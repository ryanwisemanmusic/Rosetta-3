/* extern_window.m */
#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#include "../common/keyboard/rosette_keyboard.h"
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <game/debug_runtime.h>
#import "../fb-logger/fb_logger.h"

#include "rosette_layout.h"

extern unsigned int rosette_gfx_get_width(void);
extern unsigned int rosette_gfx_get_height(void);
extern unsigned int rosette_gfx_get_block(unsigned int x, unsigned int y);
extern void         rosette_gfx_init(unsigned int w, unsigned int h);
extern void         rosette_gfx_deinit(void);
extern unsigned int rosette_gfx_scene_get_canvas_width(void);
extern unsigned int rosette_gfx_scene_get_canvas_height(void);
extern unsigned int rosette_gfx_scene_rect_count(void);
extern unsigned int rosette_gfx_scene_text_count(void);
extern void         rosette_gfx_scene_clear(void);
typedef struct {
    int x;
    int y;
    int width;
    int height;
    unsigned int color;
} RosetteSceneRect;

typedef struct {
    int x;
    int y;
    unsigned int fg_color;
    unsigned int bg_color;
    unsigned int len;
    unsigned char bytes[96];
} RosetteSceneText;

extern bool         rosette_gfx_scene_get_rect(unsigned int index, RosetteSceneRect *out_rect);
extern bool         rosette_gfx_scene_get_text(unsigned int index, RosetteSceneText *out_text);

typedef struct {
    unsigned short  ch;
    unsigned short  attr;
} ConsoleCell;

typedef struct {
    int             width;
    int             height;
    ConsoleCell    *cells;
    int             cursor_x;
    int             cursor_y;
    int             cursor_visible;
} ConsoleBuffer;

static ConsoleBuffer *g_buf = NULL;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

#define ROSETTE_SCENE_MAX_RECTS 256
#define ROSETTE_SCENE_MAX_TEXTS 96
static unsigned int g_scene_canvas_width = 0;
static unsigned int g_scene_canvas_height = 0;
static RosetteSceneRect g_scene_rects[ROSETTE_SCENE_MAX_RECTS];
static RosetteSceneText g_scene_texts[ROSETTE_SCENE_MAX_TEXTS];
static unsigned int g_scene_rect_count = 0;
static unsigned int g_scene_text_count = 0;

static const CGFloat g_palette[16][4] = {
    { 0.00f, 0.00f, 0.00f, 1.0f },   /* Black */
    { 0.00f, 0.00f, 0.67f, 1.0f },   /* Dark Blue */
    { 0.00f, 0.67f, 0.00f, 1.0f },   /* Dark Green */
    { 0.00f, 0.67f, 0.67f, 1.0f },   /* Dark Cyan */
    { 0.67f, 0.00f, 0.00f, 1.0f },   /* Dark Red */
    { 0.67f, 0.00f, 0.67f, 1.0f },   /* Dark Magenta */
    { 0.67f, 0.67f, 0.00f, 1.0f },   /* Dark Yellow */
    { 0.67f, 0.67f, 0.67f, 1.0f },   /* Gray */
    { 0.33f, 0.33f, 0.33f, 1.0f },   /* Dark Gray */
    { 0.33f, 0.33f, 1.00f, 1.0f },   /* Blue */
    { 0.33f, 1.00f, 0.33f, 1.0f },   /* Green */
    { 0.33f, 1.00f, 1.00f, 1.0f },   /* Cyan */
    { 1.00f, 0.33f, 0.33f, 1.0f },   /* Red */
    { 1.00f, 0.33f, 1.00f, 1.0f },   /* Magenta */
    { 1.00f, 1.00f, 0.33f, 1.0f },   /* Yellow */
    { 1.00f, 1.00f, 1.00f, 1.0f },   /* White */
};

#define KEY_BUF_SIZE 256
static int g_key_buffer[KEY_BUF_SIZE];
static int g_key_head = 0;
static int g_key_tail = 0;
static pthread_mutex_t g_key_lock = PTHREAD_MUTEX_INITIALIZER;

