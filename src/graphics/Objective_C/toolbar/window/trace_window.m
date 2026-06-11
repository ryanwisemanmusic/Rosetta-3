#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

#include <stdlib.h>

@interface RosetteTraceWindowController : NSWindowController <NSWindowDelegate>
@property(nonatomic, strong) NSTextView *textView;
@property(nonatomic, strong) NSTextField *pathLabel;
@property(nonatomic, strong) NSTimer *refreshTimer;
@property(nonatomic, copy) NSString *tracePath;
- (instancetype)initWithTracePath:(NSString *)path;
- (void)setTracePathAndRefresh:(NSString *)path;
- (void)presentTraceWindow;
@end

static __strong RosetteTraceWindowController *g_rosette_trace_controller = nil;
static __strong NSString *g_rosette_trace_path = nil;

static NSString *rosette_trace_string_from_c(const char *path)
{
    if (!path || path[0] == '\0') return nil;
    return [NSString stringWithUTF8String:path];
}

static NSString *rosette_trace_default_path(void)
{
    NSString *tracePath = rosette_trace_string_from_c(getenv("ROSETTE_TRACE_PATH"));
    if (tracePath.length > 0) return tracePath;

    NSString *exePath = rosette_trace_string_from_c(getenv("ROSETTE_EXE_PATH"));
    if (exePath.length == 0) return nil;
    return [exePath stringByAppendingString:@".trace.log"];
}

static void rosette_trace_on_main(dispatch_block_t block)
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static RosetteTraceWindowController *rosette_trace_controller(void)
{
    if (!g_rosette_trace_controller) {
        NSString *path = g_rosette_trace_path ?: rosette_trace_default_path();
        g_rosette_trace_controller = [[RosetteTraceWindowController alloc] initWithTracePath:path];
    }
    return g_rosette_trace_controller;
}

@implementation RosetteTraceWindowController

