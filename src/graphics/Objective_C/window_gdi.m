/*
 * window_gdi.m
 * Rosetta 3 — Native macOS GDI-emulation window for sprite-based Win32 games.
 *
 * Routes Win32 GDI calls (GetDC, CreateCompatibleDC, SelectObject, BitBlt,
 * LoadImage, DeleteObject) into a Cocoa NSWindow with a pixel framebuffer.
 *
 * Also provides sound (PlaySound, mciSendString) via AVFoundation.
 *
 * Usage from C/C++:
 *   rosetta_gdi_window_run(width_px, height_px, title,
 *                          thread_func, arg) — starts the app, creates
 *   the window, then calls thread_func(arg) on a background thread.
 *
 * The background thread can use all the GDI functions declared in
 * include/shims/win32/windows.h – this file provides the implementations.
 */

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <unistd.h>

/*
 * Debug logging — set GDI_VERBOSE to 1 at compile time or uncomment below
 * for per-tile BitBlt/SelectObject tracing (very chatty).
 * High-level events (window create, LoadImage, drawRect, sound) always log.
 */
/* Enable verbose tracing by setting environment variable GDI_VERBOSE=1
 * at runtime (checked once at startup, cached). */
static int GDI_verbose_on;
#define GDI_LOG(fmt, ...)    fprintf(stderr, "[GDIDBG] " fmt "\n", ##__VA_ARGS__)
#define GDI_LOGV(fmt, ...)   do { if (GDI_verbose_on) fprintf(stderr, "[GDIDBG] " fmt "\n", ##__VA_ARGS__); } while(0)


/* ========================================================================= */
/* Pixel framebuffer                                                          */
/* ========================================================================= */

typedef struct {
    int      width;
    int      height;
    uint32_t *pixels;   /* 0xAABBGGRR (host-endian ARGB) */
} GDIRamBuffer;

static GDIRamBuffer *g_framebuffer = NULL;
static volatile int g_fb_dirty = 0;
static pthread_mutex_t g_fb_lock = PTHREAD_MUTEX_INITIALIZER;

/* ========================================================================= */
/* Bitmap cache — stores loaded BMPs as raw ARGB pixel buffers               */
/* ========================================================================= */

typedef struct {
    uint32_t id;         /* magic handle discriminator */
    int      width;
    int      height;
    int      stride;     /* bytes per row */
    uint32_t *pixels;    /* 0xAABBGGRR */
} GDIBitmap;

#define GDI_MAX_BITMAPS 64
static GDIBitmap *g_bitmaps[GDI_MAX_BITMAPS];
static int g_bitmap_count = 0;

/* ========================================================================= */
/* GDI context state — tracks currently selected objects for each DC         */
/* ========================================================================= */

#define GDI_MAX_DC 16
typedef struct {
    uint32_t      id;          /* magic handle */
    GDIBitmap    *selected;    /* bitmap selected into this DC */
} GDIContext;

static GDIContext g_contexts[GDI_MAX_DC];
static int g_context_count = 0;

/* Magic handle values (must match windows.h #defines) */
#define GDI_HANDLE_DC       0xDC01
#define GDI_HANDLE_MEMDC    0xDC02
#define GDI_HANDLE_BITMAP   0xBEEF

/* ========================================================================= */
/* Window state                                                               */
/* ========================================================================= */

static NSWindow *g_window = nil;
static NSView   *g_view   = nil;
static int       g_win_width  = 640;
static int       g_win_height = 480;
static char      g_win_title[256] = "Rosetta 3 — GDI Window";

/* ========================================================================= */
/* Keyboard state (polled by GetAsyncKeyState)                                */
/* ========================================================================= */

#define KEYSTATE_SIZE 256
static volatile int g_key_state[KEYSTATE_SIZE]; /* 0 or 1, set by keyDown/Up */

/* ========================================================================= */
/* BMP file loader (minimal: 24-bit BMP → 0xAARRGGBB pixel buffer)          */
/* ========================================================================= */

