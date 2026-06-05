const std = @import("std");

pub const common = struct {
    pub fn writeLine(comptime fmt: []const u8, args: anytype) void {
        std.debug.print(fmt, args);
    }
    pub fn violation(_: []const u8, _: []const u8, comptime fmt: []const u8, args: anytype) void {
        std.debug.print(fmt, args);
    }
};
