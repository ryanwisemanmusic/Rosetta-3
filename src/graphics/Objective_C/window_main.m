/*
 * window_main.m
 * Rosette — Native macOS Cocoa console-emulation window.
 *
 * Routes Win32 console API calls into a proper NSWindow / NSView
 * renderer instead of emitting ANSI escape codes to the terminal.
 *
 * Usage from C/C++:
 *   rosette_window_run(thread_func, arg) — starts the app, creates
 *   the window, then calls thread_func(arg) on a background thread.
 *
 * The background thread can use the standard Win32 console functions
 * declared in include/shims/win32/windows.h (GetStdHandle,
 * SetConsoleTextAttribute, SetConsoleCursorPosition, etc.) – this
 * file provides the implementations that draw into the Cocoa window.
 */

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#include "../common/keyboard/rosette_keyboard.h"
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* ========================================================================= */
/* Win32 -> Cocoa colour mapping (also used by the C shim layer)            */
/* ========================================================================= */

/*
 * Standard 16-colour ANSI / Win32 console palette mapped to macOS
 * calibrated RGBA values.  Index = (foreground bits 0-3).
 */
static const CGFloat rosette_palette[16][4] = {
    /* 0  Black       */ { 0.00f, 0.00f, 0.00f, 1.0f },
    /* 1  Dark Blue   */ { 0.00f, 0.00f, 0.67f, 1.0f },
    /* 2  Dark Green  */ { 0.00f, 0.67f, 0.00f, 1.0f },
    /* 3  Dark Cyan   */ { 0.00f, 0.67f, 0.67f, 1.0f },
    /* 4  Dark Red    */ { 0.67f, 0.00f, 0.00f, 1.0f },
    /* 5  Dark Magenta*/ { 0.67f, 0.00f, 0.67f, 1.0f },
    /* 6  Dark Yellow */ { 0.67f, 0.67f, 0.00f, 1.0f },
    /* 7  Gray        */ { 0.67f, 0.67f, 0.67f, 1.0f },
    /* 8  Dark Gray   */ { 0.33f, 0.33f, 0.33f, 1.0f },
    /* 9  Blue        */ { 0.33f, 0.33f, 1.00f, 1.0f },
    /* 10 Green       */ { 0.33f, 1.00f, 0.33f, 1.0f },
    /* 11 Cyan        */ { 0.33f, 1.00f, 1.00f, 1.0f },
    /* 12 Red         */ { 1.00f, 0.33f, 0.33f, 1.0f },
    /* 13 Magenta     */ { 1.00f, 0.33f, 1.00f, 1.0f },
    /* 14 Yellow      */ { 1.00f, 1.00f, 0.33f, 1.0f },
    /* 15 White       */ { 1.00f, 1.00f, 1.00f, 1.0f },
};

/*
 * Convert a Win32 WORD attribute to (foreground_index, background_index).
 *   bits 0-3 : foreground colour  (0-15)
 *   bit  3   : foreground intensity (bright toggle in 0-7 → 8-15)
 *   bits 4-6 : background colour (0-7)
 *   bit  7   : background intensity
 */
static void rosette_unpack_attr(unsigned short attr,
                                int *fg_idx, int *bg_idx)
{
    int fg = attr & 0x0F;
    int bg = (attr >> 4) & 0x07;
    if (attr & 0x08) fg |= 0x08;   /* foreground intensity → bright */
    if (attr & 0x80) bg |= 0x08;   /* background intensity → bright */
    *fg_idx = fg & 0x0F;
    *bg_idx = bg & 0x0F;
}

/* ========================================================================= */
/* Console character buffer                                                  */
/* ========================================================================= */

typedef struct {
    unsigned short  ch;       /* Unicode character */
    unsigned short  attr;     /* Win32 WORD attribute (same layout as above) */
} ConsoleCell;

typedef struct {
    int             width;
    int             height;
    ConsoleCell    *cells;    /* row-major, [y * width + x] */
    int             cursor_x;
    int             cursor_y;
    int             cursor_visible; /* boolean */
} ConsoleBuffer;

static ConsoleBuffer *rosette_console_buf = NULL;
static pthread_mutex_t rosette_console_lock = PTHREAD_MUTEX_INITIALIZER;