static GDIBitmap *load_bmp_from_file(const char *path)
{
    FILE *fp = fopen(path, "rb");
    if (!fp) return NULL;

    /* BITMAPFILEHEADER */
    unsigned char hdr[14];
    if (fread(hdr, 1, 14, fp) != 14) { fclose(fp); return NULL; }
    if (hdr[0] != 'B' || hdr[1] != 'M') { fclose(fp); return NULL; }

    unsigned int data_off = (unsigned int)hdr[10]
                          | ((unsigned int)hdr[11] << 8)
                          | ((unsigned int)hdr[12] << 16)
                          | ((unsigned int)hdr[13] << 24);

    /* BITMAPINFOHEADER */
    unsigned char info[40];
    if (fread(info, 1, 40, fp) != 40) { fclose(fp); return NULL; }
    int w = (int)(info[4] | (info[5] << 8) | (info[6] << 16) | (info[7] << 24));
    int h = (int)(info[8] | (info[9] << 8) | (info[10] << 16) | (info[11] << 24));
    int bpp = (int)(info[14] | (info[15] << 8));

    if (w <= 0 || h <= 0 || (bpp != 24 && bpp != 32)) {
        fclose(fp);
        return NULL;
    }

    /* Allocate bitmap */
    GDIBitmap *bmp = calloc(1, sizeof(GDIBitmap));
    if (!bmp) { fclose(fp); return NULL; }
    bmp->width  = w;
    bmp->height = h;
    bmp->stride = w * 4;
    bmp->pixels = calloc((size_t)(w * h), 4);
    if (!bmp->pixels) { free(bmp); fclose(fp); return NULL; }

    /* BMP rows are bottom-up and 4-byte aligned */
    int src_bpp = (bpp == 32) ? 4 : 3;
    int src_stride = (w * src_bpp + 3) & ~3;
    unsigned char *row = malloc((size_t)src_stride);
    if (!row) { free(bmp->pixels); free(bmp); fclose(fp); return NULL; }

    for (int y = 0; y < h; y++) {
        fseek(fp, data_off + (h - 1 - y) * src_stride, SEEK_SET);
        if (fread(row, 1, (size_t)src_stride, fp) != (size_t)src_stride) break;
        for (int x = 0; x < w; x++) {
            unsigned char b = row[x * src_bpp + 0];
            unsigned char g = row[x * src_bpp + 1];
            unsigned char r = row[x * src_bpp + 2];
            unsigned char a = (src_bpp == 4) ? row[x * src_bpp + 3] : 0xFF;
            /* 0xAARRGGBB — with kCGImageAlphaNoneSkipFirst + kCGBitmapByteOrder32Host
               the in-memory byte order is B,G,R,X: byte0=B, byte1=G, byte2=R, byte3=X(ignored) */
            bmp->pixels[y * w + x] = ((uint32_t)a << 24)
                                   | ((uint32_t)r << 16)
                                   | ((uint32_t)g << 8)
                                   | ((uint32_t)b);
        }
    }
    free(row);
    fclose(fp);
    return bmp;
}

/* Register a bitmap and return a magic handle */
static uint32_t bitmap_register(GDIBitmap *bmp)
{
    if (!bmp) return 0;
    if (g_bitmap_count >= GDI_MAX_BITMAPS) return 0;
    uint32_t id = GDI_HANDLE_BITMAP + (uint32_t)(g_bitmap_count + 1);
    bmp->id = id;
    g_bitmaps[g_bitmap_count++] = bmp;
    return id;
}

/* Find bitmap by handle */
static GDIBitmap *bitmap_lookup(uint32_t id)
{
    for (int i = 0; i < g_bitmap_count; i++) {
        if (g_bitmaps[i] && g_bitmaps[i]->id == id)
            return g_bitmaps[i];
    }
    return NULL;
}

/* Free a bitmap */
static void bitmap_free(uint32_t id)
{
    for (int i = 0; i < g_bitmap_count; i++) {
        if (g_bitmaps[i] && g_bitmaps[i]->id == id) {
            free(g_bitmaps[i]->pixels);
            free(g_bitmaps[i]);
            g_bitmaps[i] = NULL;
            return;
        }
    }
}

/* Get or create a GDI context */
static GDIContext *context_get(uint32_t id)
{
    for (int i = 0; i < g_context_count; i++) {
        if (g_contexts[i].id == id)
            return &g_contexts[i];
    }
    return NULL;
}

static uint32_t context_create(void)
{
    if (g_context_count >= GDI_MAX_DC) return 0;
    uint32_t id = GDI_HANDLE_DC + (uint32_t)g_context_count;
    g_contexts[g_context_count].id = id;
    g_contexts[g_context_count].selected = NULL;
    g_context_count++;
    return id;
}

/* ========================================================================= */
/* Framebuffer management                                                     */
/* ========================================================================= */

static void framebuffer_resize(int w, int h)
{
    pthread_mutex_lock(&g_fb_lock);
    if (g_framebuffer) {
        free(g_framebuffer->pixels);
        free(g_framebuffer);
    }
    g_framebuffer = calloc(1, sizeof(GDIRamBuffer));
    if (g_framebuffer) {
        g_framebuffer->width  = w;
        g_framebuffer->height = h;
        g_framebuffer->pixels = calloc((size_t)(w * h), 4);
    }
    g_fb_dirty = 1;
    pthread_mutex_unlock(&g_fb_lock);
}


/* ========================================================================= */
/* Sound playback (AVAudioPlayer)                                             */
/* ========================================================================= */

typedef struct {
    char alias[64];
    AVAudioPlayer *player;
} SoundEntry;

#define MAX_SOUNDS 16
static SoundEntry g_sounds[MAX_SOUNDS];
static int g_sound_count = 0;

static AVAudioPlayer *sound_find(const char *alias)
{
    for (int i = 0; i < g_sound_count; i++) {
        if (strcmp(g_sounds[i].alias, alias) == 0)
            return g_sounds[i].player;
    }
    return nil;
}

