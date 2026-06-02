const std = @import("std");
const Executor = @import("instruction_operations.zig").Executor;
const abi = @import("abi_handshake.zig");

extern "C" fn rosetta3_cli_get_key() c_int;
extern "C" fn rosetta3_cli_move_cursor(x: c_int, y: c_int) void;
extern "C" fn rosetta3_cli_clear() void;
extern "C" fn rosetta3_cli_write_byte(byte: u8) void;
extern "C" fn rosetta3_cli_write_text(text: [*]const u8, len: c_int) void;

/// Graphics renderer — routes output to the block framebuffer when active.
const gfx = @import("graphics/renderer.zig");

pub fn readKeyToEax(ex: *Executor) void {
    ex.regs.eax = @as(u32, @bitCast(rosetta3_cli_get_key()));
}

pub fn clearScreen() void {
    gfx.rosetta3_gfx_begin_frame();
    rosetta3_cli_clear();
}

pub fn moveCursor(x: i32, y: i32) void {
    gfx.rosetta3_gfx_move_cursor(x, y);
    rosetta3_cli_move_cursor(@intCast(x), @intCast(y));
}

pub fn writeByte(byte: u8) void {
    gfx.rosetta3_gfx_write_byte(byte);
    rosetta3_cli_write_byte(byte);
}

pub fn writeText(text: []const u8) void {
    gfx.rosetta3_gfx_write_text(text.ptr, @intCast(text.len));
    rosetta3_cli_write_text(text.ptr, @intCast(text.len));
}

pub fn sleepFromEax(ex: *Executor) void {
    abi.sleepMilliseconds(ex.regs.eax);
}

pub fn pauseSeconds(seconds: u32) void {
    var ts = std.c.timespec{ .sec = @intCast(seconds), .nsec = 0 };
    _ = std.c.nanosleep(&ts, null);
}