/* ----------------------------------------------------------------- */
/* Initialise / resize the console buffer                             */
/* ----------------------------------------------------------------- */
ConsoleBuffer *rosette_console_init(int w, int h)
{
    ConsoleBuffer *buf = calloc(1, sizeof(ConsoleBuffer));
    if (!buf) return NULL;
    buf->width  = w;
    buf->height = h;
    buf->cells  = calloc((size_t)(w * h), sizeof(ConsoleCell));
    if (!buf->cells) { free(buf); return NULL; }
    /* default: white-on-black */
    for (int i = 0; i < w * h; i++) {
        buf->cells[i].ch   = ' ';
        buf->cells[i].attr = 0x07; /* white fg, black bg */
    }
    buf->cursor_x = 0;
    buf->cursor_y = 0;
    buf->cursor_visible = 1;
    return buf;
}

void rosette_console_destroy(ConsoleBuffer *buf)
{
    if (!buf) return;
    free(buf->cells);
    free(buf);
}

/* ----------------------------------------------------------------- */
/* Thread-safe accessors called from the background (game) thread     */
/* ----------------------------------------------------------------- */

void rosette_console_set_cell(int x, int y, unsigned short ch,
                              unsigned short attr)
{
    if (!rosette_console_buf) return;
    pthread_mutex_lock(&rosette_console_lock);
    if (x >= 0 && x < rosette_console_buf->width &&
        y >= 0 && y < rosette_console_buf->height) {
        int idx = y * rosette_console_buf->width + x;
        rosette_console_buf->cells[idx].ch   = ch;
        rosette_console_buf->cells[idx].attr = attr;
    }
    pthread_mutex_unlock(&rosette_console_lock);
}

void rosette_console_set_cursor(int x, int y)
{
    if (!rosette_console_buf) return;
    pthread_mutex_lock(&rosette_console_lock);
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x >= rosette_console_buf->width)  x = rosette_console_buf->width - 1;
    if (y >= rosette_console_buf->height) y = rosette_console_buf->height - 1;
    rosette_console_buf->cursor_x = x;
    rosette_console_buf->cursor_y = y;
    pthread_mutex_unlock(&rosette_console_lock);
}

void rosette_console_set_cursor_visible(int visible)
{
    if (!rosette_console_buf) return;
    pthread_mutex_lock(&rosette_console_lock);
    rosette_console_buf->cursor_visible = visible;
    pthread_mutex_unlock(&rosette_console_lock);
}

void rosette_console_clear(unsigned short attr)
{
    if (!rosette_console_buf) return;
    pthread_mutex_lock(&rosette_console_lock);
    int n = rosette_console_buf->width * rosette_console_buf->height;
    for (int i = 0; i < n; i++) {
        rosette_console_buf->cells[i].ch   = ' ';
        rosette_console_buf->cells[i].attr = attr;
    }
    rosette_console_buf->cursor_x = 0;
    rosette_console_buf->cursor_y = 0;
    pthread_mutex_unlock(&rosette_console_lock);
}

/* ----------------------------------------------------------------- */
/* Keyboard input queue (game thread polls, Cocoa Event thread pushes) */
/* ----------------------------------------------------------------- */

#define ROSETTE_KEY_BUF_SIZE 256
static int rosette_key_buffer[ROSETTE_KEY_BUF_SIZE];
static int rosette_key_head = 0;
static int rosette_key_tail = 0;
static pthread_mutex_t rosette_key_lock = PTHREAD_MUTEX_INITIALIZER;

void rosette_key_push(int key)
{
    pthread_mutex_lock(&rosette_key_lock);
    int next = (rosette_key_head + 1) % ROSETTE_KEY_BUF_SIZE;
    if (next != rosette_key_tail) {
        rosette_key_buffer[rosette_key_head] = key;
        rosette_key_head = next;
    }
    pthread_mutex_unlock(&rosette_key_lock);
}

int rosette_key_pop(void)
{
    pthread_mutex_lock(&rosette_key_lock);
    int key = -1;
    if (rosette_key_tail != rosette_key_head) {
        key = rosette_key_buffer[rosette_key_tail];
        rosette_key_tail = (rosette_key_tail + 1) % ROSETTE_KEY_BUF_SIZE;
    }
    pthread_mutex_unlock(&rosette_key_lock);
    return key;
}

int rosette_key_available(void)
{
    pthread_mutex_lock(&rosette_key_lock);
    int avail = (rosette_key_head != rosette_key_tail) ? 1 : 0;
    pthread_mutex_unlock(&rosette_key_lock);
    return avail;
}

/* ========================================================================= */
/* ConsoleView — NSView that renders the character grid                      */
/* ========================================================================= */