static int sound_add(const char *alias, AVAudioPlayer *player)
{
    if (g_sound_count >= MAX_SOUNDS) return -1;
    strncpy(g_sounds[g_sound_count].alias, alias, sizeof(g_sounds[0].alias) - 1);
    g_sounds[g_sound_count].player = player;
    g_sound_count++;
    return 0;
}

/* Callback for when an audio player finishes — used for 'play repeat' */
@interface SoundRepeatHelper : NSObject
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag;
@end
static SoundRepeatHelper *g_soundHelper = nil;


/* ========================================================================= */
/* GDIView — NSView that renders the pixel framebuffer                        */
/* ========================================================================= */

@interface GDIView : NSView
- (instancetype)initWithWidth:(int)w height:(int)h;
@end

@implementation GDIView

- (instancetype)initWithWidth:(int)w height:(int)h
{
    self = [super initWithFrame:NSMakeRect(0, 0, (CGFloat)w, (CGFloat)h)];
    if (self) {
        [self setWantsLayer:YES];
    }
    return self;
}

- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder  { return YES; }
- (BOOL)resignFirstResponder  { return YES; }

- (void)keyDown:(NSEvent *)event
{
    unsigned short keyCode = [event keyCode];
    NSString *chars = [event charactersIgnoringModifiers];
    unichar c = (chars && [chars length] > 0) ? [chars characterAtIndex:0] : 0;

    /* Set key state for GetAsyncKeyState polling.
       Bit 15 = key is down; Bit 0 = was pressed since last GetAsyncKeyState. */
    if (c > 0 && c < KEYSTATE_SIZE) {
        g_key_state[c] = 0x8001;
        /* charactersIgnoringModifiers returns lowercase for letter keys (e.g. 'w'=119),
           but the game checks uppercase ('W'=87 in KeyIsDown('W', ...)).  Set both. */
        if (c >= 'a' && c <= 'z') g_key_state[c - 32] = 0x8001;
        if (c >= 'A' && c <= 'Z') g_key_state[c + 32] = 0x8001;
    }

    /* Map common keys to virtual codes (bits 15+0 for GetAsyncKeyState) */
    switch (keyCode) {
        case 0x7E: g_key_state[0x26] = 0x8001;  break; /* Up arrow   → VK_UP (38)   */
        case 0x7D: g_key_state[0x28] = 0x8001;  break; /* Down arrow → VK_DOWN (40) */
        case 0x7B: g_key_state[0x25] = 0x8001;  break; /* Left arrow → VK_LEFT (37) */
        case 0x7C: g_key_state[0x27] = 0x8001;  break; /* Right arr  → VK_RIGHT (39)*/
        case 0x35: g_key_state[0x1B] = 0x8001;  break; /* Escape     → VK_ESCAPE (27)*/
        case 0x24: g_key_state[0x0D] = 0x8001;  break; /* Return     → VK_RETURN (13)*/
        default: break;
    }

    GDI_LOG("keyDown: keyCode=0x%02X char=U+%04X ('%c') vk_UP=%d vk_DN=%d vk_LE=%d vk_RI=%d vk_ES=%d vk_RE=%d",
            keyCode, c, (c >= 32 && c < 127) ? (char)c : '?',
            g_key_state[0x26], g_key_state[0x28],
            g_key_state[0x25], g_key_state[0x27],
            g_key_state[0x1B], g_key_state[0x0D]);

    /* Route to existing key queue for kbhit/getch */
    extern void rosetta_key_push(int key);
    switch (keyCode) {
        case 0x7E: rosetta_key_push(72);  return;
        case 0x7D: rosetta_key_push(80);  return;
        case 0x7B: rosetta_key_push(75);  return;
        case 0x7C: rosetta_key_push(77);  return;
        case 0x35: rosetta_key_push(27);  return;
        case 0x24: rosetta_key_push(13);  return;
        case 0x33: rosetta_key_push(8);   return;
        case 0x30: rosetta_key_push(9);   return;
        default: break;
    }
    if (c > 0) {
        rosetta_key_push((int)c);
    }
}

- (void)keyUp:(NSEvent *)event
{
    unsigned short keyCode = [event keyCode];
    NSString *chars = [event charactersIgnoringModifiers];
    unichar c = (chars && [chars length] > 0) ? [chars characterAtIndex:0] : 0;

    /* Clear character-based entries (both cases) */
    if (c > 0 && c < KEYSTATE_SIZE) {
        g_key_state[c] = 0;
        if (c >= 'a' && c <= 'z') g_key_state[c - 32] = 0;
        if (c >= 'A' && c <= 'Z') g_key_state[c + 32] = 0;
    }
    /* Clear virtual key codes */
    switch (keyCode) {
        case 0x7E: g_key_state[0x26] = 0; break;
        case 0x7D: g_key_state[0x28] = 0; break;
        case 0x7B: g_key_state[0x25] = 0; break;
        case 0x7C: g_key_state[0x27] = 0; break;
        case 0x35: g_key_state[0x1B] = 0; break;
        case 0x24: g_key_state[0x0D] = 0; break;
        default: break;
    }

    GDI_LOG("keyUp:   keyCode=0x%02X char=U+%04X ('%c')", keyCode, c,
            (c >= 32 && c < 127) ? (char)c : '?');
}