static void key_push(int key)
{
    pthread_mutex_lock(&g_key_lock);
    int next = (g_key_head + 1) % KEY_BUF_SIZE;
    if (next != g_key_tail) {
        g_key_buffer[g_key_head] = key;
        g_key_head = next;
    }
    pthread_mutex_unlock(&g_key_lock);
}

static int key_pop(void)
{
    pthread_mutex_lock(&g_key_lock);
    int key = -1;
    if (g_key_tail != g_key_head) {
        key = g_key_buffer[g_key_tail];
        g_key_tail = (g_key_tail + 1) % KEY_BUF_SIZE;
    }
    pthread_mutex_unlock(&g_key_lock);
    return key;
}

static void rosette_append_graphics_log(NSString *text)
{
    if (!text) return;
    const char *path = rosette_debug_log_path();
    if (!path || path[0] == '\0') return;
    FILE *fp = fopen(path, "a");
    if (!fp) return;
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (data && [data length] > 0) {
        fwrite([data bytes], 1, [data length], fp);
    }
    fclose(fp);
}

static void rosette_dump_first_frame(ConsoleBuffer *buf,
                                      unsigned int gfxW,
                                      unsigned int gfxH,
                                      unsigned int sceneRectCount,
                                      unsigned int sceneTextCount,
                                      CGFloat gridPixelX0,
                                      CGFloat gridPixelY0,
                                      CGFloat gridPixelW,
                                      CGFloat gridPixelH,
                                      CGFloat textPanelLeft,
                                      CGFloat textPanelTop)
{
    static int dumped = 0;
    if (!rosette_debug_graphics_enabled()) return;
    if (rosette_debug_first_frame_dump_enabled() && dumped) return;
    dumped = 1;

    NSMutableString *out = [NSMutableString string];
    [out appendString:@"\n# Rosette graphics first-frame dump\n"];
    [out appendFormat:@"framebuffer=%ux%u scene_rects=%u scene_texts=%u\n",
                      gfxW, gfxH, sceneRectCount, sceneTextCount];
    [out appendFormat:@"grid_pixel_origin=(%.1f,%.1f) grid_pixel_size=(%.1f,%.1f) text_panel=(%.1f,%.1f)\n",
                      gridPixelX0, gridPixelY0, gridPixelW, gridPixelH, textPanelLeft, textPanelTop];
    [out appendFormat:@"console_grid=%dx%d cursor=(%d,%d)\n",
                      buf ? buf->width : 0,
                      buf ? buf->height : 0,
                      buf ? buf->cursor_x : 0,
                      buf ? buf->cursor_y : 0];

    if (sceneRectCount > 0) {
        [out appendString:@"scene_rects:\n"];
        for (unsigned int i = 0; i < sceneRectCount; i++) {
            RosetteSceneRect rect;
            if (!rosette_gfx_scene_get_rect(i, &rect)) continue;
            [out appendFormat:@"  [%u] x=%d y=%d w=%d h=%d color=0x%08X\n",
                              i, rect.x, rect.y, rect.width, rect.height, rect.color];
        }
    } else {
        [out appendString:@"scene_rects: none\n"];
    }

    if (sceneTextCount > 0) {
        [out appendString:@"scene_text:\n"];
        for (unsigned int i = 0; i < sceneTextCount; i++) {
            RosetteSceneText text;
            if (!rosette_gfx_scene_get_text(i, &text)) continue;
            NSString *s = [[NSString alloc] initWithBytes:text.bytes length:text.len encoding:NSUTF8StringEncoding];
            [out appendFormat:@"  [%u] x=%d y=%d fg=0x%08X bg=0x%08X text=\"%@\"\n",
                              i, text.x, text.y, text.fg_color, text.bg_color, s ? s : @""];
        }
    } else {
        [out appendString:@"scene_text: none\n"];
    }

    if (gfxW > 0 && gfxH > 0) {
        [out appendString:@"framebuffer_nonzero:\n"];
        for (unsigned int row = 0; row < gfxH; row++) {
            for (unsigned int col = 0; col < gfxW; col++) {
                unsigned int rgba = rosette_gfx_get_block(col, row);
                if (rgba != 0) {
                    [out appendFormat:@"  cell[%u,%u]=0x%08X\n", col, row, rgba];
                }
            }
        }
    } else {
        [out appendString:@"framebuffer_nonzero: none\n"];
    }

    if (buf && buf->cells) {
        [out appendString:@"console_nonspace:\n"];
        for (int row = 0; row < buf->height; row++) {
            for (int col = 0; col < buf->width; col++) {
                int idx = row * buf->width + col;
                unsigned short ch = buf->cells[idx].ch;
                if (ch != 0 && ch != ' ') {
                    [out appendFormat:@"  char[%d,%d]=U+%04X\n", col, row, ch];
                }
            }
        }
    }

    [out appendString:@"# end first-frame dump\n"];
    rosette_append_graphics_log(out);
}

