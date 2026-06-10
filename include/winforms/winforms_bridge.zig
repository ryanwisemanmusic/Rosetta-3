const std = @import("std");
const clr_executor = @import("../runtime/clr_executor.zig");

const Allocator = std.mem.Allocator;

pub const WinFormsError = error{
    NotSupported,
    OutOfMemory,
    InvalidHandle,
};

pub const ControlType = enum {
    None,
    Form,
    Button,
    TextBox,
    Label,
    Menu,
    MenuItem,
    RichTextBox,
    StatusBar,
    MainMenu,
};

pub const ControlState = struct {
    handle: u32,
    control_type: ControlType,
    text: []const u8,
    visible: bool = true,
    enabled: bool = true,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 800,
    height: i32 = 450,
    parent: ?u32 = null,
    children: std.ArrayListUnmanaged(u32),
    multiline: bool = false,
    read_only: bool = false,
    dock: i32 = 0,

    fn init(_: Allocator) ControlState {
        return ControlState{
            .handle = 0,
            .control_type = .None,
            .text = "",
            .children = std.ArrayListUnmanaged(u32).empty,
        };
    }
    fn deinit(self: *ControlState, allocator: Allocator) void {
        self.children.deinit(allocator);
    }
};

pub const WinFormsApp = struct {
    controls: std.AutoHashMapUnmanaged(u32, ControlState),
    next_handle: u32 = 1,
    main_form: ?u32 = null,
    is_running: bool = false,
    allocator: Allocator,

    pub fn init(allocator: Allocator) WinFormsApp {
        return WinFormsApp{
            .controls = std.AutoHashMapUnmanaged(u32, ControlState){},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *WinFormsApp) void {
        var iter = self.controls.iterator();
        while (iter.next()) |entry| entry.value_ptr.deinit(self.allocator);
        self.controls.deinit(self.allocator);
    }

    pub fn createControl(self: *WinFormsApp, control_type: ControlType, parent: ?u32) WinFormsError!u32 {
        const handle = self.next_handle;
        self.next_handle += 1;
        var control = ControlState.init(self.allocator);
        control.handle = handle;
        control.control_type = control_type;
        control.parent = parent;
        try self.controls.put(self.allocator, handle, control);
        if (parent) |ph| {
            if (self.controls.getPtr(ph)) |pc| try pc.children.append(self.allocator, handle);
        }
        return handle;
    }

    pub fn setControlText(self: *WinFormsApp, handle: u32, text: []const u8) WinFormsError!void {
        if (self.controls.getPtr(handle)) |c| c.text = text else return WinFormsError.InvalidHandle;
    }

    pub fn setControlPosition(self: *WinFormsApp, handle: u32, x: i32, y: i32) WinFormsError!void {
        if (self.controls.getPtr(handle)) |c| {
            c.x = x;
            c.y = y;
        } else return WinFormsError.InvalidHandle;
    }

    pub fn setControlSize(self: *WinFormsApp, handle: u32, width: i32, height: i32) WinFormsError!void {
        if (self.controls.getPtr(handle)) |c| {
            c.width = width;
            c.height = height;
        } else return WinFormsError.InvalidHandle;
    }

    pub fn showControl(self: *WinFormsApp, handle: u32) WinFormsError!void {
        if (self.controls.getPtr(handle)) |c| c.visible = true else return WinFormsError.InvalidHandle;
    }

    pub fn hideControl(self: *WinFormsApp, handle: u32) WinFormsError!void {
        if (self.controls.getPtr(handle)) |c| c.visible = false else return WinFormsError.InvalidHandle;
    }

    pub fn setMainForm(self: *WinFormsApp, handle: u32) WinFormsError!void {
        if (self.controls.contains(handle)) {
            self.main_form = handle;
        } else return WinFormsError.InvalidHandle;
    }

    pub fn run(self: *WinFormsApp) !void {
        self.is_running = true;
        if (self.main_form) |mf| {
            if (self.controls.get(mf)) |form| {
                std.debug.print("WinForms: running main form '{s}' ({d}x{d})\n", .{ form.text, form.width, form.height });
            }
        }
        // Show native Cocoa window
        syncControlsToNative(self);
        // The Cocoa event loop runs here
        runNativeEventLoop();
    }

    pub fn stop(self: *WinFormsApp) void {
        self.is_running = false;
    }
};

pub const WinFormsBridge = struct {
    app: *WinFormsApp,
    executor: *clr_executor.ILExecutor,

    pub fn init(app: *WinFormsApp, executor: *clr_executor.ILExecutor) WinFormsBridge {
        return WinFormsBridge{ .app = app, .executor = executor };
    }

    fn argToI32(val: clr_executor.StackValue) ?i32 {
        return switch (val) {
            .int32 => |v| v,
            .uint32 => |v| @as(i32, @bitCast(v)),
            .int64 => |v| @as(i32, @truncate(v)),
            .uint64 => |v| @as(i32, @bitCast(@as(u32, @truncate(v)))),
            else => null,
        };
    }

    fn argToU32(val: clr_executor.StackValue) ?u32 {
        return switch (val) {
            .int32 => |v| @as(u32, @bitCast(v)),
            .uint32 => |v| v,
            .int64 => |v| @as(u32, @bitCast(@as(i32, @truncate(v)))),
            .uint64 => |v| @as(u32, @truncate(v)),
            else => null,
        };
    }

    pub fn callWinFormsMethod(self: *WinFormsBridge, method_name: []const u8, args: []const clr_executor.StackValue) WinFormsError!clr_executor.StackValue {
        if (std.mem.eql(u8, method_name, "CreateControl")) {
            const parent = if (args.len > 0) argToU32(args[0]) else null;
            const handle = try self.app.createControl(.Form, parent);
            return clr_executor.StackValue{ .int32 = @intCast(handle) };
        } else if (std.mem.eql(u8, method_name, "set_Text") or std.mem.eql(u8, method_name, "SetText")) {
            if (args.len < 2) return WinFormsError.NotSupported;
            const handle = argToU32(args[0]) orelse return WinFormsError.NotSupported;
            const text = switch (args[1]) {
                .string => |s| s,
                else => return WinFormsError.NotSupported,
            };
            try self.app.setControlText(handle, text);
            return clr_executor.StackValue{ .int32 = 0 };
        } else if (std.mem.eql(u8, method_name, "set_Location") or std.mem.eql(u8, method_name, "SetPosition")) {
            if (args.len < 3) return WinFormsError.NotSupported;
            const handle = argToU32(args[0]) orelse return WinFormsError.NotSupported;
            const x = argToI32(args[1]) orelse return WinFormsError.NotSupported;
            const y = argToI32(args[2]) orelse return WinFormsError.NotSupported;
            try self.app.setControlPosition(handle, x, y);
            return clr_executor.StackValue{ .int32 = 0 };
        } else if (std.mem.eql(u8, method_name, "set_Size") or std.mem.eql(u8, method_name, "SetSize")) {
            if (args.len < 3) return WinFormsError.NotSupported;
            const handle = argToU32(args[0]) orelse return WinFormsError.NotSupported;
            const w = argToI32(args[1]) orelse return WinFormsError.NotSupported;
            const h = argToI32(args[2]) orelse return WinFormsError.NotSupported;
            try self.app.setControlSize(handle, w, h);
            return clr_executor.StackValue{ .int32 = 0 };
        } else if (std.mem.eql(u8, method_name, "Show") or std.mem.eql(u8, method_name, "set_Visible")) {
            if (args.len < 1) return WinFormsError.NotSupported;
            const handle = argToU32(args[0]) orelse return WinFormsError.NotSupported;
            try self.app.showControl(handle);
            return clr_executor.StackValue{ .int32 = 0 };
        } else if (std.mem.eql(u8, method_name, "SetMainForm")) {
            if (args.len < 1) return WinFormsError.NotSupported;
            const handle = argToU32(args[0]) orelse return WinFormsError.NotSupported;
            try self.app.setMainForm(handle);
            return clr_executor.StackValue{ .int32 = 0 };
        } else if (std.mem.eql(u8, method_name, "Run") or std.mem.eql(u8, method_name, "Application.Run")) {
            try self.app.run();
            return clr_executor.StackValue{ .int32 = 0 };
        } else if (std.mem.eql(u8, method_name, "Exit")) {
            self.app.stop();
            return clr_executor.StackValue{ .int32 = 0 };
        } else if (std.mem.eql(u8, method_name, "set_ClientSize") or std.mem.eql(u8, method_name, "SetClientSize")) {
            if (args.len < 3) return WinFormsError.NotSupported;
            const handle = argToU32(args[0]) orelse return WinFormsError.NotSupported;
            const w = argToI32(args[1]) orelse return WinFormsError.NotSupported;
            const h = argToI32(args[2]) orelse return WinFormsError.NotSupported;
            try self.app.setControlSize(handle, w, h + 30);
            return clr_executor.StackValue{ .int32 = 0 };
        } else {
            if (comptime std.debug.runtime_safety) {
                std.log.debug("WinForms bridge: unhandled method '{s}'", .{method_name});
            }
            return WinFormsError.NotSupported;
        }
    }
};

// Native Cocoa window externs
extern fn rosette_winforms_create_window() ?*anyopaque;
extern fn rosette_winforms_set_title(window: ?*anyopaque, title: [*:0]const u8) void;
extern fn rosette_winforms_set_size(window: ?*anyopaque, width: i32, height: i32) void;
extern fn rosette_winforms_show(window: ?*anyopaque) void;
extern fn rosette_run_native_event_loop() void;

pub const NativeWindow = struct {
    handle: ?*anyopaque = null,

    fn create() NativeWindow {
        return NativeWindow{ .handle = rosette_winforms_create_window() };
    }

    fn setTitle(self: *NativeWindow, title: []const u8) void {
        if (self.handle) |h| {
            var buf: [512]u8 = undefined;
            const len = @min(title.len, buf.len - 1);
            @memcpy(buf[0..len], title);
            buf[len] = 0;
            rosette_winforms_set_title(h, @ptrCast(&buf));
        }
    }

    fn setSize(self: *NativeWindow, width: i32, height: i32) void {
        if (self.handle) |h| rosette_winforms_set_size(h, width, height);
    }

    fn show(self: *NativeWindow) void {
        if (self.handle) |h| rosette_winforms_show(h);
    }
};

pub fn syncControlsToNative(app: *WinFormsApp) void {
    if (app.main_form) |mf| {
        if (app.controls.get(mf)) |form| {
            var nw = NativeWindow.create();
            nw.setTitle(form.text);
            nw.setSize(form.width, form.height);
            nw.show();
        }
    }
}

pub fn runNativeEventLoop() void {
    rosette_run_native_event_loop();
}