- (void)flagsChanged:(NSEvent *)event { }

static int g_frame_count = 0;

- (void)drawRect:(NSRect)dirtyRect
{
    if (!g_framebuffer) return;

    pthread_mutex_lock(&g_fb_lock);
    int w = g_framebuffer->width;
    int h = g_framebuffer->height;
    uint32_t *pixels = g_framebuffer->pixels;

    /* Check if any pixel is non-zero to detect actual content */
    int has_content = 0;
    for (int i = 0; i < w * h && !has_content; i += w * h / 100 + 1) {
        if (pixels[i] != 0) has_content = 1;
    }

    g_fb_dirty = 0;
    pthread_mutex_unlock(&g_fb_lock);

    if (!pixels) return;

    g_frame_count++;
    if ((g_frame_count % 30) == 0) {
        GDI_LOG("drawRect #%d — %dx%d %s", g_frame_count, w, h,
                has_content ? "HAS CONTENT" : "BLANK (all-zero framebuffer)");
    }

    /* Create CGImage via CGBitmapContext from the framebuffer.
       Pixel storage: 0xAARRGGBB (A<<24|R<<16|G<<8|B).  On little-endian this
       gives in-memory byte order: byte0=B, byte1=G, byte2=R, byte3=A.

       With kCGImageAlphaNoneSkipFirst (X,R,G,B) + kCGBitmapByteOrder32Host:
       LE byte order: byte0=B, byte1=G, byte2=R, byte3=X.
       This EXACTLY matches our storage — byte0=B, byte1=G, byte2=R, byte3=A(ignored).

       Do NOT use PremultipliedLast — it expects byte0=A, byte1=B, byte2=G, byte3=R,
       which misreads our Blue byte as Alpha (causing B=0 pixels to become transparent). */
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    if (!cs) return;

    CGContextRef bmCtx = CGBitmapContextCreate(pixels, w, h, 8, (size_t)(w * 4),
        cs, kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst);
    CGColorSpaceRelease(cs);
    if (!bmCtx) return;

    CGImageRef image = CGBitmapContextCreateImage(bmCtx);
    CGContextRelease(bmCtx);

    CGContextRef cgCtx = [[NSGraphicsContext currentContext] CGContext];
    if (image && cgCtx) {
        CGRect r = CGRectMake(0, 0, (CGFloat)w, (CGFloat)h);
        CGContextSaveGState(cgCtx);
        CGContextTranslateCTM(cgCtx, 0, h);
        CGContextScaleCTM(cgCtx, 1, -1);
        CGContextDrawImage(cgCtx, r, image);
        CGContextRestoreGState(cgCtx);
        CGImageRelease(image);
    }
}

@end


/* ========================================================================= */
/* GDIWindowController                                                        */
/* ========================================================================= */

@interface GDIWindowController : NSWindowController <NSWindowDelegate> {
    GDIView    *_gdiView;
    int         _width;
    int         _height;
    NSThread   *_gameThread;
    NSString   *_windowTitle;
}
- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)title;
- (void)startGame:(void (*)(void *))func arg:(void *)arg;
@end

@implementation GDIWindowController

- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)title
{
    _width  = w;
    _height = h;
    _windowTitle = [NSString stringWithUTF8String:title ? title : "Rosetta 3 — GDI Window"];

    /* Create framebuffer */
    framebuffer_resize(w, h);

    _gdiView = [[GDIView alloc] initWithWidth:w height:h];
    NSRect viewFrame = [_gdiView frame];

    NSUInteger style = NSWindowStyleMaskTitled
                     | NSWindowStyleMaskClosable
                     | NSWindowStyleMaskMiniaturizable;
    NSWindow *win = [[NSWindow alloc]
        initWithContentRect:viewFrame
                  styleMask:style
                    backing:NSBackingStoreBuffered
                      defer:NO];
    [win setContentView:_gdiView];
    [win setTitle:_windowTitle];
    [win makeFirstResponder:_gdiView];
    [win center];
    [win setAcceptsMouseMovedEvents:NO];
    [win setReleasedWhenClosed:NO];

    /* Set global window pointer so GetConsoleWindow() etc. work */
    g_window = win;

    self = [super initWithWindow:win];
    if (self) {
        [win setDelegate:self];
        _gameThread = nil;
    }
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp terminate:nil];
}

- (void)startGame:(void (*)(void *))func arg:(void *)arg
{
    _gameThread = [[NSThread alloc] initWithBlock:^{
        if (func) func(arg);
    }];
    [_gameThread start];
}

- (void)scheduleRedraw
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 / 30.0
                                             target:self
                                           selector:@selector(redrawTimer:)
                                           userInfo:nil
                                            repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)redrawTimer:(NSTimer *)timer
{
    if (g_fb_dirty) {
        [_gdiView setNeedsDisplay:YES];
    }
}

@end


/* ========================================================================= */
/* App delegate                                                               */
/* ========================================================================= */