@interface ConsoleView : NSView {
    NSFont       *_font;
    NSSize        _cellSize;
    int           _gridWidth;
    int           _gridHeight;
}
- (instancetype)initWithWidth:(int)w height:(int)h;
@end

@implementation ConsoleView

- (instancetype)initWithWidth:(int)w height:(int)h
{
    self = [super initWithFrame:NSMakeRect(0, 0, 800, 600)];
    if (self) {
        _gridWidth  = w;
        _gridHeight = h;
        _font       = [NSFont fontWithName:@"Menlo" size:14.0];
        if (!_font) _font = [NSFont fontWithName:@"Monaco" size:14.0];
        if (!_font) _font = [NSFont userFixedPitchFontOfSize:14.0];
        NSDictionary *attrs = @{NSFontAttributeName: _font};
        NSSize charSize = [@"@" sizeWithAttributes:attrs];
        _cellSize.width  = ceil(charSize.width);
        _cellSize.height = ceil(charSize.height);
        /* Resize frame to fit the grid (2px padding each side — callers
         * provide the full canvas size including any borders/scoring). */
        NSSize gridSize = NSMakeSize(
            _cellSize.width  * (CGFloat)_gridWidth  + 4,
            _cellSize.height * (CGFloat)_gridHeight + 4);
        [self setFrameSize:gridSize];
        [self setWantsLayer:YES];
    }
    return self;
}

/* Top‑left origin to match console coordinates */
- (BOOL)isFlipped { return YES; }

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder  { return YES; }
- (BOOL)resignFirstResponder  { return YES; }

/* ---- Keyboard event capture ---- */
- (void)keyDown:(NSEvent *)event
{
    rosette_keyboard_handle_key_down(event, NULL, 0, rosette_key_push);
}

- (void)flagsChanged:(NSEvent *)event
{
    /* Ignore modifier-only events */
}

/* ---- Rendering (called by drawRect: via setNeedsDisplay:) ---- */
- (void)drawRect:(NSRect)dirtyRect
{
    if (!rosette_console_buf) return;

    pthread_mutex_lock(&rosette_console_lock);
    ConsoleBuffer *buf = rosette_console_buf;
    int w = buf->width;
    int h = buf->height;
    ConsoleCell *cells = buf->cells;
    int cx = buf->cursor_x;
    int cy = buf->cursor_y;
    int cv = buf->cursor_visible;
    pthread_mutex_unlock(&rosette_console_lock);

    CGFloat cellW = _cellSize.width;
    CGFloat cellH = _cellSize.height;
    CGFloat x0 = 2.0f;
    CGFloat y0 = 2.0f;

    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];

    /* Background fill (black) */
    [[NSColor blackColor] setFill];
    NSRectFill([self bounds]);

    for (int row = 0; row < h; row++) {
        CGFloat rowY = y0 + (CGFloat)row * cellH;
        for (int col = 0; col < w; col++) {
            CGFloat colX = x0 + (CGFloat)col * cellW;
            int idx = row * w + col;
            unsigned short ch   = cells[idx].ch;
            unsigned short attr = cells[idx].attr;

            int fg_idx, bg_idx;
            rosette_unpack_attr(attr, &fg_idx, &bg_idx);

            /* Background rect */
            NSRect bgRect = NSMakeRect(colX, rowY, cellW, cellH);
            CGFloat bgR = rosette_palette[bg_idx][0];
            CGFloat bgG = rosette_palette[bg_idx][1];
            CGFloat bgB = rosette_palette[bg_idx][2];
            [[NSColor colorWithDeviceRed:bgR green:bgG blue:bgB alpha:1.0f] setFill];
            NSRectFill(bgRect);

            /* Foreground character */
            CGFloat fgR = rosette_palette[fg_idx][0];
            CGFloat fgG = rosette_palette[fg_idx][1];
            CGFloat fgB = rosette_palette[fg_idx][2];
            NSColor *fgColor = [NSColor colorWithDeviceRed:fgR green:fgG blue:fgB alpha:1.0f];
            NSDictionary *attrs = @{
                NSFontAttributeName: _font,
                NSForegroundColorAttributeName: fgColor,
            };
            unichar bufC = (ch != 0) ? ch : ' ';
            NSString *s = [NSString stringWithCharacters:&bufC length:1];
            [s drawAtPoint:NSMakePoint(colX, rowY) withAttributes:attrs];
        }
    }

    /* Cursor block */
    if (cv && cx >= 0 && cx < w && cy >= 0 && cy < h) {
        NSRect cursorRect = NSMakeRect(
            x0 + (CGFloat)cx * cellW,
            y0 + (CGFloat)cy * cellH,
            cellW, cellH);
        [[NSColor whiteColor] setFill];
        NSRectFill(cursorRect);
    }

    [ctx restoreGraphicsState];
}

