const std = @import("std");
const Executor = @import("instruction_operations.zig").Executor;
const abi = @import("abi_handshake.zig");

extern "C" fn rosetta3_cli_get_key() c_int;
extern "C" fn rosetta3_cli_move_cursor(x: c_int, y: c_int) void;
extern "C" fn rosetta3_cli_clear() void;

pub fn readKeyToEax(ex: *Executor) void {
    ex.regs.eax = @as(u32, @bitCast(rosetta3_cli_get_key()));
}

pub fn clearScreen() void {
    rosetta3_cli_clear();
}

pub fn moveCursor(x: i32, y: i32) void {
    rosetta3_cli_move_cursor(@intCast(x), @intCast(y));
}

pub fn writeByte(byte: u8) void {
    _ = std.c.write(1, &[_]u8{byte}, 1);
}

pub fn writeText(text: []const u8) void {
    _ = std.c.write(1, text.ptr, text.len);
}

pub fn sleepFromEax(ex: *Executor) void {
    abi.sleepMilliseconds(ex.regs.eax);
}

pub fn pauseSeconds(seconds: u32) void {
    var ts = std.c.timespec{ .sec = @intCast(seconds), .nsec = 0 };
    _ = std.c.nanosleep(&ts, null);
}