@interface GDIGameAppDelegate : NSObject <NSApplicationDelegate> {
    GDIWindowController *_controller;
    void (*_threadFunc)(void *);
    void *_threadArg;
    int _width;
    int _height;
    char _title[256];
}
- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)t
                    threadFunc:(void (*)(void *))func arg:(void *)arg;
@end

@implementation GDIGameAppDelegate

- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)t
                    threadFunc:(void (*)(void *))func arg:(void *)arg
{
    self = [super init];
    if (self) {
        _width  = w;
        _height = h;
        strncpy(_title, t ? t : "Rosetta 3 — GDI Window", sizeof(_title) - 1);
        _threadFunc = func;
        _threadArg  = arg;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    GDI_LOG("App finished launching — creating window %d×%d \"%s\"", _width, _height, _title);
    _controller = [[GDIWindowController alloc]
                   initWithWidth:_width height:_height title:_title];
    [_controller showWindow:nil];
    GDI_LOG("Window shown, starting redraw timer");
    [_controller scheduleRedraw];
    GDI_LOG("Starting game thread");
    [_controller startGame:_threadFunc arg:_threadArg];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end


/* ========================================================================= */
/* Public C-linkage entry point                                               */
/* ========================================================================= */

void rosetta_gdi_window_run(int width, int height, const char *title,
                            void (*thread_func)(void *), void *arg)
{
    /* Cache GDI_VERBOSE from environment at first call */
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        char *ev = getenv("GDI_VERBOSE");
        GDI_verbose_on = ev && ev[0] == '1';
    });

    GDI_LOG("rosetta_gdi_window_run(%d×%d, \"%s\", func=%p)",
            width, height, title ? title : "(null)", (void*)thread_func);
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        GDIGameAppDelegate *delegate =
            [[GDIGameAppDelegate alloc] initWithWidth:width
                                                height:height
                                                 title:title
                                            threadFunc:thread_func
                                                   arg:arg];
        [app setDelegate:delegate];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
}


/* 16-bit wide string length (Win32 WCHAR is unsigned short, not wchar_t) */
static size_t wstrlen16(const unsigned short *s) {
    if (!s) return 0;
    size_t len = 0;
    while (s[len] != 0) len++;
    return len;
}

/* ========================================================================= */
/* C-linkage GDI API implementations called from the shim layer               */
/* ========================================================================= */

#include <stdint.h>

uint32_t rosetta_gdi_get_dc(void *hwnd)
{
    (void)hwnd;
    uint32_t id = context_create();
    GDI_LOG("GetDC(%p) → 0x%04X", hwnd, id);
    return id;
}

uint32_t rosetta_gdi_create_compatible_dc(uint32_t hdc)
{
    (void)hdc;
    uint32_t id = context_create();
    GDI_LOG("CreateCompatibleDC(0x%04X) → 0x%04X", hdc, id);
    return id;
}

uint32_t rosetta_gdi_select_object(uint32_t hdc, uint32_t hgdiobj)
{
    GDIContext *ctx = context_get(hdc);
    GDIBitmap  *bmp = bitmap_lookup(hgdiobj);
    if (ctx && bmp) {
        ctx->selected = bmp;
        GDI_LOGV("SelectObject(0x%04X, 0x%04X) → OK", hdc, hgdiobj);
        return hgdiobj;
    }
    GDI_LOG("SelectObject(0x%04X, 0x%04X) FAILED — ctx=%p bmp=%p",
            hdc, hgdiobj, (void*)ctx, (void*)bmp);
    return 0;
}

int rosetta_gdi_bitblt(uint32_t hdc_dest, int x_dest, int y_dest,
                       int w, int h, uint32_t hdc_src,
                       int x_src, int y_src, uint32_t dw_rop)
{
    (void)dw_rop;

    GDIContext *src_ctx = context_get(hdc_src);
    if (!src_ctx || !src_ctx->selected) {
        GDI_LOG("BitBlt(dst=0x%04X, src=0x%04X) FAILED — no source bitmap", hdc_dest, hdc_src);
        return 0;
    }

    pthread_mutex_lock(&g_fb_lock);
    if (!g_framebuffer || !g_framebuffer->pixels) {
        pthread_mutex_unlock(&g_fb_lock);
        return 0;
    }

    GDIBitmap *src_bmp = src_ctx->selected;
    int fb_w = g_framebuffer->width;
    int fb_h = g_framebuffer->height;

    for (int row = 0; row < h; row++) {
        int dst_y = y_dest + row;
        if (dst_y < 0 || dst_y >= fb_h) continue;

        int src_y = y_src + row;
        if (src_y < 0 || src_y >= src_bmp->height) continue;

        for (int col = 0; col < w; col++) {
            int dst_x = x_dest + col;
            if (dst_x < 0 || dst_x >= fb_w) continue;

            int src_x = x_src + col;
            if (src_x < 0 || src_x >= src_bmp->width) continue;

            /* Non-premultiplied ARGB copy — already 0xAARRGGBB in our format */
            g_framebuffer->pixels[dst_y * fb_w + dst_x] =
                src_bmp->pixels[src_y * src_bmp->width + src_x];
        }
    }
    g_fb_dirty = 1;
    pthread_mutex_unlock(&g_fb_lock);
    GDI_LOGV("BitBlt(dst=0x%04X, src=0x%04X, [%d×%d at %d,%d ← %d,%d] rop=0x%08X) → OK",
             hdc_dest, hdc_src, w, h, x_dest, y_dest, x_src, y_src, dw_rop);
    return 1;
}