@end

/* ========================================================================= */
/* ConsoleWindowController — manages the NSWindow                           */
/* ========================================================================= */

/* Forward declarations for C++ helpers in cout_bridge.cpp */
extern void rosette_cout_redirect(void);
extern void rosette_cout_restore(void);

@interface ConsoleWindowController : NSWindowController <NSWindowDelegate> {
    ConsoleView *_consoleView;
    int _width;
    int _height;
    NSThread *_gameThread;
}
@property (readonly) ConsoleView *consoleView;
- (instancetype)initWithWidth:(int)w height:(int)h;
- (void)startGame:(void (*)(void *))func arg:(void *)arg;
@end

@implementation ConsoleWindowController

@synthesize consoleView = _consoleView;

- (instancetype)initWithWidth:(int)w height:(int)h
{
    _width  = w;
    _height = h;
    _consoleView = [[ConsoleView alloc] initWithWidth:w height:h];
    NSRect viewFrame = [_consoleView frame];

    NSUInteger style = NSWindowStyleMaskTitled
                     | NSWindowStyleMaskClosable
                     | NSWindowStyleMaskMiniaturizable;
    NSWindow *win = [[NSWindow alloc]
        initWithContentRect:viewFrame
                  styleMask:style
                    backing:NSBackingStoreBuffered
                      defer:NO];
    [win setContentView:_consoleView];
    [win setTitle:@"Rosette — Console Window"];
    [win makeFirstResponder:_consoleView];
    [win center];
    [win setAcceptsMouseMovedEvents:NO];
    [win setReleasedWhenClosed:NO];

    self = [super initWithWindow:win];
    if (self) {
        [win setDelegate:self];
        _gameThread = nil;
    }
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
    /* Forcefully exit when window is closed */
    [NSApp terminate:nil];
}

- (void)startGame:(void (*)(void *))func arg:(void *)arg
{
    _gameThread = [[NSThread alloc] initWithBlock:^{
        rosette_cout_redirect();
        if (func) func(arg);
        rosette_cout_restore();
    }];
    [_gameThread start];
}

/* Periodic redraw via a timer */
- (void)scheduleRedraw
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 / 30.0  /* 30 fps */
                                             target:self
                                           selector:@selector(redrawTimer:)
                                           userInfo:nil
                                            repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)redrawTimer:(NSTimer *)timer
{
    [_consoleView setNeedsDisplay:YES];
}

@end

/* ========================================================================= */
/* Application delegate that kicks everything off                            */
/* ========================================================================= */

@interface RosetteAppDelegate : NSObject <NSApplicationDelegate> {
    ConsoleWindowController *_controller;
    void (*_threadFunc)(void *);
    void *_threadArg;
    int _width;
    int _height;
}
- (instancetype)initWithWidth:(int)w height:(int)h
                    threadFunc:(void (*)(void *))func arg:(void *)arg;
@end

@implementation RosetteAppDelegate

- (instancetype)initWithWidth:(int)w height:(int)h
                    threadFunc:(void (*)(void *))func arg:(void *)arg
{
    self = [super init];
    if (self) {
        _width  = w;
        _height = h;
        _threadFunc = func;
        _threadArg  = arg;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _controller = [[ConsoleWindowController alloc]
                   initWithWidth:_width height:_height];
    [_controller showWindow:nil];
    [[_controller window] makeKeyAndOrderFront:nil];
    [[_controller window] makeFirstResponder:[_controller consoleView]];
    [_controller scheduleRedraw];
    [_controller startGame:_threadFunc arg:_threadArg];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end

/* ========================================================================= */
/* Public C-linkage entry points                                             */
/* ========================================================================= */

/*
 * Start the Cocoa app and create a console window.
 * The thread function runs on a background thread once the window is live.
 * Returns only when the window is closed (call from main()).
 */
void rosette_window_run(int width, int height,
                        void (*thread_func)(void *), void *arg)
{
    rosette_console_buf = rosette_console_init(width, height);
    if (!rosette_console_buf) return;

    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        RosetteAppDelegate *delegate =
            [[RosetteAppDelegate alloc] initWithWidth:width
                                               height:height
                                           threadFunc:thread_func
                                                  arg:arg];
        [app setDelegate:delegate];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];
        [app run];
    }

    rosette_console_destroy(rosette_console_buf);
    rosette_console_buf = NULL;
}

