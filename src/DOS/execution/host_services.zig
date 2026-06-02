const std = @import("std");

pub const KeyStatus = struct {
    available: bool,
    ascii: u8 = 0,
    scan: u8 = 0,
};

pub const CursorPosition = struct {
    row: u8,
    col: u8,
};

pub const HostVTable = struct {
    clear_screen: *const fn (ctx: ?*anyopaque) void,
    set_cursor: *const fn (ctx: ?*anyopaque, pos: CursorPosition) void,
    write_char_attr: *const fn (ctx: ?*anyopaque, ch: u8, attr: u8, count: u16) void,
    write_text: *const fn (ctx: ?*anyopaque, text: []const u8) void,
    read_key_blocking: *const fn (ctx: ?*anyopaque) KeyStatus,
    poll_key: *const fn (ctx: ?*anyopaque) ?KeyStatus,
    sleep_microseconds: *const fn (ctx: ?*anyopaque, micros: u32) void,
    time_hundredths: *const fn (ctx: ?*anyopaque) u8,
    exit_process: *const fn (ctx: ?*anyopaque, code: u8) void,
};

pub const HostAdapter = struct {
    ctx: ?*anyopaque = null,
    vtable: HostVTable,

    pub fn clearScreen(self: HostAdapter) void {
        self.vtable.clear_screen(self.ctx);
    }

    pub fn setCursor(self: HostAdapter, row: u8, col: u8) void {
        self.vtable.set_cursor(self.ctx, .{ .row = row, .col = col });
    }

    pub fn writeCharAttr(self: HostAdapter, ch: u8, attr: u8, count: u16) void {
        self.vtable.write_char_attr(self.ctx, ch, attr, count);
    }

    pub fn writeText(self: HostAdapter, text: []const u8) void {
        self.vtable.write_text(self.ctx, text);
    }

    pub fn readKeyBlocking(self: HostAdapter) KeyStatus {
        return self.vtable.read_key_blocking(self.ctx);
    }

    pub fn pollKey(self: HostAdapter) ?KeyStatus {
        return self.vtable.poll_key(self.ctx);
    }

    pub fn sleepMicroseconds(self: HostAdapter, micros: u32) void {
        self.vtable.sleep_microseconds(self.ctx, micros);
    }

    pub fn timeHundredths(self: HostAdapter) u8 {
        return self.vtable.time_hundredths(self.ctx);
    }

    pub fn exitProcess(self: HostAdapter, code: u8) void {
        self.vtable.exit_process(self.ctx, code);
    }
};

pub const NoopHostState = struct {
    log: std.ArrayListUnmanaged(u8) = .empty,
    cursor: CursorPosition = .{ .row = 0, .col = 0 },
    exited: bool = false,
    exit_code: u8 = 0,
    queued_key: ?KeyStatus = null,

    pub fn deinit(self: *NoopHostState, _: std.mem.Allocator) void {
        self.log.deinit(std.heap.page_allocator);
    }

    pub fn adapter(self: *NoopHostState) HostAdapter {
        return .{
            .ctx = self,
            .vtable = .{
                .clear_screen = clearScreen,
                .set_cursor = setCursor,
                .write_char_attr = writeCharAttr,
                .write_text = writeText,
                .read_key_blocking = readKeyBlocking,
                .poll_key = pollKey,
                .sleep_microseconds = sleepMicroseconds,
                .time_hundredths = timeHundredths,
                .exit_process = exitProcess,
            },
        };
    }

    fn clearScreen(ctx: ?*anyopaque) void {
        const self: *NoopHostState = @ptrCast(@alignCast(ctx.?));
        self.log.clearRetainingCapacity();
    }

    fn setCursor(ctx: ?*anyopaque, pos: CursorPosition) void {
        const self: *NoopHostState = @ptrCast(@alignCast(ctx.?));
        self.cursor = pos;
    }

    fn writeCharAttr(ctx: ?*anyopaque, ch: u8, _: u8, count: u16) void {
        const self: *NoopHostState = @ptrCast(@alignCast(ctx.?));
        for (0..count) |_| {
            self.log.append(std.heap.page_allocator, ch) catch {};
        }
    }

    fn writeText(ctx: ?*anyopaque, text: []const u8) void {
        const self: *NoopHostState = @ptrCast(@alignCast(ctx.?));
        self.log.appendSlice(std.heap.page_allocator, text) catch {};
    }

    fn readKeyBlocking(ctx: ?*anyopaque) KeyStatus {
        const self: *NoopHostState = @ptrCast(@alignCast(ctx.?));
        if (self.queued_key) |key| {
            self.queued_key = null;
            return key;
        }
        return .{ .available = true, .ascii = 13, .scan = 0x1C };
    }

    fn pollKey(ctx: ?*anyopaque) ?KeyStatus {
        const self: *NoopHostState = @ptrCast(@alignCast(ctx.?));
        return self.queued_key;
    }

    fn sleepMicroseconds(_: ?*anyopaque, _: u32) void {}

    fn timeHundredths(_: ?*anyopaque) u8 {
        return 42;
    }

    fn exitProcess(ctx: ?*anyopaque, code: u8) void {
        const self: *NoopHostState = @ptrCast(@alignCast(ctx.?));
        self.exited = true;
        self.exit_code = code;
    }
};
