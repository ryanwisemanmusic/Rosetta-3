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
#include <game/debug_runtime.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
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
static void rosetta_gdi_trace_log(int verbose_only, const char *fmt, ...)
{
    if (verbose_only && !GDI_verbose_on) return;

    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    fprintf(stderr, "\n");
    va_end(args);

    char detail[2048];
    va_start(args, fmt);
    vsnprintf(detail, sizeof(detail), fmt, args);
    va_end(args);
    rosetta3_debug_log_host_call("ARM64", "gdi", detail);
}

#define GDI_LOG(fmt, ...)    rosetta_gdi_trace_log(0, "[GDIDBG] " fmt, ##__VA_ARGS__)
#define GDI_LOGV(fmt, ...)   rosetta_gdi_trace_log(1, "[GDIDBG] " fmt, ##__VA_ARGS__)

/* Mouse state tracked by GDIView mouseDown/mouseDragged/mouseUp/mouseMoved.
   Written on the main thread, read from the game thread (via GetMessage). */
static volatile int g_mouse_x = 0;
static volatile int g_mouse_y = 0;
static volatile int g_mouse_buttons = 0;  /* bit 0 = left, bit 1 = right */

int rosetta_gdi_get_mouse_x(void)  { return g_mouse_x; }
int rosetta_gdi_get_mouse_y(void)  { return g_mouse_y; }
int rosetta_gdi_get_mouse_buttons(void) { return g_mouse_buttons; }

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

typedef struct {
    int x;
    int y;
} RosettaWinPoint;

/* ========================================================================= */
/* GDI context state — tracks currently selected objects for each DC         */
/* ========================================================================= */

#define GDI_MAX_DC 16
typedef struct {
    uint32_t      id;              /* magic handle */
    GDIBitmap    *selected;        /* bitmap selected into this DC */
    uint32_t      selected_brush;  /* handle of selected brush (0 = none) */
    uint32_t      selected_pen;    /* handle of selected pen   (0 = none) */
    uint32_t      selected_font;   /* handle of selected font  (0 = none) */
    int           cur_x;           /* MoveToEx current position X */
    int           cur_y;           /* MoveToEx current position Y */
    uint32_t      text_color;      /* SetTextColor (ARGB) */
    uint32_t      bk_color;        /* SetBkColor   (ARGB) */
    int           bk_mode;         /* SetBkMode (OPAQUE=2 or TRANSPARENT=1) */
} GDIContext;

static GDIContext g_contexts[GDI_MAX_DC];
static int g_context_count = 0;

/* Magic handle values (must match windows.h #defines) */
#define GDI_HANDLE_DC       0xDC01
#define GDI_HANDLE_MEMDC    0xDC02
#define GDI_HANDLE_BITMAP   0xBEEF

/* Win32 constants replicated here since ObjC compiles separately from windows.h */
#define BF_LEFT            0x0001
#define BF_TOP             0x0002
#define BF_RIGHT           0x0004
#define BF_BOTTOM          0x0008
#define BF_RECT            (BF_LEFT | BF_TOP | BF_RIGHT | BF_BOTTOM)

/* ========================================================================= */
/* Window state                                                               */
/* ========================================================================= */

static NSWindow *g_window = nil;
static NSView   *g_view   = nil;
static id g_window_controller = nil;
@class GDIWindowController;
static int       g_win_width  = 640;
static int       g_win_height = 480;
static char      g_win_title[256] = "Rosetta 3 — GDI Window";

#define ROSETTA_MENU_HEIGHT 24
#define ROSETTA_MAX_MENU_TOPLEVEL 16
#define ROSETTA_MAX_MENU_TITLE 64
#define ROSETTA_MAX_MENU_ITEMS 32
typedef struct {
    int is_separator;
    unsigned int command_id;
    char title[ROSETTA_MAX_MENU_TITLE];
} RosettaMenuItem;
typedef struct {
    uint32_t handle;
    int visible;
    int count;
    char titles[ROSETTA_MAX_MENU_TOPLEVEL][ROSETTA_MAX_MENU_TITLE];
    NSRect rects[ROSETTA_MAX_MENU_TOPLEVEL];
    int item_counts[ROSETTA_MAX_MENU_TOPLEVEL];
    RosettaMenuItem items[ROSETTA_MAX_MENU_TOPLEVEL][ROSETTA_MAX_MENU_ITEMS];
} RosettaMenuModel;
static RosettaMenuModel g_menu_model = {0};

typedef struct {
    void *hwnd;
    unsigned int message;
    uintptr_t wParam;
    intptr_t lParam;
    unsigned int time;
    int pt_x;
    int pt_y;
} RosettaPostedMessage;

#define ROSETTA_MAX_POSTED_MESSAGES 64
static RosettaPostedMessage g_posted_messages[ROSETTA_MAX_POSTED_MESSAGES];
static int g_posted_head = 0;
static int g_posted_tail = 0;
static pthread_mutex_t g_posted_lock = PTHREAD_MUTEX_INITIALIZER;

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
    g_contexts[g_context_count].selected_brush = 0xDE64; /* WHITE_BRUSH */
    g_contexts[g_context_count].selected_pen = 0xDE6B;   /* BLACK_PEN */
    g_contexts[g_context_count].selected_font = 0;
    g_contexts[g_context_count].cur_x = 0;
    g_contexts[g_context_count].cur_y = 0;
    g_contexts[g_context_count].text_color = 0xFF000000;  /* default black */
    g_contexts[g_context_count].bk_color = 0xFFFFFFFF;    /* default white */
    g_contexts[g_context_count].bk_mode = 2;              /* OPAQUE */
    g_context_count++;
    return id;
}

/* ========================================================================= */
/* Font cache (CreateFontW → CTFontRef)                                       */
/* ========================================================================= */

#define GDI_MAX_FONTS 32
#define GDI_FONT_HANDLE_BASE 0xDF00

static CTFontRef g_fonts[GDI_MAX_FONTS];
static int g_font_count = 0;
static int surface_get(GDIContext *ctx, int *w, int *h, uint32_t **pixels);