/*
 * Replacements for the Win32 console functions that draw into the
 * Cocoa window instead of emitting ANSI escape codes.  These are
 * called from the C shim layer (include/shims/win32/windows.h).
 *
 * HANDLE functions (stubs that route to the console buffer):
 */

#include <stdint.h>

/* Unique handle values so the shim can recognise our handles */
#define ROSETTE_CONSOLE_HANDLE_OUT ((void *)(intptr_t)0xB001)
#define ROSETTE_CONSOLE_HANDLE_IN  ((void *)(intptr_t)0xB002)
#define ROSETTE_CONSOLE_HANDLE_ERR ((void *)(intptr_t)0xB003)

void *rosette_get_std_handle(unsigned long nStdHandle)
{
    switch (nStdHandle) {
        case 0xFFFFFFF6: /* STD_INPUT_HANDLE  = (DWORD)-10 */
            return ROSETTE_CONSOLE_HANDLE_IN;
        case 0xFFFFFFF5: /* STD_OUTPUT_HANDLE = (DWORD)-11 */
            return ROSETTE_CONSOLE_HANDLE_OUT;
        case 0xFFFFFFF4: /* STD_ERROR_HANDLE  = (DWORD)-12 */
            return ROSETTE_CONSOLE_HANDLE_ERR;
        default:
            return ROSETTE_CONSOLE_HANDLE_OUT;
    }
}

/*
 * Print a string at the current cursor position using the most recent
 * attribute.  Called from operator<< overloading / putchar routing.
 */
static unsigned short rosette_current_attr = 0x07;

void rosette_write_string(const char *str, int len)
{
    if (!rosette_console_buf || !str) return;
    int x, y;
    pthread_mutex_lock(&rosette_console_lock);
    x = rosette_console_buf->cursor_x;
    y = rosette_console_buf->cursor_y;
    pthread_mutex_unlock(&rosette_console_lock);

    for (int i = 0; i < len; i++) {
        unsigned char c = (unsigned char)str[i];
        if (c == '\n') {
            x = 0;
            y++;
        } else {
            rosette_console_set_cell(x, y, c, rosette_current_attr);
            x++;
        }
        if (x >= rosette_console_buf->width) {
            x = 0;
            y++;
        }
        if (y >= rosette_console_buf->height) {
            /* Scroll by shifting rows up */
            pthread_mutex_lock(&rosette_console_lock);
            int w = rosette_console_buf->width;
            int h = rosette_console_buf->height;
            memmove(rosette_console_buf->cells,
                    rosette_console_buf->cells + w,
                    (size_t)((h - 1) * w) * sizeof(ConsoleCell));
            for (int j = 0; j < w; j++) {
                rosette_console_buf->cells[(h - 1) * w + j].ch   = ' ';
                rosette_console_buf->cells[(h - 1) * w + j].attr = 0x07;
            }
            y = h - 1;
            pthread_mutex_unlock(&rosette_console_lock);
        }
    }
    rosette_console_set_cursor(x, y);
}

void rosette_set_console_text_attribute(void *hConsole,
                                        unsigned short wAttributes)
{
    (void)hConsole;
    rosette_current_attr = wAttributes;
}

void rosette_set_console_cursor_position(void *hConsole, int x, int y)
{
    (void)hConsole;
    rosette_console_set_cursor(x, y);
}

void rosette_set_console_cursor_info(void *hConsole,
                                     void *lpConsoleCursorInfo)
{
    (void)hConsole;
    if (!lpConsoleCursorInfo) return;
    /* lpConsoleCursorInfo is CONSOLE_CURSOR_INFO { DWORD dwSize; BOOL bVisible; } */
    int visible = ((unsigned int *)lpConsoleCursorInfo)[1] != 0;
    rosette_console_set_cursor_visible(visible);
}

void rosette_console_clear_screen(void)
{
    rosette_console_clear(rosette_current_attr);
}

/*
  Key event replacements for kbhit / getch consumed from the Cocoa
  event queue.
 */
int rosette_kbhit(void)
{
    return rosette_key_available();
}

int rosette_getch(void)
{
    /* Block until a key arrives */
    int key;
    while ((key = rosette_key_pop()) < 0) {
        usleep(1000); /* 1 ms */
    }
    return key;
}