int rosetta_gdi_delete_object(uint32_t hgdiobj)
{
    /* Windows GDI: DeleteObject FAILS if the object is selected into any DC.
       We must match this behavior — the game expects the object to survive. */
    for (int i = 0; i < g_context_count; i++) {
        if (g_contexts[i].selected &&
            g_contexts[i].selected->id == hgdiobj) {
            /* Still selected — reject deletion (returns 0 = failure) */
            GDI_LOGV("DeleteObject(0x%04X) FAILED — still selected in DC 0x%04X",
                     hgdiobj, g_contexts[i].id);
            return 0;
        }
    }
    bitmap_free(hgdiobj);
    return 1;
}

uint32_t rosetta_gdi_load_image_a(void *h_inst, const char *name,
                                   uint32_t type, int cx, int cy,
                                   uint32_t fu_load)
{
    (void)h_inst; (void)type; (void)cx; (void)cy; (void)fu_load;
    if (!name) {
        GDI_LOG("LoadImageA(NULL) FAILED — null name");
        return 0;
    }

    GDIBitmap *bmp = load_bmp_from_file(name);
    if (!bmp) {
        GDI_LOG("LoadImageA(\"%s\", type=%u) FAILED — file not found or bad format", name, type);
        return 0;
    }

    uint32_t id = bitmap_register(bmp);
    GDI_LOG("LoadImageA(\"%s\", type=%u) → 0x%04X (%d×%d)", name, type, id, bmp->width, bmp->height);
    return id;
}

uint32_t rosetta_gdi_load_image_w(void *h_inst, const unsigned short *name,
                                   uint32_t type, int cx, int cy,
                                   uint32_t fu_load)
{
    /* Convert wide string to UTF-8 (WCHAR is unsigned short, 16-bit) */
    NSString *ns = [NSString stringWithCharacters:name
                                           length:wstrlen16(name)];
    const char *utf8 = [ns UTF8String];
    GDI_LOG("LoadImageW → \"%s\"", utf8 ? utf8 : "(null)");
    return rosetta_gdi_load_image_a(h_inst, utf8, type, cx, cy, fu_load);
}

void *rosetta_gdi_get_console_window(void)
{
    void *ptr = (__bridge void *)g_window;
    GDI_LOGV("GetConsoleWindow() → %p", ptr);
    return ptr;
}

void rosetta_gdi_set_console_title(const char *title)
{
    if (!title) return;
    GDI_LOG("SetConsoleTitle(\"%s\")", title);
    strncpy(g_win_title, title, sizeof(g_win_title) - 1);
    dispatch_async(dispatch_get_main_queue(), ^{
        [g_window setTitle:[NSString stringWithUTF8String:title]];
    });
}

void rosetta_gdi_set_window_pos(void *hwnd, void *insert_after,
                                 int x, int y, int cx, int cy,
                                 unsigned int flags)
{
    (void)hwnd; (void)insert_after;
    GDI_LOG("SetWindowPos(%p, %p, %d,%d %d×%d flags=0x%X)", hwnd, insert_after, x, y, cx, cy, flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_window) {
            NSRect r = NSMakeRect((CGFloat)x, (CGFloat)y,
                                  (CGFloat)cx, (CGFloat)cy);
            /* Adjust for screen coordinates (y from top on macOS) */
            NSScreen *screen = [NSScreen mainScreen];
            CGFloat screenH = screen ? [screen frame].size.height : 1080;
            r.origin.y = screenH - r.origin.y - r.size.height;
            [g_window setFrame:r display:YES];
            /* Update framebuffer size if window size changed */
            if (cx > 0 && cy > 0 && (cx != g_win_width || cy != g_win_height)) {
                g_win_width = cx;
                g_win_height = cy;
                framebuffer_resize(cx, cy);
            }
        }
    });
}

int rosetta_gdi_get_console_screen_buffer_info(void *handle, void *lpInfo)
{
    (void)handle;
    if (!lpInfo) {
        GDI_LOG("GetConsoleScreenBufferInfo(%p) FAILED — null buffer", handle);
        return 0;
    }
    /* lpInfo is CONSOLE_SCREEN_BUFFER_INFO struct.
       We fill in window dimensions in "char cells" — since this is a
       pixel-based window, report 1 char cell per pixel for simplicity. */
    typedef struct {
        short X, Y;       /* COORD dwSize */
        short curX, curY; /* COORD dwCursorPosition */
        short wAttributes;
        short left, top, right, bottom; /* SMALL_RECT srWindow */
        short maxX, maxY; /* COORD dwMaximumWindowSize */
    } CSBI;

    CSBI *info = (CSBI *)lpInfo;
    info->X = (short)g_win_width;
    info->Y = (short)g_win_height;
    info->curX = 0;
    info->curY = 0;
    info->wAttributes = 0x07;
    info->left = 0;
    info->top = 0;
    info->right = (short)(g_win_width - 1);
    info->bottom = (short)(g_win_height - 1);
    info->maxX = (short)g_win_width;
    info->maxY = (short)g_win_height;
    GDI_LOG("GetConsoleScreenBufferInfo(%p) → win=%dx%d", handle, g_win_width, g_win_height);
    return 1;
}