#define GDI_MAX_COLOR_OBJECTS 128
static uint32_t g_color_object_handles[GDI_MAX_COLOR_OBJECTS];
static uint32_t g_color_object_values[GDI_MAX_COLOR_OBJECTS];
static int g_color_object_count = 0;

#define GDI_MAX_OBJECT_KINDS 128
enum {
    GDI_OBJECT_KIND_UNKNOWN = 0,
    GDI_OBJECT_KIND_BRUSH   = 1,
    GDI_OBJECT_KIND_PEN     = 2,
};
static uint32_t g_object_kind_handles[GDI_MAX_OBJECT_KINDS];
static uint32_t g_object_kind_values[GDI_MAX_OBJECT_KINDS];
static int g_object_kind_count = 0;

static uint32_t color_object_lookup(uint32_t handle)
{
    switch (handle) {
        case 0xDE64: return 0x00FFFFFF; /* WHITE_BRUSH */
        case 0xDE65: return 0x00C0C0C0; /* LTGRAY_BRUSH */
        case 0xDE66: return 0x00808080; /* GRAY_BRUSH */
        case 0xDE67: return 0x00404040; /* DKGRAY_BRUSH */
        case 0xDE68: return 0x00000000; /* BLACK_BRUSH */
        case 0xDE69: return 0x00FFFFFF; /* NULL_BRUSH */
        case 0xDE6A: return 0x00FFFFFF; /* WHITE_PEN */
        case 0xDE6B: return 0x00000000; /* BLACK_PEN */
        case 0xDE6C: return 0x00000000; /* NULL_PEN */
        default: break;
    }
    for (int i = 0; i < g_color_object_count; i++) {
        if (g_color_object_handles[i] == handle)
            return g_color_object_values[i];
    }
    return 0x00000000;
}

static uint32_t object_kind_lookup(uint32_t handle)
{
    switch (handle) {
        case 0xDE64:
        case 0xDE65:
        case 0xDE66:
        case 0xDE67:
        case 0xDE68:
        case 0xDE69:
            return GDI_OBJECT_KIND_BRUSH;
        case 0xDE6A:
        case 0xDE6B:
        case 0xDE6C:
            return GDI_OBJECT_KIND_PEN;
        default:
            break;
    }

    for (int i = 0; i < g_object_kind_count; i++) {
        if (g_object_kind_handles[i] == handle)
            return g_object_kind_values[i];
    }
    return GDI_OBJECT_KIND_UNKNOWN;
}

static int is_null_pen_handle(uint32_t handle)
{
    return handle == 0xDE6C;
}

static int is_null_brush_handle(uint32_t handle)
{
    return handle == 0xDE69;
}

static void colorref_to_components(uint32_t color, CGFloat *r, CGFloat *g, CGFloat *b, CGFloat *a)
{
    *r = (CGFloat)((color >> 0) & 0xFF) / 255.0;
    *g = (CGFloat)((color >> 8) & 0xFF) / 255.0;
    *b = (CGFloat)((color >> 16) & 0xFF) / 255.0;
    *a = 1.0;
}

static CTFontRef font_lookup(uint32_t handle)
{
    if (handle < GDI_FONT_HANDLE_BASE) return NULL;
    int idx = (int)(handle - GDI_FONT_HANDLE_BASE);
    if (idx < 0 || idx >= g_font_count) return NULL;
    return g_fonts[idx];
}

uint32_t rosetta_gdi_create_font(int height, int weight, int italic,
                                  const uint16_t *faceName)
{
    if (g_font_count >= GDI_MAX_FONTS) return 0;
    int len = 0;
    while (faceName[len]) len++;
    NSString *name = [[NSString alloc] initWithCharacters:faceName length:len];
    CGFloat ctSize = (CGFloat)(height < 0 ? -height : (height ? height : 16));
    CTFontRef font = CTFontCreateWithName((CFStringRef)name, ctSize, NULL);
    if (!font) return 0;
    uint32_t h = GDI_FONT_HANDLE_BASE + (uint32_t)g_font_count;
    g_fonts[g_font_count] = font;
    g_font_count++;
    return h;
}

void rosetta_gdi_register_color_object(uint32_t handle, uint32_t color)
{
    for (int i = 0; i < g_color_object_count; i++) {
        if (g_color_object_handles[i] == handle) {
            g_color_object_values[i] = color;
            return;
        }
    }
    if (g_color_object_count >= GDI_MAX_COLOR_OBJECTS) return;
    g_color_object_handles[g_color_object_count] = handle;
    g_color_object_values[g_color_object_count] = color;
    g_color_object_count++;
}

void rosetta_gdi_register_object_kind(uint32_t handle, uint32_t kind)
{
    for (int i = 0; i < g_object_kind_count; i++) {
        if (g_object_kind_handles[i] == handle) {
            g_object_kind_values[i] = kind;
            return;
        }
    }
    if (g_object_kind_count >= GDI_MAX_OBJECT_KINDS) return;
    g_object_kind_handles[g_object_kind_count] = handle;
    g_object_kind_values[g_object_kind_count] = kind;
    g_object_kind_count++;
}

void rosetta_gdi_delete_font(uint32_t handle)
{
    CTFontRef font = font_lookup(handle);
    if (font) CFRelease(font);
}

/* ── Text state setters ── */

uint32_t rosetta_gdi_set_text_color(uint32_t hdc, uint32_t color)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 0xFF000000;
    uint32_t old = ctx->text_color;
    ctx->text_color = color;
    return old;
}

uint32_t rosetta_gdi_set_bk_color(uint32_t hdc, uint32_t color)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 0xFFFFFFFF;
    uint32_t old = ctx->bk_color;
    ctx->bk_color = color;
    return old;
}

int rosetta_gdi_set_bk_mode(uint32_t hdc, int mode)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 2;
    int old = ctx->bk_mode;
    ctx->bk_mode = mode;
    return old;
}

/* ── Text measurement via Core Text ── */

