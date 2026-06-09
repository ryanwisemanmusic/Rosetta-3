const std = @import("std");
const builtin = @import("builtin");

pub const lib866d_tag: []const u8 = @import("root.zig").lib866d_tag;

pub fn assert(ok: bool) void {
    if (!ok) @panic("LIB866D ASSERTION FAILED");
}

pub fn assertMsg(ok: bool, msg: []const u8) void {
    if (!ok) {
        std.log.err("LIB866D FATAL ERROR\n Module: [ {s} ]\n Assertion failed!\n {s}\n Aborting...\n", .{ lib866d_tag, msg });
        @panic(msg);
    }
}

pub fn nullcheck(ptr: anytype) void {
    if (@intFromPtr(ptr) == 0) {
        std.log.err("LIB866D FATAL ERROR\n Module: [ {s} ]\n NULL POINTER\n Aborting...\n", .{lib866d_tag});
        @panic("NULL POINTER");
    }
}

pub fn dbg(comptime fmt: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        std.log.debug(fmt, args);
    }
}
