const std = @import("std");
const core = @import("../exe_runner_core.zig");

pub fn main(init: std.process.Init.Minimal) !void {
    _ = init;
    _ = std.c.write(2, "[BOOT] rosette_exe_runner: standalone entry\n", 44);
    return error.AbortTrap;
}