int rosetta_gdi_set_console_screen_buffer_size(void *handle, short x, short y)
{
    (void)handle;
    /* We ignore this for pixel mode — window resize is handled by SetWindowPos */
    (void)x; (void)y;
    return 1;
}

short rosetta_gdi_get_async_key_state(int vKey)
{
    short result = 0;
    if (vKey >= 0 && vKey < KEYSTATE_SIZE) {
        int val = g_key_state[vKey];
        result = (short)(val & 0x8001);           /* preserve bit 15 (down) and bit 0 (transition) */
        g_key_state[vKey] = val & ~1;              /* clear "just pressed" bit after reading */
    }
    if (result & 0x8000) {
        GDI_LOGV("GetAsyncKeyState(%d) → DOWN (bits 0x%X)", vKey, result);
    }
    return result;
}

void *rosetta_gdi_get_foreground_window(void)
{
    void *ptr = (__bridge void *)g_window;
    GDI_LOGV("GetForegroundWindow() → %p", ptr);
    return ptr;
}

void *rosetta_gdi_monitor_from_window(void *hwnd, unsigned long flags)
{
    (void)hwnd; (void)flags;
    GDI_LOG("MonitorFromWindow(%p, %lu) → 0xCAFE", hwnd, flags);
    return (void *)(intptr_t)0xCAFE;
}

int rosetta_gdi_get_monitor_info_a(void *hMonitor, void *lpmi)
{
    (void)hMonitor;
    if (!lpmi) return 0;

    NSScreen *screen = [NSScreen mainScreen];
    CGFloat sw = screen ? [screen frame].size.width : 1920;
    CGFloat sh = screen ? [screen frame].size.height : 1080;

    unsigned int *cb = (unsigned int *)lpmi;
    if (*cb < 40) return 0;

    /* rcMonitor */
    int *rc = (int *)((unsigned char *)lpmi + 4);
    rc[0] = 0;    /* left */
    rc[1] = 0;    /* top */
    rc[2] = (int)sw;  /* right */
    rc[3] = (int)sh;  /* bottom */

    /* rcWork */
    rc[4] = 0;
    rc[5] = 0;
    rc[6] = (int)sw;
    rc[7] = (int)sh;

    /* dwFlags */
    unsigned int *flags = (unsigned int *)((unsigned char *)lpmi + 36);
    flags[0] = 1;

    /* szDevice (MONITORINFOEX only) — only if cbSize >= sizeof(MONITORINFOEX) */
    if (*cb >= 40 + 32) {
        char *device = (char *)((unsigned char *)lpmi + 40);
        strncpy(device, "MainDisplay", 31);
    }
    return 1;
}

int rosetta_gdi_enum_display_settings_a(const char *device_name,
                                         unsigned int mode_num, void *lpDevMode)
{
    (void)device_name;
    if (mode_num != 0xFFFFFFFF || !lpDevMode) return 0; /* ENUM_CURRENT_SETTINGS */

    NSScreen *screen = [NSScreen mainScreen];
    CGFloat sw = screen ? [screen frame].size.width : 1920;
    CGFloat sh = screen ? [screen frame].size.height : 1080;

    /* DEVMODEA layout */
    unsigned char *dm = (unsigned char *)lpDevMode;
    unsigned short *dmSize = (unsigned short *)(dm + 68);
    *dmSize = 220;  /* sizeof(DEVMODEA) */

    unsigned int *pelW = (unsigned int *)(dm + 108);
    unsigned int *pelH = (unsigned int *)(dm + 112);
    unsigned int *bpp  = (unsigned int *)(dm + 104);
    unsigned int *freq = (unsigned int *)(dm + 120);

    *pelW = (unsigned int)sw;
    *pelH = (unsigned int)sh;
    *bpp = 32;
    *freq = 60;

    return 1;
}

int rosetta_gdi_get_std_handle_val(void)
{
    return 1; /* truthy handle */
}

int rosetta_gdi_set_console_text_attribute(void *h, unsigned short attr)
{
    (void)h; (void)attr; return 1;
}

int rosetta_gdi_set_console_cursor_position(void *h, int x, int y)
{
    (void)h; (void)x; (void)y; return 1;
}

int rosetta_gdi_set_console_cursor_info(void *h, void *info)
{
    (void)h; (void)info; return 1;
}

/* ---- Sound (PlaySound) ---- */