int rosetta_gdi_get_text_extent_point_32w(uint32_t hdc,
    const uint16_t *str, int len, int *out_cx, int *out_cy)
{
    GDIContext *ctx = context_get(hdc);
    if (!str || len <= 0) { *out_cx = 0; *out_cy = 0; return 1; }
    NSString *ns = [[NSString alloc] initWithCharacters:str length:len];
    NSFont *font = [NSFont systemFontOfSize:18];
    if (ctx) {
        CTFontRef selected = font_lookup(ctx->selected_font);
        if (selected) font = (__bridge NSFont *)selected;
    }
    NSDictionary *attrs = @{NSFontAttributeName: font};
    NSSize size = [ns sizeWithAttributes:attrs];
    *out_cx = (int)ceil(size.width);
    *out_cy = (int)ceil(size.height);
    return 1;
}

static CGContextRef surface_begin_context(GDIContext *ctx, int *w, int *h, uint32_t **pixels)
{
    if (!ctx) return NULL;
    pthread_mutex_lock(&g_fb_lock);
    if (!surface_get(ctx, w, h, pixels)) {
        pthread_mutex_unlock(&g_fb_lock);
        return NULL;
    }

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    if (!cs) {
        pthread_mutex_unlock(&g_fb_lock);
        return NULL;
    }
    CGContextRef cg = CGBitmapContextCreate(*pixels, *w, *h, 8, (size_t)(*w * 4),
        cs, kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst);
    CGColorSpaceRelease(cs);
    if (!cg) {
        pthread_mutex_unlock(&g_fb_lock);
        return NULL;
    }
    CGContextTranslateCTM(cg, 0, *h);
    CGContextScaleCTM(cg, 1, -1);
    return cg;
}

static void surface_end_context(CGContextRef cg)
{
    if (cg) CGContextRelease(cg);
    g_fb_dirty = 1;
    pthread_mutex_unlock(&g_fb_lock);
}

int rosetta_gdi_text_out_w(uint32_t hdc, int x, int y,
    const uint16_t *str, int len)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx || !str || len < 0) return 0;

    NSString *ns = [[NSString alloc] initWithCharacters:str length:(NSUInteger)len];
    if (!ns) return 0;

    int sw = 0, sh = 0;
    uint32_t *pixels = NULL;
    CGContextRef cg = surface_begin_context(ctx, &sw, &sh, &pixels);
    (void)sw;
    (void)sh;
    (void)pixels;
    if (!cg) return 0;

    NSFont *font = [NSFont systemFontOfSize:18];
    CTFontRef selected = font_lookup(ctx->selected_font);
    if (selected) font = (__bridge NSFont *)selected;

    CGFloat fr, fg, fb, fa;
    colorref_to_components(ctx->text_color, &fr, &fg, &fb, &fa);

    NSMutableDictionary *attrs = [@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:fr green:fg blue:fb alpha:fa],
    } mutableCopy];

    NSSize size = [ns sizeWithAttributes:attrs];
    if (ctx->bk_mode != 1) {
        CGFloat br, bg, bb, ba;
        colorref_to_components(ctx->bk_color, &br, &bg, &bb, &ba);
        CGContextSetRGBFillColor(cg, br, bg, bb, ba);
        CGContextFillRect(cg, CGRectMake(x, y, ceil(size.width), ceil(size.height)));
    }

    NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithCGContext:cg flipped:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:gc];
    [ns drawAtPoint:NSMakePoint((CGFloat)x, (CGFloat)y) withAttributes:attrs];
    [NSGraphicsContext restoreGraphicsState];

    surface_end_context(cg);
    return 1;
}

int rosetta_gdi_ellipse(uint32_t hdc, int left, int top, int right, int bottom)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 0;

    int sw = 0, sh = 0;
    uint32_t *pixels = NULL;
    CGContextRef cg = surface_begin_context(ctx, &sw, &sh, &pixels);
    (void)sw; (void)sh; (void)pixels;
    if (!cg) return 0;

    CGRect rect = CGRectMake(left, top, right - left, bottom - top);
    CGContextSaveGState(cg);
    CGContextClipToRect(cg, rect);
    CGContextBeginPath(cg);
    CGContextAddEllipseInRect(cg, rect);

    int has_brush = !is_null_brush_handle(ctx->selected_brush);
    int has_pen = !is_null_pen_handle(ctx->selected_pen);

    if (has_brush) {
        CGFloat r, g, b, a;
        colorref_to_components(color_object_lookup(ctx->selected_brush), &r, &g, &b, &a);
        CGContextSetRGBFillColor(cg, r, g, b, a);
    }
    if (has_pen) {
        CGFloat r, g, b, a;
        colorref_to_components(color_object_lookup(ctx->selected_pen), &r, &g, &b, &a);
        CGContextSetRGBStrokeColor(cg, r, g, b, a);
        CGContextSetLineWidth(cg, 1.0);
    }

    if (has_brush && has_pen) CGContextDrawPath(cg, kCGPathFillStroke);
    else if (has_brush) CGContextDrawPath(cg, kCGPathFill);
    else if (has_pen) CGContextDrawPath(cg, kCGPathStroke);
    CGContextRestoreGState(cg);
    surface_end_context(cg);
    return 1;
}

int rosetta_gdi_arc(uint32_t hdc, int left, int top, int right, int bottom,
    int xStart, int yStart, int xEnd, int yEnd)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 0;

    int sw = 0, sh = 0;
    uint32_t *pixels = NULL;
    CGContextRef cg = surface_begin_context(ctx, &sw, &sh, &pixels);
    (void)sw; (void)sh; (void)pixels;
    if (!cg) return 0;

    CGRect rect = CGRectMake(left, top, right - left, bottom - top);
    const CGFloat cx = CGRectGetMidX(rect);
    const CGFloat cy = CGRectGetMidY(rect);
    const CGFloat rx = rect.size.width / 2.0;
    const CGFloat ry = rect.size.height / 2.0;
    const CGFloat start_angle = atan2(cy - (CGFloat)yStart, (CGFloat)xStart - cx);
    const CGFloat end_angle = atan2(cy - (CGFloat)yEnd, (CGFloat)xEnd - cx);

    CGContextSaveGState(cg);
    CGContextClipToRect(cg, rect);
    CGContextTranslateCTM(cg, cx, cy);
    if (rx != 0 && ry != 0) CGContextScaleCTM(cg, rx, ry);
    CGContextBeginPath(cg);
    CGContextAddArc(cg, 0, 0, 1.0, start_angle, end_angle, 0);

    CGFloat r, g, b, a;
    colorref_to_components(color_object_lookup(ctx->selected_pen), &r, &g, &b, &a);
    CGContextSetRGBStrokeColor(cg, r, g, b, a);
    CGContextSetLineWidth(cg, (rx != 0) ? (1.0 / rx) : 1.0);
    CGContextStrokePath(cg);
    CGContextRestoreGState(cg);

    surface_end_context(cg);
    return 1;
}