- (instancetype)initWithTracePath:(NSString *)path
{
    NSRect frame = NSMakeRect(0, 0, 920, 640);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:(NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable |
                                                              NSWindowStyleMaskMiniaturizable |
                                                              NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window setTitle:@"Rosette - Trace Window"];
    [window setReleasedWhenClosed:NO];
    [window center];

    self = [super initWithWindow:window];
    if (!self) return nil;

    _tracePath = [path copy];
    [window setDelegate:self];

    NSView *content = [window contentView];
    [content setWantsLayer:YES];
    [[content layer] setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];

    CGFloat toolbarHeight = 44.0;
    NSView *toolbar = [[NSView alloc] initWithFrame:NSMakeRect(0, frame.size.height - toolbarHeight, frame.size.width, toolbarHeight)];
    [toolbar setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
    [content addSubview:toolbar];

    _pathLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(14, 12, frame.size.width - 220, 20)];
    [_pathLabel setEditable:NO];
    [_pathLabel setSelectable:YES];
    [_pathLabel setBordered:NO];
    [_pathLabel setDrawsBackground:NO];
    [_pathLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [_pathLabel setFont:[NSFont systemFontOfSize:12.0]];
    [_pathLabel setTextColor:[NSColor secondaryLabelColor]];
    [_pathLabel setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
    [toolbar addSubview:_pathLabel];

    NSButton *refreshButton = [NSButton buttonWithTitle:@"Refresh" target:self action:@selector(refreshTrace:)];
    [refreshButton setFrame:NSMakeRect(frame.size.width - 190, 8, 82, 28)];
    [refreshButton setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
    [toolbar addSubview:refreshButton];

    NSButton *openButton = [NSButton buttonWithTitle:@"Open..." target:self action:@selector(openTraceFile:)];
    [openButton setFrame:NSMakeRect(frame.size.width - 100, 8, 86, 28)];
    [openButton setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
    [toolbar addSubview:openButton];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - toolbarHeight)];
    [scroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:YES];
    [scroll setBorderType:NSNoBorder];

    _textView = [[NSTextView alloc] initWithFrame:[[scroll contentView] bounds]];
    [_textView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [_textView setEditable:NO];
    [_textView setSelectable:YES];
    [_textView setRichText:NO];
    [_textView setHorizontallyResizable:YES];
    [_textView setVerticallyResizable:YES];
    [_textView setTextColor:[NSColor labelColor]];
    [_textView setBackgroundColor:[NSColor textBackgroundColor]];
    [_textView setFont:[NSFont monospacedSystemFontOfSize:12.0 weight:NSFontWeightRegular]];
    [_textView setTextContainerInset:NSMakeSize(12.0, 12.0)];
    [[_textView textContainer] setWidthTracksTextView:NO];
    [[_textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [scroll setDocumentView:_textView];
    [content addSubview:scroll];

    [self refreshTrace:nil];
    return self;
}

- (void)setTracePathAndRefresh:(NSString *)path
{
    if (path.length > 0) {
        self.tracePath = path;
    }
    [self refreshTrace:nil];
}

- (void)presentTraceWindow
{
    if (self.tracePath.length == 0) {
        NSString *defaultPath = rosette_trace_default_path();
        if (defaultPath.length > 0) {
            self.tracePath = defaultPath;
        }
    }

    if (self.tracePath.length == 0) {
        [self openTraceFile:nil];
        return;
    }

    [self showWindow:nil];
    [[self window] makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [self refreshTrace:nil];
    [self startRefreshTimer];
}

- (void)startRefreshTimer
{
    if (self.refreshTimer) return;
    self.refreshTimer = [NSTimer timerWithTimeInterval:0.75
                                                target:self
                                              selector:@selector(refreshTrace:)
                                              userInfo:nil
                                               repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)windowWillClose:(NSNotification *)notification
{
    (void)notification;
    [self stopRefreshTimer];
}

- (void)openTraceFile:(id)sender
{
    (void)sender;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        NSString *path = [[panel URL] path];
        if (path.length == 0) return;
        [self setTracePathAndRefresh:path];
        [self presentTraceWindow];
    }];
}

- (void)refreshTrace:(id)sender
{
    (void)sender;
    NSString *path = self.tracePath;
    NSString *title = @"Rosette - Trace Window";
    NSString *label = @"No trace selected. Use Open... to choose a trace log.";
    NSString *text = label;

    if (path.length > 0) {
        title = [NSString stringWithFormat:@"Trace - %@", [path lastPathComponent]];
        label = path;

        NSError *error = nil;
        NSStringEncoding encoding = NSUTF8StringEncoding;
        text = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
        if (!text) {
            NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
            if (data.length > 0) {
                text = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
            }
        }
        if (!text) {
            text = [NSString stringWithFormat:@"Trace file is not available yet.\n\nExpected:\n%@",
                                              path];
        }
    }

    [[self window] setTitle:title];
    [self.pathLabel setStringValue:label];
    if (![[self.textView string] isEqualToString:text]) {
        [self.textView setString:text ?: @""];
        [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];
    }
}

@end

void rosette_trace_window_set_path(const char *path)
{
    NSString *tracePath = rosette_trace_string_from_c(path);
    rosette_trace_on_main(^{
        g_rosette_trace_path = [tracePath copy];
        if (g_rosette_trace_controller) {
            [g_rosette_trace_controller setTracePathAndRefresh:g_rosette_trace_path];
        }
    });
}

void rosette_trace_window_open(void)
{
    rosette_trace_on_main(^{
        RosetteTraceWindowController *controller = rosette_trace_controller();
        [controller presentTraceWindow];
    });
}

void rosette_trace_window_open_path(const char *path)
{
    NSString *tracePath = rosette_trace_string_from_c(path);
    rosette_trace_on_main(^{
        g_rosette_trace_path = [tracePath copy];
        RosetteTraceWindowController *controller = rosette_trace_controller();
        [controller setTracePathAndRefresh:g_rosette_trace_path];
        [controller presentTraceWindow];
    });
}
