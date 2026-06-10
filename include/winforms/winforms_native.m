#import <Cocoa/Cocoa.h>

static NSWindow *g_winforms_window = nil;

void *rosette_winforms_create_window(void)
{
    @autoreleasepool {
        if (g_winforms_window) {
            [g_winforms_window close];
            g_winforms_window = nil;
        }

        NSRect frame = NSMakeRect(0, 0, 800, 450);
        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:(NSWindowStyleMaskTitled |
                                                                  NSWindowStyleMaskClosable |
                                                                  NSWindowStyleMaskMiniaturizable |
                                                                  NSWindowStyleMaskResizable)
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window setTitle:@"Rosette - WinForms App"];
        [window setReleasedWhenClosed:NO];
        [window center];

        NSView *content = [window contentView];

        // Create a text view for the client area (like Notepad's edit control)
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:[content bounds]];
        [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setBorderType:NSNoBorder];

        NSTextView *textView = [[NSTextView alloc] initWithFrame:[[scrollView contentView] bounds]];
        [textView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [textView setEditable:YES];
        [textView setSelectable:YES];
        [textView setRichText:NO];
        [textView setFont:[NSFont fontWithName:@"Menlo" size:12.0]];
        [textView setString:@""];

        [scrollView setDocumentView:textView];
        [content addSubview:scrollView];

        g_winforms_window = window;
        return (__bridge void *)window;
    }
}

void rosette_winforms_set_title(void *window_ptr, const char *title)
{
    @autoreleasepool {
        NSWindow *window = (__bridge NSWindow *)window_ptr;
        NSString *nsTitle = [NSString stringWithUTF8String:title ?: ""];
        [window setTitle:nsTitle];
    }
}

void rosette_winforms_set_size(void *window_ptr, int width, int height)
{
    @autoreleasepool {
        NSWindow *window = (__bridge NSWindow *)window_ptr;
        NSRect frame = [window frame];
        frame.size.width = (CGFloat)width;
        frame.size.height = (CGFloat)height;
        [window setFrame:frame display:YES animate:NO];
    }
}

void rosette_winforms_show(void *window_ptr)
{
    @autoreleasepool {
        NSWindow *window = (__bridge NSWindow *)window_ptr;
        [window makeKeyAndOrderFront:nil];
    }
}

void rosette_run_native_event_loop(void)
{
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];

        while (g_winforms_window && [g_winforms_window isVisible]) {
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
}