int rosetta_gdi_polygon(uint32_t hdc, const void *points, int count)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx || !points || count <= 1) return 0;

    int sw = 0, sh = 0;
    uint32_t *pixels = NULL;
    CGContextRef cg = surface_begin_context(ctx, &sw, &sh, &pixels);
    (void)sw; (void)sh; (void)pixels;
    if (!cg) return 0;

    const RosettaWinPoint *pts = (const RosettaWinPoint *)points;
    int min_x = pts[0].x;
    int min_y = pts[0].y;
    int max_x = pts[0].x;
    int max_y = pts[0].y;
    for (int i = 1; i < count; i++) {
        if (pts[i].x < min_x) min_x = pts[i].x;
        if (pts[i].y < min_y) min_y = pts[i].y;
        if (pts[i].x > max_x) max_x = pts[i].x;
        if (pts[i].y > max_y) max_y = pts[i].y;
    }
    CGContextSaveGState(cg);
    CGContextClipToRect(cg, CGRectMake(min_x - 1, min_y - 1,
                                       (max_x - min_x) + 3,
                                       (max_y - min_y) + 3));
    CGContextBeginPath(cg);
    CGContextMoveToPoint(cg, pts[0].x, pts[0].y);
    for (int i = 1; i < count; i++) {
        CGContextAddLineToPoint(cg, pts[i].x, pts[i].y);
    }
    CGContextClosePath(cg);

    int has_brush = !is_null_brush_handle(ctx->selected_brush);
    int has_pen = !is_null_pen_handle(ctx->selected_pen);
    if (has_brush) {
        CGFloat r, g, b, a;
        colorref_to_components(color_object_lookup(ctx->selected_brush), &r, &g, &b, &a);
        CGContextSetRGBFillColor(cg, r, g, b, a);
    }
    if (has_pen) {
        CGFloat r, g, b, a;
        colorref_to_components(color_object_lookup(ctx->selected_pen), &r, &g, &b, &a);
        CGContextSetRGBStrokeColor(cg, r, g, b, a);
        CGContextSetLineWidth(cg, 1.0);
    }

    if (has_brush && has_pen) CGContextDrawPath(cg, kCGPathFillStroke);
    else if (has_brush) CGContextDrawPath(cg, kCGPathFill);
    else if (has_pen) CGContextDrawPath(cg, kCGPathStroke);
    CGContextRestoreGState(cg);
    surface_end_context(cg);
    return 1;
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

static void menu_reset_model(void)
{
    memset(&g_menu_model, 0, sizeof(g_menu_model));
}

static void menu_strip_ampersands(char *text)
{
    size_t write_idx = 0;
    for (size_t i = 0; text[i] != '\0'; i++) {
        if (text[i] == '&') continue;
        if (text[i] == '\t') break;
        text[write_idx++] = text[i];
    }
    text[write_idx] = '\0';
}

static void menu_trim(char *text)
{
    size_t len = strlen(text);
    while (len > 0 && (text[len - 1] == '\r' || text[len - 1] == '\n' || text[len - 1] == ' ' || text[len - 1] == '\t'))
        text[--len] = '\0';
    size_t start = 0;
    while (text[start] == ' ' || text[start] == '\t') start++;
    if (start > 0) memmove(text, text + start, strlen(text + start) + 1);
}

static unsigned int menu_lookup_command_id(const char *symbol)
{
    FILE *fp = fopen("src/resource.h", "r");
    if (!fp) return 0;
    char line[512];
    unsigned int result = 0;
    while (fgets(line, sizeof(line), fp)) {
        char name[128];
        unsigned int value = 0;
        if (sscanf(line, "#define %127s %u", name, &value) == 2) {
            if (strcmp(name, symbol) == 0) {
                result = value;
                break;
            }
        }
    }
    fclose(fp);
    return result;
}

static int menu_parse_item_line(const char *line, RosettaMenuItem *item)
{
    if (strstr(line, "MENUITEM") == NULL) return 0;
    if (strstr(line, "SEPARATOR") != NULL) {
        memset(item, 0, sizeof(*item));
        item->is_separator = 1;
        return 1;
    }

    const char *first_quote = strchr(line, '"');
    const char *second_quote = first_quote ? strchr(first_quote + 1, '"') : NULL;
    if (!first_quote || !second_quote) return 0;
    size_t len = (size_t)(second_quote - (first_quote + 1));
    if (len >= sizeof(item->title)) len = sizeof(item->title) - 1;
    memcpy(item->title, first_quote + 1, len);
    item->title[len] = '\0';
    menu_strip_ampersands(item->title);
    menu_trim(item->title);

    const char *comma = strchr(second_quote, ',');
    if (!comma) return 0;
    char symbol[128];
    size_t idx = 0;
    comma++;
    while (*comma == ' ' || *comma == '\t') comma++;
    while (*comma && *comma != ' ' && *comma != '\t' && *comma != '\r' && *comma != '\n' && idx + 1 < sizeof(symbol)) {
        symbol[idx++] = *comma++;
    }
    symbol[idx] = '\0';
    item->command_id = menu_lookup_command_id(symbol);
    item->is_separator = 0;
    return item->command_id != 0;
}

