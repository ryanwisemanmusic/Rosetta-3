#import <Cocoa/Cocoa.h>

@interface RosetteAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSTextView *logView;
@end

@implementation RosetteAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [self buildMenuBar];
    [self buildWindow];
    [self appendLine:@"Rosette is ready."];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return NO;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    (void)sender;
    [self openExecutableAtPath:filename];
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames {
    (void)sender;
    for (NSString *path in filenames) {
        [self openExecutableAtPath:path];
    }
    [NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

- (void)buildWindow {
    NSRect frame = NSMakeRect(0, 0, 820, 520);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled |
                                                         NSWindowStyleMaskClosable |
                                                         NSWindowStyleMaskMiniaturizable |
                                                         NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"Rosette"];
    [self.window setDelegate:self];
    [self.window center];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:[[self.window contentView] bounds]];
    [scroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:NO];

    self.logView = [[NSTextView alloc] initWithFrame:[[self.window contentView] bounds]];
    [self.logView setEditable:NO];
    [self.logView setSelectable:YES];
    [self.logView setFont:[NSFont monospacedSystemFontOfSize:13.0 weight:NSFontWeightRegular]];
    [self.logView setTextColor:[NSColor labelColor]];
    [self.logView setBackgroundColor:[NSColor textBackgroundColor]];
    [self.logView setTypingAttributes:[self logTextAttributes]];
    [self.logView setTextContainerInset:NSMakeSize(12.0, 12.0)];
    [[self.logView textContainer] setWidthTracksTextView:YES];
    [scroll setDocumentView:self.logView];

    [[self.window contentView] addSubview:scroll];
    [self.window makeKeyAndOrderFront:nil];
}

- (void)buildMenuBar {
    NSMenu *menubar = [[NSMenu alloc] initWithTitle:@""];
    [NSApp setMainMenu:menubar];

    NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    [menubar addItem:appItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Rosette"];
    [appItem setSubmenu:appMenu];
    [appMenu addItemWithTitle:@"About Rosette" action:@selector(showAbout:) keyEquivalent:@""].target = self;
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit Rosette" action:@selector(terminate:) keyEquivalent:@"q"];

    NSMenuItem *fileItem = [[NSMenuItem alloc] initWithTitle:@"File" action:nil keyEquivalent:@""];
    [menubar addItem:fileItem];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    [fileItem setSubmenu:fileMenu];
    NSMenuItem *openItem = [fileMenu addItemWithTitle:@"Open Executable..." action:@selector(openExecutable:) keyEquivalent:@"o"];
    [openItem setTarget:self];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *installItem = [fileMenu addItemWithTitle:@"Install to Applications" action:@selector(installToApplications:) keyEquivalent:@""];
    [installItem setTarget:self];
    NSMenuItem *registerItem = [fileMenu addItemWithTitle:@"Register File Association" action:@selector(registerFileAssociation:) keyEquivalent:@""];
    [registerItem setTarget:self];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    [fileMenu addItemWithTitle:@"Close Window" action:@selector(performClose:) keyEquivalent:@"w"];

    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    [menubar addItem:editItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editItem setSubmenu:editMenu];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];

    NSMenuItem *viewItem = [[NSMenuItem alloc] initWithTitle:@"View" action:nil keyEquivalent:@""];
    [menubar addItem:viewItem];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    [viewItem setSubmenu:viewMenu];
    NSMenuItem *clearItem = [viewMenu addItemWithTitle:@"Clear Log" action:@selector(clearLog:) keyEquivalent:@"k"];
    [clearItem setTarget:self];

    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    [menubar addItem:windowItem];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowItem setSubmenu:windowMenu];
    [NSApp setWindowsMenu:windowMenu];
    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];

    NSMenuItem *helpItem = [[NSMenuItem alloc] initWithTitle:@"Help" action:nil keyEquivalent:@""];
    [menubar addItem:helpItem];
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpItem setSubmenu:helpMenu];
    NSMenuItem *helpAction = [helpMenu addItemWithTitle:@"Rosette Help" action:@selector(showHelp:) keyEquivalent:@"?"];
    [helpAction setTarget:self];
}

- (void)openExecutable:(id)sender {
    (void)sender;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowedFileTypes:@[ @"exe", @"EXE", @"com", @"COM" ]];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            [self openExecutableAtPath:[[panel URL] path]];
        }
    }];
}

- (void)openExecutableAtPath:(NSString *)path {
    if (path.length == 0) {
        return;
    }
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [self appendLine:[NSString stringWithFormat:@"Opening %@", path]];
    [self runHelperWithArguments:@[ @"--open", path ]];
}

- (void)installToApplications:(id)sender {
    (void)sender;
    [self appendLine:@"Installing Rosette to /Applications"];
    [self runHelperWithArguments:@[ @"--install", @"/Applications" ]];
}

- (void)registerFileAssociation:(id)sender {
    (void)sender;
    [self appendLine:@"Registering Rosette with LaunchServices"];
    [self runHelperWithArguments:@[ @"--register" ]];
}

- (void)clearLog:(id)sender {
    (void)sender;
    [self.logView setString:@""];
    [self.logView setTypingAttributes:[self logTextAttributes]];
}

- (void)showAbout:(id)sender {
    (void)sender;
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Rosette"];
    [alert setInformativeText:@"x86/x64/DOS translation shell for macOS."];
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)showHelp:(id)sender {
    (void)sender;
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Rosette Help"];
    [alert setInformativeText:@"Use File > Open Executable to inspect a Windows or DOS executable. Use the installer DMG to copy Rosette into an application folder and register file associations."];
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)runHelperWithArguments:(NSArray<NSString *> *)arguments {
    NSString *helper = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"rosette-cli"];
    if (helper.length == 0) {
        [self appendLine:@"error: bundled rosette-cli helper was not found"];
        return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        [task setExecutableURL:[NSURL fileURLWithPath:helper]];
        [task setArguments:arguments];

        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        [task setStandardError:pipe];

        NSError *error = nil;
        BOOL launched = [task launchAndReturnError:&error];
        if (!launched) {
            NSString *message = [NSString stringWithFormat:@"error: %@", [error localizedDescription]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self appendLine:message];
            });
            return;
        }

        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        [task waitUntilExit];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (output.length == 0) {
            output = [NSString stringWithFormat:@"helper exited with status %d", [task terminationStatus]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self appendLine:output];
        });
    });
}

- (void)appendLine:(NSString *)line {
    if (line.length == 0) {
        return;
    }
    NSString *withNewline = [line hasSuffix:@"\n"] ? line : [line stringByAppendingString:@"\n"];
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:withNewline attributes:[self logTextAttributes]];
    [[self.logView textStorage] appendAttributedString:attr];
    [self.logView scrollRangeToVisible:NSMakeRange([[self.logView string] length], 0)];
}

- (NSDictionary<NSAttributedStringKey, id> *)logTextAttributes {
    NSFont *font = self.logView.font ?: [NSFont monospacedSystemFontOfSize:13.0 weight:NSFontWeightRegular];
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor labelColor],
    };
}

@end

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;

    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        RosetteAppDelegate *delegate = [[RosetteAppDelegate alloc] init];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app setDelegate:delegate];
        [app run];
    }
    return 0;
}