@interface ExternConsoleView : NSView {
    NSFont       *_font;
    NSSize        _cellSize;
    CGFloat       _blockSize;
    CGFloat       _gridLeft;
    CGFloat       _gridTop;
    CGFloat       _textPanelLeft;
    CGFloat       _textPanelTop;
    int           _gridWidth;
    int           _gridHeight;
}
- (instancetype)initWithWidth:(int)w height:(int)h;
@end

@implementation ExternConsoleView

- (instancetype)initWithWidth:(int)w height:(int)h
{
    self = [super initWithFrame:NSMakeRect(0, 0, 800, 600)];
    if (self) {
        _gridWidth  = w;
        _gridHeight = h;

        _blockSize  = ROSETTE_LAYOUT_BLOCK_SIZE;
        _gridLeft   = ROSETTE_LAYOUT_GRID_LEFT;
        _gridTop    = ROSETTE_LAYOUT_GRID_TOP;

        _font = [NSFont fontWithName:@"Menlo" size:14.0];
        if (!_font) _font = [NSFont fontWithName:@"Monaco" size:14.0];
        if (!_font) _font = [NSFont userFixedPitchFontOfSize:14.0];
        NSDictionary *attrs = @{NSFontAttributeName: _font};
        NSSize charSize = [@"@" sizeWithAttributes:attrs];
        _cellSize.width  = ceil(charSize.width);
        _cellSize.height = ceil(charSize.height);

        unsigned int gfxW = rosette_gfx_get_width();
        unsigned int gfxH = rosette_gfx_get_height();
        unsigned int sceneW = rosette_gfx_scene_get_canvas_width();
        unsigned int sceneH = rosette_gfx_scene_get_canvas_height();
        if (gfxW > 0 && gfxH > 0) {
            CGFloat gap = ROSETTE_LAYOUT_TEXT_PANEL_GAP;
            _textPanelLeft = _gridLeft + (CGFloat)gfxW * _blockSize + gap;
        } else {
            _textPanelLeft = _gridLeft + 16.0f;
        }
        _textPanelTop = _gridTop;

        CGFloat textPanelW = ROSETTE_LAYOUT_TEXT_PANEL_MIN_WIDTH;
        CGFloat totalW = _gridLeft + (CGFloat)gfxW * _blockSize + ROSETTE_LAYOUT_TEXT_PANEL_GAP + textPanelW + ROSETTE_LAYOUT_CANVAS_MARGIN;
        CGFloat totalH = ROSETTE_LAYOUT_CANVAS_MARGIN + (CGFloat)gfxH * _blockSize + ROSETTE_LAYOUT_CANVAS_MARGIN;

        CGFloat textH = _cellSize.height * (CGFloat)h + _gridTop;
        if (textH > totalH) totalH = textH;

        if (gfxW == 0 || gfxH == 0) {
            totalW = _cellSize.width  * (CGFloat)_gridWidth  + _gridLeft * 2;
            totalH = _cellSize.height * (CGFloat)_gridHeight + _gridTop  * 2;
        }
        if (sceneW > 0 && sceneH > 0) {
            totalW = (CGFloat)sceneW;
            totalH = (CGFloat)sceneH;
        }

        [self setFrameSize:NSMakeSize(totalW, totalH)];
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
    rosette_keyboard_handle_key_down(event, NULL, 0, key_push);
}

- (void)flagsChanged:(NSEvent *)event { }

- (void)drawRect:(NSRect)dirtyRect
{
    if (!g_buf) return;

    ConsoleCell *cells_copy = NULL;
    int cell_count = 0;
    pthread_mutex_lock(&g_lock);
    ConsoleBuffer *buf = g_buf;
    int w = buf->width;
    int h = buf->height;
    int cx = buf->cursor_x;
    int cy = buf->cursor_y;
    int cv = buf->cursor_visible;
    unsigned int gfxW = rosette_gfx_get_width();
    unsigned int gfxH = rosette_gfx_get_height();
    unsigned int sceneRectCount = rosette_gfx_scene_rect_count();
    unsigned int sceneTextCount = rosette_gfx_scene_text_count();
    cell_count = w * h;
    cells_copy = malloc((size_t)cell_count * sizeof(ConsoleCell));
    if (cells_copy) {
        memcpy(cells_copy, buf->cells, (size_t)cell_count * sizeof(ConsoleCell));
    }
    pthread_mutex_unlock(&g_lock);
    if (!cells_copy) return;

    CGFloat cellW = _cellSize.width;
    CGFloat cellH = _cellSize.height;

    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];

    [[NSColor colorWithDeviceRed:0.10f green:0.10f blue:0.18f alpha:1.0f] setFill];
    NSRectFill([self bounds]);

    CGFloat gridPixelX0 = _gridLeft;
    CGFloat gridPixelY0 = _gridTop;
    CGFloat gridPixelW  = (CGFloat)gfxW * _blockSize;
    CGFloat gridPixelH  = (CGFloat)gfxH * _blockSize;

    rosette_dump_first_frame(buf, gfxW, gfxH, sceneRectCount, sceneTextCount,
                              gridPixelX0, gridPixelY0, gridPixelW, gridPixelH,
                              _textPanelLeft, _textPanelTop);

    if (gfxW > 0 && gfxH > 0) {
        NSRect gridBg = NSMakeRect(gridPixelX0, gridPixelY0, gridPixelW, gridPixelH);
        [[NSColor colorWithDeviceRed:0.06f green:0.06f blue:0.10f alpha:1.0f] setFill];
        NSRectFill(gridBg);

        for (unsigned int row = 0; row < gfxH; row++) {
            CGFloat rowY = gridPixelY0 + (CGFloat)row * _blockSize;
            for (unsigned int col = 0; col < gfxW; col++) {
                CGFloat colX = gridPixelX0 + (CGFloat)col * _blockSize;
                unsigned int rgba = rosette_gfx_get_block(col, row);
                if (rgba == 0) continue;

                CGFloat r = ((rgba >> 24) & 0xFF) / 255.0f;
                CGFloat g = ((rgba >> 16) & 0xFF) / 255.0f;
                CGFloat b = ((rgba >>  8) & 0xFF) / 255.0f;
                CGFloat a = ((rgba >>  0) & 0xFF) / 255.0f;
                if (a < 0.01f) continue;

                NSRect blockRect = NSMakeRect(colX + 1, rowY + 1,
                                              _blockSize - 2, _blockSize - 2);
                [[NSColor colorWithDeviceRed:r green:g blue:b alpha:a] setFill];
                NSRectFill(blockRect);

                [[NSColor colorWithDeviceRed:MIN(r + 0.2f, 1.0f)
                                       green:MIN(g + 0.2f, 1.0f)
                                        blue:MIN(b + 0.2f, 1.0f)
                                       alpha:a] setFill];
                NSRect smallRect = NSMakeRect(colX + 1, rowY + 1,
                                              _blockSize - 2, 3);
                NSRectFill(smallRect);
                smallRect = NSMakeRect(colX + 1, rowY + 1, 3, _blockSize - 2);
                NSRectFill(smallRect);
            }
        }
    }

    for (unsigned int i = 0; i < sceneRectCount; i++) {
        RosetteSceneRect rect;
        if (!rosette_gfx_scene_get_rect(i, &rect)) continue;
        unsigned int rgba = rect.color;
        CGFloat r = ((rgba >> 24) & 0xFF) / 255.0f;
        CGFloat g = ((rgba >> 16) & 0xFF) / 255.0f;
        CGFloat b = ((rgba >>  8) & 0xFF) / 255.0f;
        CGFloat a = ((rgba >>  0) & 0xFF) / 255.0f;
        [[NSColor colorWithDeviceRed:r green:g blue:b alpha:a] setFill];
        NSRectFill(NSMakeRect(rect.x, rect.y, rect.width, rect.height));
    }

    for (unsigned int i = 0; i < sceneTextCount; i++) {
        RosetteSceneText text;
        if (!rosette_gfx_scene_get_text(i, &text)) continue;
        if (text.len == 0) continue;

        CGFloat bgR = ((text.bg_color >> 24) & 0xFF) / 255.0f;
        CGFloat bgG = ((text.bg_color >> 16) & 0xFF) / 255.0f;
        CGFloat bgB = ((text.bg_color >>  8) & 0xFF) / 255.0f;
        CGFloat bgA = ((text.bg_color >>  0) & 0xFF) / 255.0f;
        if (bgA > 0.01f) {
            NSDictionary *measureAttrs = @{NSFontAttributeName: _font};
            NSString *measureStr = [[NSString alloc] initWithBytes:text.bytes length:text.len encoding:NSUTF8StringEncoding];
            NSSize textSize = [measureStr sizeWithAttributes:measureAttrs];
            [[NSColor colorWithDeviceRed:bgR green:bgG blue:bgB alpha:bgA] setFill];
            NSRectFill(NSMakeRect(text.x, text.y, ceil(textSize.width) + 4.0f, ceil(textSize.height) + 2.0f));
        }

        CGFloat fgR = ((text.fg_color >> 24) & 0xFF) / 255.0f;
        CGFloat fgG = ((text.fg_color >> 16) & 0xFF) / 255.0f;
        CGFloat fgB = ((text.fg_color >>  8) & 0xFF) / 255.0f;
        CGFloat fgA = ((text.fg_color >>  0) & 0xFF) / 255.0f;
        NSColor *fgColor = [NSColor colorWithDeviceRed:fgR green:fgG blue:fgB alpha:fgA];
        NSDictionary *attrs = @{
            NSFontAttributeName: _font,
            NSForegroundColorAttributeName: fgColor,
        };
        NSString *s = [[NSString alloc] initWithBytes:text.bytes length:text.len encoding:NSUTF8StringEncoding];
        if (!s) continue;
        [s drawAtPoint:NSMakePoint(text.x, text.y) withAttributes:attrs];
    }

    for (int row = 0; row < h; row++) {
        CGFloat rowY = 2.0f + (CGFloat)row * cellH;
        for (int col = 0; col < w; col++) {
            CGFloat colX = 2.0f + (CGFloat)col * cellW;

            if (gfxW > 0 && gfxH > 0 &&
                colX + cellW > gridPixelX0 && colX < gridPixelX0 + gridPixelW &&
                rowY + cellH > gridPixelY0 && rowY < gridPixelY0 + gridPixelH) {
                continue;
            }

            int idx = row * w + col;
            unsigned short ch   = cells_copy[idx].ch;
            unsigned short attr = cells_copy[idx].attr;

            int fg_idx = attr & 0x0F;
            int bg_idx = (attr >> 4) & 0x07;
            if (attr & 0x08) fg_idx |= 0x08;
            if (attr & 0x80) bg_idx |= 0x08;
            fg_idx &= 0x0F;
            bg_idx &= 0x0F;

            NSRect bgRect = NSMakeRect(colX, rowY, cellW, cellH);
            CGFloat bgR = g_palette[bg_idx][0] * 0.3f;
            CGFloat bgG = g_palette[bg_idx][1] * 0.3f;
            CGFloat bgB = g_palette[bg_idx][2] * 0.3f;
            [[NSColor colorWithDeviceRed:bgR green:bgG blue:bgB alpha:1.0f] setFill];
            NSRectFill(bgRect);

            CGFloat fgR = g_palette[fg_idx][0];
            CGFloat fgG = g_palette[fg_idx][1];
            CGFloat fgB = g_palette[fg_idx][2];
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

    if (cv && cx >= 0 && cx < w && cy >= 0 && cy < h) {
        CGFloat cursorX = 2.0f + (CGFloat)cx * cellW;
        CGFloat cursorY = 2.0f + (CGFloat)cy * cellH;
        BOOL inGrid = (gfxW > 0 && gfxH > 0 &&
            cursorX + cellW > gridPixelX0 && cursorX < gridPixelX0 + gridPixelW &&
            cursorY + cellH > gridPixelY0 && cursorY < gridPixelY0 + gridPixelH);
        if (!inGrid) {
            NSRect cursorRect = NSMakeRect(cursorX, cursorY, cellW, cellH);
            [[NSColor whiteColor] setFill];
            NSRectFill(cursorRect);
        }
    }

    [ctx restoreGraphicsState];
    rosette_fb_logger_capture_view(self);
    free(cells_copy);
}

@end

@interface ExternConsoleWindowController : NSWindowController <NSWindowDelegate> {
    ExternConsoleView *_consoleView;
}
@property (readonly) ExternConsoleView *consoleView;
- (instancetype)initWithWidth:(int)w height:(int)h;
@end

@implementation ExternConsoleWindowController

@synthesize consoleView = _consoleView;

- (instancetype)initWithWidth:(int)w height:(int)h
{
        _consoleView = [[ExternConsoleView alloc] initWithWidth:w height:h];
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
    [win setTitle:@"Rosette — CLI Window"];
    [win makeFirstResponder:_consoleView];
    [win center];
    [win setAcceptsMouseMovedEvents:NO];
    [win setReleasedWhenClosed:NO];

    self = [super initWithWindow:win];
    if (self) {
        [win setDelegate:self];
    }
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp terminate:nil];
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
    [_consoleView setNeedsDisplay:YES];
}

@end

@interface ExternWindowDelegate : NSObject <NSApplicationDelegate> {
    ExternConsoleWindowController *_controller;
    int _width;
    int _height;
    NSString *_title;
}
- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)title;
@end