static int menu_parse_popup_title(const char *line, char *out, size_t out_len)
{
    const char *popup = strstr(line, "POPUP");
    if (!popup) return 0;
    const char *first_quote = strchr(popup, '"');
    if (!first_quote) return 0;
    const char *second_quote = strchr(first_quote + 1, '"');
    if (!second_quote) return 0;
    size_t len = (size_t)(second_quote - (first_quote + 1));
    if (len >= out_len) len = out_len - 1;
    memcpy(out, first_quote + 1, len);
    out[len] = '\0';
    menu_strip_ampersands(out);
    menu_trim(out);
    return out[0] != '\0';
}

static void menu_try_load_from_cwd(void)
{
    FILE *fp = fopen("src/menu.inc", "r");
    if (!fp) return;

    menu_reset_model();
    g_menu_model.handle = 0xFACE;

    char line[512];
    int nesting = 0;
    int active_popup = -1;
    while (fgets(line, sizeof(line), fp)) {
        char copy[512];
        strncpy(copy, line, sizeof(copy) - 1);
        copy[sizeof(copy) - 1] = '\0';
        menu_trim(copy);
        if (strncmp(copy, "BEGIN", 5) == 0) {
            nesting++;
            continue;
        }
        if (strncmp(copy, "END", 3) == 0) {
            if (nesting == 2) active_popup = -1;
            if (nesting > 0) nesting--;
            continue;
        }
        if (nesting == 1 && strstr(copy, "POPUP") != NULL && g_menu_model.count < ROSETTA_MAX_MENU_TOPLEVEL) {
            if (menu_parse_popup_title(copy, g_menu_model.titles[g_menu_model.count], ROSETTA_MAX_MENU_TITLE)) {
                active_popup = g_menu_model.count;
                g_menu_model.count++;
            }
        } else if (nesting == 2 && active_popup >= 0 && g_menu_model.item_counts[active_popup] < ROSETTA_MAX_MENU_ITEMS) {
            RosettaMenuItem item;
            if (menu_parse_item_line(copy, &item)) {
                g_menu_model.items[active_popup][g_menu_model.item_counts[active_popup]++] = item;
            }
        }
    }
    fclose(fp);
}

static int posted_message_push(void *hwnd, unsigned int msg, uintptr_t wParam, intptr_t lParam)
{
    pthread_mutex_lock(&g_posted_lock);
    int next = (g_posted_tail + 1) % ROSETTA_MAX_POSTED_MESSAGES;
    if (next == g_posted_head) {
        pthread_mutex_unlock(&g_posted_lock);
        return 0;
    }
    g_posted_messages[g_posted_tail].hwnd = hwnd;
    g_posted_messages[g_posted_tail].message = msg;
    g_posted_messages[g_posted_tail].wParam = wParam;
    g_posted_messages[g_posted_tail].lParam = lParam;
    g_posted_messages[g_posted_tail].time = 0;
    g_posted_messages[g_posted_tail].pt_x = 0;
    g_posted_messages[g_posted_tail].pt_y = 0;
    g_posted_tail = next;
    pthread_mutex_unlock(&g_posted_lock);
    return 1;
}

@interface RosettaRootView : NSView
@end

@implementation RosettaRootView
- (BOOL)isFlipped { return YES; }
@end

@interface RosettaMenuBarView : NSView
@end

@implementation RosettaMenuBarView

- (BOOL)isFlipped { return YES; }

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithCalibratedWhite:0.94 alpha:1.0] setFill];
    NSRectFill(dirtyRect);

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont menuFontOfSize:14],
        NSForegroundColorAttributeName: [NSColor blackColor],
    };

    CGFloat x = 8.0;
    for (int i = 0; i < g_menu_model.count; i++) {
        NSString *title = [NSString stringWithUTF8String:g_menu_model.titles[i]];
        NSSize sz = [title sizeWithAttributes:attrs];
        g_menu_model.rects[i] = NSMakeRect(x, 2.0, sz.width + 16.0, ROSETTA_MENU_HEIGHT - 4.0);
        [title drawAtPoint:NSMakePoint(x + 8.0, 4.0) withAttributes:attrs];
        x += sz.width + 24.0;
    }

    [[NSColor colorWithCalibratedWhite:0.70 alpha:1.0] setStroke];
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0, ROSETTA_MENU_HEIGHT - 0.5)];
    [line lineToPoint:NSMakePoint(self.bounds.size.width, ROSETTA_MENU_HEIGHT - 0.5)];
    [line stroke];
}

- (void)menuItemChosen:(id)sender
{
    NSNumber *command = [sender representedObject];
    if (!command) return;
    posted_message_push((__bridge void *)g_window, 0x0211, 0, 0); /* WM_ENTERMENULOOP */
    posted_message_push((__bridge void *)g_window, 0x0111, (uintptr_t)[command unsignedIntValue], 0); /* WM_COMMAND */
    posted_message_push((__bridge void *)g_window, 0x0212, 0, 0); /* WM_EXITMENULOOP */
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil];
    for (int i = 0; i < g_menu_model.count; i++) {
        if (NSPointInRect(pt, g_menu_model.rects[i])) {
            NSMenu *menu = [[NSMenu alloc] initWithTitle:[NSString stringWithUTF8String:g_menu_model.titles[i]]];
            for (int j = 0; j < g_menu_model.item_counts[i]; j++) {
                RosettaMenuItem *item = &g_menu_model.items[i][j];
                if (item->is_separator) {
                    [menu addItem:[NSMenuItem separatorItem]];
                    continue;
                }
                NSMenuItem *nsitem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:item->title]
                                                                action:@selector(menuItemChosen:)
                                                         keyEquivalent:@""];
                [nsitem setTarget:self];
                [nsitem setRepresentedObject:@(item->command_id)];
                [menu addItem:nsitem];
            }
            [NSMenu popUpContextMenu:menu withEvent:event forView:self];
            return;
        }
    }
}

@end


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

- (void)updateMouseFromEvent:(NSEvent *)event
{
    NSPoint pt = [event locationInWindow];
    pt = [self convertPoint:pt fromView:nil];
    g_mouse_x = (int)pt.x;
    g_mouse_y = (int)pt.y;
}

- (void)mouseDown:(NSEvent *)event
{
    [self updateMouseFromEvent:event];
    if (([event modifierFlags] & NSEventModifierFlagControl) != 0) {
        g_mouse_buttons |= 2;
    } else {
        g_mouse_buttons |= 1;
    }
}

