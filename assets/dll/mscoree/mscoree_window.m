#import <Cocoa/Cocoa.h>

#include <stdlib.h>
#include <string.h>

static NSString *rosette_env_string(const char *name, NSString *fallback)
{
    const char *value = getenv(name);
    if (!value || value[0] == '\0') return fallback;
    return [NSString stringWithUTF8String:value] ?: fallback;
}

static NSTextField *rosette_label(NSString *text, NSRect frame, CGFloat size, BOOL bold)
{
    NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
    [field setStringValue:text ?: @""];
    [field setEditable:NO];
    [field setSelectable:YES];
    [field setBordered:NO];
    [field setDrawsBackground:NO];
    [field setFont:bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
    [field setTextColor:[NSColor labelColor]];
    return field;
}

static unsigned int rosette_autoclose_delay_ms(void)
{
    const char *value = getenv("ROSETTE_MANAGED_WINDOW_AUTOCLOSE_MS");
    if (!value || value[0] == '\0') return 0;
    char *end = NULL;
    unsigned long parsed = strtoul(value, &end, 10);
    if (end == value || parsed > 60000UL) return 0;
    return (unsigned int)parsed;
}

int rosette_mscoree_show_managed_window(void)
{
    const char *enabled = getenv("ROSETTE_MANAGED_GUI");
    if (!enabled || strcmp(enabled, "1") != 0) return 0;

    @autoreleasepool {
        NSString *exePath = rosette_env_string("ROSETTE_EXE_PATH", @"Managed .NET executable");
        NSString *tracePath = rosette_env_string("ROSETTE_TRACE_PATH", @"");
        NSString *exeName = [exePath lastPathComponent];
        if (exeName.length == 0) exeName = @"Managed .NET executable";

        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        NSRect frame = NSMakeRect(0, 0, 820, 560);
        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:(NSWindowStyleMaskTitled |
                                                                  NSWindowStyleMaskClosable |
                                                                  NSWindowStyleMaskMiniaturizable |
                                                                  NSWindowStyleMaskResizable)
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window setTitle:[NSString stringWithFormat:@"Rosette - %@", exeName]];
        [window setReleasedWhenClosed:NO];
        [window center];

        NSView *content = [window contentView];
        [content setWantsLayer:YES];
        [[content layer] setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];

        NSTextField *title = rosette_label(exeName, NSMakeRect(24, 514, 760, 26), 20.0, YES);
        [title setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
        [content addSubview:title];

        NSTextField *status = rosette_label(
            @"Managed WinForms entry reached through mscoree._CorExeMain. CLR execution is stubbed; Rosette opened this native window so GUI intake is visible.",
            NSMakeRect(24, 488, 760, 20),
            12.0,
            NO);
        [status setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
        [content addSubview:status];

        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(24, 58, 772, 412)];
        [scroll setBorderType:NSBezelBorder];
        [scroll setHasVerticalScroller:YES];
        [scroll setHasHorizontalScroller:NO];
        [scroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

        NSTextView *editor = [[NSTextView alloc] initWithFrame:[[scroll contentView] bounds]];
        [editor setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [editor setEditable:YES];
        [editor setRichText:NO];
        [editor setFont:[NSFont monospacedSystemFontOfSize:14.0 weight:NSFontWeightRegular]];
        [editor setString:@""];
        [scroll setDocumentView:editor];
        [content addSubview:scroll];

        NSString *traceText = tracePath.length > 0
            ? [NSString stringWithFormat:@"trace: %@", tracePath]
            : @"trace: unavailable";
        NSTextField *trace = rosette_label(traceText, NSMakeRect(24, 24, 772, 20), 12.0, NO);
        [trace setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
        [content addSubview:trace];

        unsigned int autoclose = rosette_autoclose_delay_ms();
        NSDate *deadline = autoclose > 0
            ? [NSDate dateWithTimeIntervalSinceNow:((NSTimeInterval)autoclose / 1000.0)]
            : nil;

        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:editor];
        [app activateIgnoringOtherApps:YES];

        while ([window isVisible]) {
            if (deadline && [[NSDate date] compare:deadline] != NSOrderedAscending) {
                [window close];
                break;
            }

            @autoreleasepool {
                NSEvent *event = [app nextEventMatchingMask:NSEventMaskAny
                                                  untilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]
                                                     inMode:NSDefaultRunLoopMode
                                                    dequeue:YES];
                if (event) {
                    [app sendEvent:event];
                }
                [app updateWindows];
            }
        }
    }

    return 0;
}
