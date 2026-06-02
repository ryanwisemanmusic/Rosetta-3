const std = @import("std");

pub const Level = enum(u2) {
    info = 0,
    verbose = 1,
    spam = 2,
};

var g_level: Level = .info;
var g_initted: bool = false;

fn init() void {
    if (g_initted) return;
    g_initted = true;
    const env = std.c.getenv("GFX_LOG") orelse "0";
    const level_str = std.mem.sliceTo(env, 0);
    if (std.mem.eql(u8, level_str, "2")) {
        g_level = .spam;
    } else if (std.mem.eql(u8, level_str, "1")) {
        g_level = .verbose;
    } else {
        g_level = .info;
    }
}

pub fn log(comptime level: Level, comptime fmt: []const u8, args: anytype) void {
    init();
    if (@intFromEnum(level) > @intFromEnum(g_level)) return;
    const prefix = switch (level) {
        .info => "[GFX]",
        .verbose => "[GFX:V]",
        .spam => "[GFX:S]",
    };
    std.debug.print(prefix ++ " " ++ fmt ++ "\n", args);
}