- (void)mouseUp:(NSEvent *)event
{
    [self updateMouseFromEvent:event];
    if (([event modifierFlags] & NSEventModifierFlagControl) != 0) {
        g_mouse_buttons &= ~2;
    } else {
        g_mouse_buttons &= ~1;
    }
}

- (void)mouseDragged:(NSEvent *)event
{
    [self updateMouseFromEvent:event];
}

- (void)mouseMoved:(NSEvent *)event
{
    [self updateMouseFromEvent:event];
}

- (void)rightMouseDown:(NSEvent *)event
{
    [self updateMouseFromEvent:event];
    g_mouse_buttons |= 2;
}

- (void)rightMouseUp:(NSEvent *)event
{
    [self updateMouseFromEvent:event];
    g_mouse_buttons &= ~2;
}

- (void)rightMouseDragged:(NSEvent *)event
{
    [self updateMouseFromEvent:event];
}

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
    NSView     *_rootView;
    RosettaMenuBarView *_menuBarView;
    GDIView    *_gdiView;
    int         _width;
    int         _height;
    NSThread   *_gameThread;
    NSString   *_windowTitle;
}
- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)title;
- (void)startGame:(void (*)(void *))func arg:(void *)arg;
- (void)syncMenuLayout;
@end

@implementation GDIWindowController

- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)title
{
    _width  = w;
    _height = h;
    _windowTitle = [NSString stringWithUTF8String:title ? title : "Rosetta 3 — GDI Window"];

    /* Create framebuffer */
    framebuffer_resize(w, h);

    CGFloat menuHeight = g_menu_model.visible ? ROSETTA_MENU_HEIGHT : 0.0;
    _rootView = [[RosettaRootView alloc] initWithFrame:NSMakeRect(0, 0, (CGFloat)w, (CGFloat)h + menuHeight)];
    _menuBarView = [[RosettaMenuBarView alloc] initWithFrame:NSMakeRect(0, 0, (CGFloat)w, menuHeight)];
    [_menuBarView setHidden:!g_menu_model.visible];
    [_rootView addSubview:_menuBarView];
    _gdiView = [[GDIView alloc] initWithWidth:w height:h];
    [_gdiView setFrame:NSMakeRect(0, menuHeight, (CGFloat)w, (CGFloat)h)];
    [_rootView addSubview:_gdiView];
    NSRect viewFrame = [_rootView frame];

    NSUInteger style = NSWindowStyleMaskTitled
                     | NSWindowStyleMaskClosable
                     | NSWindowStyleMaskMiniaturizable;
    NSWindow *win = [[NSWindow alloc]
        initWithContentRect:viewFrame
                  styleMask:style
                    backing:NSBackingStoreBuffered
                      defer:NO];
    [win setContentView:_rootView];
    [win setTitle:_windowTitle];
    [win makeFirstResponder:_gdiView];
    [win center];
    [win setAcceptsMouseMovedEvents:YES];
    [win setReleasedWhenClosed:NO];

    /* Set global window pointer so GetConsoleWindow() etc. work */
    g_window = win;

    self = [super initWithWindow:win];
    if (self) {
        [win setDelegate:self];
        _gameThread = nil;
        g_window_controller = self;
    }
    return self;
}

- (void)syncMenuLayout
{
    if (!_rootView || !_gdiView || !_menuBarView) return;
    CGFloat menuHeight = g_menu_model.visible ? ROSETTA_MENU_HEIGHT : 0.0;
    [_rootView setFrame:NSMakeRect(0, 0, _width, _height + menuHeight)];
    [_menuBarView setFrame:NSMakeRect(0, 0, _width, menuHeight)];
    [_menuBarView setHidden:!g_menu_model.visible];
    [_gdiView setFrame:NSMakeRect(0, menuHeight, _width, _height)];
    [_menuBarView setNeedsDisplay:YES];
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
    if (!id) {
        GDI_LOG("GetDC(%p) FAILED — DC pool exhausted", hwnd);
        return 0;
    }
    GDI_LOG("GetDC(%p) → 0x%04X", hwnd, id);
    return id;
}

uint32_t rosetta_gdi_create_compatible_dc(uint32_t hdc)
{
    (void)hdc;
    uint32_t id = context_create();
    if (!id) {
        GDI_LOG("CreateCompatibleDC(0x%04X) FAILED — DC pool exhausted", hdc);
        return 0;
    }
    GDI_LOG("CreateCompatibleDC(0x%04X) → 0x%04X", hdc, id);
    return id;
}