@implementation ExternWindowDelegate

- (instancetype)initWithWidth:(int)w height:(int)h title:(const char *)title
{
    self = [super init];
    if (self) {
        _width  = w;
        _height = h;
        _title  = title ? [NSString stringWithUTF8String:title] : @"Rosette — CLI Window";
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _controller = [[ExternConsoleWindowController alloc]
                   initWithWidth:_width height:_height];
    if (_title) {
        [[_controller window] setTitle:_title];
    }
    [_controller showWindow:nil];
    [[_controller window] makeKeyAndOrderFront:nil];
    [[_controller window] makeFirstResponder:[_controller consoleView]];
    [_controller scheduleRedraw];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end

static ConsoleBuffer *buf_create(int w, int h)
{
    ConsoleBuffer *buf = calloc(1, sizeof(ConsoleBuffer));
    if (!buf) return NULL;
    buf->width  = w;
    buf->height = h;
    buf->cells  = calloc((size_t)(w * h), sizeof(ConsoleCell));
    if (!buf->cells) { free(buf); return NULL; }
    for (int i = 0; i < w * h; i++) {
        buf->cells[i].ch   = ' ';
        buf->cells[i].attr = 0x07;
    }
    buf->cursor_visible = 0;
    return buf;
}

static void buf_destroy(ConsoleBuffer *buf)
{
    if (!buf) return;
    free(buf->cells);
    free(buf);
}

static void buf_clear(void)
{
    if (!g_buf) return;
    pthread_mutex_lock(&g_lock);
    int n = g_buf->width * g_buf->height;
    for (int i = 0; i < n; i++) {
        g_buf->cells[i].ch   = ' ';
        g_buf->cells[i].attr = 0x07;
    }
    g_buf->cursor_x = 0;
    g_buf->cursor_y = 0;
    pthread_mutex_unlock(&g_lock);
}

static void buf_set_cell_locked(int x, int y, unsigned short ch)
{
    if (x >= 0 && x < g_buf->width && y >= 0 && y < g_buf->height) {
        int idx = y * g_buf->width + x;
        g_buf->cells[idx].ch   = ch;
        g_buf->cells[idx].attr = 0x07;
    }
}

static void buf_set_cell(int x, int y, unsigned short ch)
{
    if (!g_buf) return;
    pthread_mutex_lock(&g_lock);
    buf_set_cell_locked(x, y, ch);
    pthread_mutex_unlock(&g_lock);
}

static void buf_scroll_if_needed_locked(void)
{
    if (g_buf->cursor_y < g_buf->height) return;
    int w = g_buf->width;
    int h = g_buf->height;
    memmove(g_buf->cells,
            g_buf->cells + w,
            (size_t)((h - 1) * w) * sizeof(ConsoleCell));
    for (int i = 0; i < w; i++) {
        g_buf->cells[(h - 1) * w + i].ch   = ' ';
        g_buf->cells[(h - 1) * w + i].attr = 0x07;
    }
    g_buf->cursor_y = h - 1;
}

static void buf_write_byte_locked(unsigned char byte)
{
    if (byte == '\n') {
        g_buf->cursor_x = 0;
        g_buf->cursor_y++;
        buf_scroll_if_needed_locked();
        return;
    }

    buf_set_cell_locked(g_buf->cursor_x, g_buf->cursor_y, byte);
    g_buf->cursor_x++;
    if (g_buf->cursor_x >= g_buf->width) {
        g_buf->cursor_x = 0;
        g_buf->cursor_y++;
        buf_scroll_if_needed_locked();
    }
}

void rosette_windowed_run(int grid_w, int grid_h,
                           int block_w, int block_h,
                           const char *title,
                           void (*game_func)(void *), void *arg)
{
    g_buf = buf_create(grid_w > 0 ? grid_w : 80,
                       grid_h > 0 ? grid_h : 24);
    if (!g_buf) return;

    if (block_w > 0 && block_h > 0) {
        rosette_gfx_init((unsigned int)block_w, (unsigned int)block_h);
    } else {
        rosette_gfx_scene_clear();
    }

    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        ExternWindowDelegate *delegate =
            [[ExternWindowDelegate alloc] initWithWidth:g_buf->width
                                                  height:g_buf->height
                                                  title:title];
        [app setDelegate:delegate];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];

        [NSThread detachNewThreadWithBlock:^{
            if (game_func) game_func(arg);
        }];

        [app run];
    }

    buf_destroy(g_buf);
    g_buf = NULL;
    rosette_gfx_deinit();
}

