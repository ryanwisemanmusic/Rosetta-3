const std = @import("std");
const core = @import("../exe_runner_core.zig");

pub fn main(init: std.process.Init.Minimal) !void {
    _ = init;
    _ = std.c.write(2, "[ABORT_TRAP] main_entry\n", 24);
    std.c.abort();
    return error.AbortTrap;
}