uint32_t rosetta_gdi_select_object(uint32_t hdc, uint32_t hgdiobj)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) {
        GDI_LOG("SelectObject(0x%04X, 0x%04X) FAILED — no DC", hdc, hgdiobj);
        return 0;
    }

    /* Check if it's a bitmap (0xBEEF range) */
    GDIBitmap *bmp = bitmap_lookup(hgdiobj);
    if (bmp) {
        uint32_t previous = ctx->selected ? ctx->selected->id : 0;
        ctx->selected = bmp;
        GDI_LOGV("SelectObject(0x%04X, 0x%04X) → bitmap OK", hdc, hgdiobj);
        return previous;
    }

    /* Non-bitmap GDI objects: brushes, pens, fonts. */
    if (hgdiobj > 0) {
        if (hgdiobj >= GDI_FONT_HANDLE_BASE) {
            /* Font handle — stored in font slot only */
            uint32_t previous = ctx->selected_font;
            ctx->selected_font = hgdiobj;
            GDI_LOGV("SelectObject(0x%04X, 0x%04X) → font selected", hdc, hgdiobj);
            return previous;
        } else if (object_kind_lookup(hgdiobj) == GDI_OBJECT_KIND_BRUSH) {
            uint32_t previous = ctx->selected_brush;
            ctx->selected_brush = hgdiobj;
            GDI_LOGV("SelectObject(0x%04X, 0x%04X) → brush selected", hdc, hgdiobj);
            return previous;
        } else if (object_kind_lookup(hgdiobj) == GDI_OBJECT_KIND_PEN) {
            uint32_t previous = ctx->selected_pen;
            ctx->selected_pen = hgdiobj;
            GDI_LOGV("SelectObject(0x%04X, 0x%04X) → pen selected", hdc, hgdiobj);
            return previous;
        } else {
            uint32_t previous = ctx->selected_brush;
            ctx->selected_brush = hgdiobj;
            GDI_LOGV("SelectObject(0x%04X, 0x%04X) → generic object selected", hdc, hgdiobj);
            return previous;
        }
    }

    /* hgdiobj == 0 is a no-op — return 0 (NULL) like real Windows */
    GDI_LOGV("SelectObject(0x%04X, 0x%04X) → NULL (no-op)", hdc, hgdiobj);
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

        int lazy_w = g_win_width > 0 ? g_win_width : 640;
        int lazy_h = g_win_height > 0 ? g_win_height : 480;
        framebuffer_resize(lazy_w, lazy_h);

        pthread_mutex_lock(&g_fb_lock);
        if (!g_framebuffer || !g_framebuffer->pixels) {
            pthread_mutex_unlock(&g_fb_lock);
            GDI_LOG("BitBlt(dst=0x%04X, src=0x%04X) DEFERRED — framebuffer unavailable", hdc_dest, hdc_src);
            rosetta3_debug_log_host_call("ARM64", "gdi", "BitBlt deferred: framebuffer unavailable during startup");
            return 1;
        }
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
            GDI_LOGV("DeleteObject(0x%04X) FAILED — still selected in DC 0x%04X",
                     hgdiobj, g_contexts[i].id);
            return 0;
        }
        if (g_contexts[i].selected_font == hgdiobj) {
            GDI_LOGV("DeleteObject(0x%04X) FAILED — font still selected in DC 0x%04X",
                     hgdiobj, g_contexts[i].id);
            return 0;
        }
    }
    /* Font handles need special cleanup */
    if (hgdiobj >= GDI_FONT_HANDLE_BASE) {
        rosetta_gdi_delete_font(hgdiobj);
        return 1;
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

void *rosetta_gdi_load_menu_a(void *hInst, const char *name)
{
    (void)hInst;
    (void)name;
    if (g_menu_model.count == 0) {
        menu_try_load_from_cwd();
    }
    return g_menu_model.count > 0 ? (void *)(uintptr_t)g_menu_model.handle : NULL;
}

void *rosetta_gdi_load_menu_w(void *hInst, const unsigned short *name)
{
    (void)name;
    return rosetta_gdi_load_menu_a(hInst, NULL);
}

int rosetta_gdi_set_menu(void *hwnd, void *menu)
{
    (void)hwnd;
    if (menu != NULL && (uint32_t)(uintptr_t)menu != g_menu_model.handle) {
        GDI_LOG("SetMenu(%p) — unknown menu handle", menu);
    }
    g_menu_model.visible = (menu != NULL && (uint32_t)(uintptr_t)menu == g_menu_model.handle);
    if (g_window_controller) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [(GDIWindowController *)g_window_controller syncMenuLayout];
        });
    }
    return 1;
}

int rosetta_gdi_post_message(void *hwnd, unsigned int msg, uintptr_t wParam, intptr_t lParam)
{
    return posted_message_push(hwnd, msg, wParam, lParam);
}

int rosetta_gdi_pop_message(void *msg_out)
{
    if (!msg_out) {
        rosetta3_runtime_abi_host_violation("gdi", "pop_message", "GetMessage/PeekMessage received null output buffer");
        return 0;
    }
    pthread_mutex_lock(&g_posted_lock);
    if (g_posted_head == g_posted_tail) {
        pthread_mutex_unlock(&g_posted_lock);
        return 0;
    }
    RosettaPostedMessage msg = g_posted_messages[g_posted_head];
    g_posted_head = (g_posted_head + 1) % ROSETTA_MAX_POSTED_MESSAGES;
    pthread_mutex_unlock(&g_posted_lock);

    typedef struct {
        void *hwnd;
        unsigned int message;
        uintptr_t wParam;
        intptr_t lParam;
        unsigned int time;
        RosettaWinPoint pt;
    } RosettaWinMsg;
    RosettaWinMsg *out = (RosettaWinMsg *)msg_out;
    out->hwnd = msg.hwnd;
    out->message = msg.message;
    out->wParam = msg.wParam;
    out->lParam = msg.lParam;
    out->time = msg.time;
    out->pt.x = msg.pt_x;
    out->pt.y = msg.pt_y;
    return 1;
}

unsigned long rosetta_gdi_check_menu_item(void *menu, unsigned int item, unsigned int check)
{
    (void)menu;
    (void)item;
    (void)check;
    return 0;
}