int rosette_cli_get_key(void)
{
    return key_pop();
}

void rosette_cli_clear(void)
{
    buf_clear();
}

void rosette_cli_move_cursor(int x, int y)
{
    if (!g_buf) return;
    pthread_mutex_lock(&g_lock);
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x >= g_buf->width)  x = g_buf->width - 1;
    if (y >= g_buf->height) y = g_buf->height - 1;
    g_buf->cursor_x = x;
    g_buf->cursor_y = y;
    pthread_mutex_unlock(&g_lock);
}

void rosette_cli_write_byte(unsigned char byte)
{
    if (!g_buf) return;
    pthread_mutex_lock(&g_lock);
    buf_write_byte_locked(byte);
    pthread_mutex_unlock(&g_lock);
}

void rosette_cli_write_text(const char *text, int len)
{
    if (!text || len <= 0 || !g_buf) return;
    pthread_mutex_lock(&g_lock);
    for (int i = 0; i < len; i++) {
        buf_write_byte_locked((unsigned char)text[i]);
    }
    pthread_mutex_unlock(&g_lock);
}

void rosette_cli_init(void)
{

}

void rosette_gfx_scene_set_canvas_size(unsigned int width, unsigned int height)
{
    g_scene_canvas_width = width;
    g_scene_canvas_height = height;
}