int rosetta_gdi_play_sound_a(const char *pszSound, void *hmod,
                              unsigned long fdwSound)
{
    (void)hmod;
    if (!pszSound) {
        GDI_LOG("PlaySoundA(NULL) — no-op");
        return 0;
    }

    GDI_LOG("PlaySoundA(\"%s\", fdwSound=0x%lX) → attempting...", pszSound, fdwSound);

    /* SND_FILENAME=0x00020000, SND_ASYNC=0x00000001 */
    BOOL async = (fdwSound & 0x00000001) != 0;

    NSString *path = [NSString stringWithUTF8String:pszSound];
    NSURL *url = [NSURL fileURLWithPath:path];

    NSError *err = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                                    error:&err];
    if (!player) {
        GDI_LOG("PlaySoundA(\"%s\") FAILED (%s)", pszSound, [[err localizedDescription] UTF8String]);
        return 0;
    }

    if (async) {
        [player play];
        /* Keep a reference — but don't cache for PlaySound (one-shot) */
    } else {
        [player play];
    }
    GDI_LOG("PlaySoundA(\"%s\") → OK (async=%d)", pszSound, async);
    return 1;
}

int rosetta_gdi_play_sound_w(const unsigned short *pszSound, void *hmod,
                              unsigned long fdwSound)
{
    NSString *ns = [NSString stringWithCharacters:pszSound
                                          length:wstrlen16(pszSound)];
    return rosetta_gdi_play_sound_a([ns UTF8String], hmod, fdwSound);
}

/* ---- Sound (mciSendString) ---- */

int rosetta_gdi_mci_send_string_a(const char *command, char *ret_str,
                                   unsigned int ret_len, void *callback)
{
    (void)ret_str; (void)ret_len; (void)callback;
    GDI_LOG("mciSendStringA(\"%s\")", command ? command : "NULL");
    if (!command) return 0;

    /* Parse simple MCI command strings */
    char cmd[512];
    strncpy(cmd, command, sizeof(cmd) - 1);
    cmd[sizeof(cmd) - 1] = '\0';

    char *verb = strtok(cmd, " ");
    if (!verb) return 0;

    if (strcmp(verb, "open") == 0) {
        /* open "filename.mp3" type mpegvideo alias mp3 */
        char *file_start = strchr(command, '"');
        if (!file_start) return 0;
        file_start++;
        char *file_end = strchr(file_start, '"');
        if (!file_end) return 0;
        size_t file_len = (size_t)(file_end - file_start);

        char fpath[512];
        size_t flen = file_len < sizeof(fpath) - 1 ? file_len : sizeof(fpath) - 1;
        strncpy(fpath, file_start, flen);
        fpath[flen] = '\0';

        /* Find alias */
        char *alias_token = strstr(command, "alias ");
        const char *alias = "default";
        if (alias_token) {
            alias = alias_token + 6;
        }

        NSString *path = [NSString stringWithUTF8String:fpath];
        NSURL *url = [NSURL fileURLWithPath:path];

        NSError *err = nil;
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                                       error:&err];
        if (!player) {
            return 1; /* MCI returns 0 on success */
        }

        [player prepareToPlay];
        sound_add(alias, player);
        return 0; /* MCI_SUCCESS */
    }

    else if (strcmp(verb, "play") == 0) {
        /* play mp3 [repeat] */
        char *alias_token = verb;
        char *next = strtok(NULL, " ");
        if (!next) return 0;

        const char *alias = next;
        BOOL repeat = NO;

        char *repeat_token = strtok(NULL, " ");
        if (repeat_token && strcmp(repeat_token, "repeat") == 0) repeat = YES;

        AVAudioPlayer *player = sound_find(alias);
        if (!player) return 0;

        if (repeat) {
            player.numberOfLoops = -1; /* infinite */
        }
        [player play];
        return 0;
    }

    else if (strcmp(verb, "stop") == 0) {
        char *alias = strtok(NULL, " ");
        if (!alias) return 0;

        AVAudioPlayer *player = sound_find(alias);
        if (!player) return 0;

        [player stop];
        player.currentTime = 0;
        return 0;
    }

    else if (strcmp(verb, "close") == 0) {
        char *alias = strtok(NULL, " ");
        if (!alias) return 0;

        /* Remove from sound table */
        for (int i = 0; i < g_sound_count; i++) {
            if (strcmp(g_sounds[i].alias, alias) == 0) {
                [g_sounds[i].player stop];
                g_sounds[i].player = nil;
                g_sounds[i].alias[0] = '\0';
                return 0;
            }
        }
        return 0;
    }

    return 0;
}

int rosetta_gdi_mci_send_string_w(const unsigned short *command,
                                   unsigned short *ret_str,
                                   unsigned int ret_len, void *callback)
{
    (void)ret_str; (void)ret_len; (void)callback;
    /* Convert wide to UTF-8 and delegate */
    NSString *ns = [NSString stringWithCharacters:command
                                          length:wstrlen16(command)];
    return rosetta_gdi_mci_send_string_a([ns UTF8String], NULL, 0, NULL);
}