int rosetta_gdi_get_menu_item_rect(void *hwnd, void *menu, unsigned int item, void *rect)
{
    (void)hwnd;
    if (!menu || (uint32_t)(uintptr_t)menu != g_menu_model.handle || !rect) return 0;
    if (item >= (unsigned int)g_menu_model.count) return 0;
    typedef struct { int left; int top; int right; int bottom; } R3Rect;
    R3Rect *out = (R3Rect *)rect;
    NSRect r = g_menu_model.rects[item];
    out->left = (int)r.origin.x;
    out->top = (int)r.origin.y;
    out->right = (int)(r.origin.x + r.size.width);
    out->bottom = (int)(r.origin.y + r.size.height);
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

/* ── CreateCompatibleBitmap — allocates a real pixel buffer ── */

uint32_t rosetta_gdi_create_compatible_bitmap(int width, int height)
{
    if (width <= 0 || height <= 0) return 0;

    GDIBitmap *bmp = calloc(1, sizeof(GDIBitmap));
    if (!bmp) return 0;

    bmp->pixels = calloc((size_t)(width * height), 4);
    if (!bmp->pixels) { free(bmp); return 0; }

    bmp->width  = width;
    bmp->height = height;
    bmp->stride = width * 4;

    uint32_t id = bitmap_register(bmp);
    if (id == 0) {
        free(bmp->pixels);
        free(bmp);
        return 0;
    }

    GDI_LOG("CreateCompatibleBitmap(%dx%d) → 0x%04X", width, height, id);
    return id;
}

/* ── Write pixels through a DC: if it has a selected bitmap, write there;
     otherwise write directly to the framebuffer.  Returns the target
     surface dimensions and a writeable pointer (locked).              ── */

static int surface_get(GDIContext *ctx, int *w, int *h, uint32_t **pixels)
{
    if (ctx->selected) {
        *w = ctx->selected->width;
        *h = ctx->selected->height;
        *pixels = ctx->selected->pixels;
        return 1;
    }
    if (g_framebuffer && g_framebuffer->pixels) {
        *w = g_framebuffer->width;
        *h = g_framebuffer->height;
        *pixels = g_framebuffer->pixels;
        return 1;
    }
    return 0;
}

/* ── FillRect — fills a rectangle on the DC's surface ── */

void rosetta_gdi_fill_rect(uint32_t hdc, int left, int top,
                            int right, int bottom, uint32_t color)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return;

    pthread_mutex_lock(&g_fb_lock);

    int sw, sh;
    uint32_t *pixels;
    if (!surface_get(ctx, &sw, &sh, &pixels)) {
        pthread_mutex_unlock(&g_fb_lock);
        return;
    }

    /* Clamp */
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (right > sw) right = sw;
    if (bottom > sh) bottom = sh;

    for (int y = top; y < bottom; y++) {
        for (int x = left; x < right; x++) {
            pixels[y * sw + x] = color;
        }
    }
    g_fb_dirty = 1;
    pthread_mutex_unlock(&g_fb_lock);

    GDI_LOGV("FillRect(0x%04X, [%d,%d-%d,%d], color=0x%06X)", hdc, left, top, right, bottom, color);
}

/* ── MoveToEx ── */

void rosetta_gdi_move_to_ex(uint32_t hdc, int x, int y)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return;
    ctx->cur_x = x;
    ctx->cur_y = y;
}

/* ── LineTo (Bresenham on DC's surface) ── */

int rosetta_gdi_line_to(uint32_t hdc, int x, int y, uint32_t color)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 0;

    int x0 = ctx->cur_x;
    int y0 = ctx->cur_y;
    int x1 = x;
    int y1 = y;

    ctx->cur_x = x1;
    ctx->cur_y = y1;

    pthread_mutex_lock(&g_fb_lock);

    int sw, sh;
    uint32_t *pixels;
    if (!surface_get(ctx, &sw, &sh, &pixels)) {
        pthread_mutex_unlock(&g_fb_lock);
        return 0;
    }

    /* Bresenham */
    int dx = x1 > x0 ? x1 - x0 : x0 - x1;
    int dy = y1 > y0 ? y1 - y0 : y0 - y1;
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    while (1) {
        if (x0 >= 0 && x0 < sw && y0 >= 0 && y0 < sh) {
            pixels[y0 * sw + x0] = color;
        }
        if (x0 == x1 && y0 == y1) break;
        int e2 = 2 * err;
        if (e2 > -dy) { err -= dy; x0 += sx; }
        if (e2 <  dx) { err += dx; y0 += sy; }
    }

    g_fb_dirty = 1;
    pthread_mutex_unlock(&g_fb_lock);
    return 1;
}

/* ── GetSelectedPen ── */

uint32_t rosetta_gdi_get_selected_pen(uint32_t hdc)
{
    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 0;
    return ctx->selected_pen;
}

/* ── DrawEdge (3D border effect on framebuffer) ── */

int rosetta_gdi_draw_edge(uint32_t hdc, int left, int top,
                           int right, int bottom,
                           uint32_t edge, uint32_t flags)
{
    (void)hdc;

    /* Determine whether this is a raised or sunken edge.
       EDGE_RAISED = BDR_RAISEDOUTER|BDR_RAISEDINNER = 0x0005
       EDGE_SUNKEN = BDR_SUNKENOUTER|BDR_SUNKENINNER = 0x000A
       BDR_SUNKENOUTER = 0x0002 (often used for cells) */
    int is_raised = 0;
    int is_sunken = 0;

    if ((edge & 0x0005) == 0x0005) is_raised = 1;   /* EDGE_RAISED */
    if ((edge & 0x000A) == 0x000A) is_sunken = 1;   /* EDGE_SUNKEN */
    if (edge == 0x0002) is_sunken = 1;               /* BDR_SUNKENOUTER */

    uint32_t light = 0x00FFFFFF; /* white highlight */
    uint32_t dark  = 0x00808080; /* gray shadow */

    GDIContext *ctx = context_get(hdc);
    if (!ctx) return 0;

    pthread_mutex_lock(&g_fb_lock);

    int sw, sh;
    uint32_t *pixels;
    if (!surface_get(ctx, &sw, &sh, &pixels)) {
        pthread_mutex_unlock(&g_fb_lock);
        return 0;
    }

    /* Clamp */
    if (left   < 0) left   = 0;
    if (top    < 0) top    = 0;
    if (right  > sw) right  = sw;
    if (bottom > sh) bottom = sh;
    if (left >= right || top >= bottom) {
        pthread_mutex_unlock(&g_fb_lock);
        return 0;
    }

    /* Draw the four edges.  For BF_RECT (all sides) or specific side flags.
       For simplicity we draw a simple 1-pixel border when BF_RECT is set. */

    if (flags & BF_RECT) {
        uint32_t top_color = is_raised ? light : dark;
        for (int x = left; x < right; x++) {
            pixels[top * sw + x] = top_color;
        }
        uint32_t bot_color = is_raised ? dark : light;
        for (int x = left; x < right; x++) {
            pixels[(bottom - 1) * sw + x] = bot_color;
        }
        uint32_t lft_color = is_raised ? light : dark;
        for (int y = top; y < bottom; y++) {
            pixels[y * sw + left] = lft_color;
        }
        uint32_t rgt_color = is_raised ? dark : light;
        for (int x = right - 1, y = top; y < bottom; y++) {
            pixels[y * sw + x] = rgt_color;
        }
    }

    g_fb_dirty = 1;
    pthread_mutex_unlock(&g_fb_lock);
    return 1;
}