bool rosette_gfx_scene_is_available(void)
{
    return true;
}

unsigned int rosette_gfx_scene_get_canvas_width(void)
{
    return g_scene_canvas_width;
}

unsigned int rosette_gfx_scene_get_canvas_height(void)
{
    return g_scene_canvas_height;
}

void rosette_gfx_scene_clear(void)
{
    g_scene_rect_count = 0;
    g_scene_text_count = 0;
}

void rosette_gfx_scene_fill_rect(int x, int y, int width, int height, unsigned int color)
{
    if (width <= 0 || height <= 0 || g_scene_rect_count >= ROSETTE_SCENE_MAX_RECTS) return;
    g_scene_rects[g_scene_rect_count].x = x;
    g_scene_rects[g_scene_rect_count].y = y;
    g_scene_rects[g_scene_rect_count].width = width;
    g_scene_rects[g_scene_rect_count].height = height;
    g_scene_rects[g_scene_rect_count].color = color;
    g_scene_rect_count++;
}

void rosette_gfx_scene_stroke_rect(int x, int y, int width, int height, int thickness, unsigned int color)
{
    if (thickness <= 0) return;
    rosette_gfx_scene_fill_rect(x, y, width, thickness, color);
    rosette_gfx_scene_fill_rect(x, y + height - thickness, width, thickness, color);
    rosette_gfx_scene_fill_rect(x, y, thickness, height, color);
    rosette_gfx_scene_fill_rect(x + width - thickness, y, thickness, height, color);
}

void rosette_gfx_scene_draw_text(int x, int y, unsigned int fg_color, unsigned int bg_color, const unsigned char *text_ptr, unsigned int len)
{
    if (!text_ptr || len == 0 || g_scene_text_count >= ROSETTE_SCENE_MAX_TEXTS) return;
    RosetteSceneText *text = &g_scene_texts[g_scene_text_count++];
    unsigned int copy_len = len > sizeof(text->bytes) ? (unsigned int)sizeof(text->bytes) : len;
    text->x = x;
    text->y = y;
    text->fg_color = fg_color;
    text->bg_color = bg_color;
    text->len = copy_len;
    memset(text->bytes, 0, sizeof(text->bytes));
    memcpy(text->bytes, text_ptr, copy_len);
}

unsigned int rosette_gfx_scene_rect_count(void)
{
    return g_scene_rect_count;
}

unsigned int rosette_gfx_scene_text_count(void)
{
    return g_scene_text_count;
}

bool rosette_gfx_scene_get_rect(unsigned int index, RosetteSceneRect *out_rect)
{
    if (!out_rect || index >= g_scene_rect_count) return false;
    *out_rect = g_scene_rects[index];
    return true;
}

bool rosette_gfx_scene_get_text(unsigned int index, RosetteSceneText *out_text)
{
    if (!out_text || index >= g_scene_text_count) return false;
    *out_text = g_scene_texts[index];
    return true;
}

void rosette_cli_deinit(void)
{

}
