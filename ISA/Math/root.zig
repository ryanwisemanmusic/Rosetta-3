const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const core = @import("core.zig");
pub const x86 = @import("x86/Zig/root.zig");
pub const neon = @import("NEON/Zig/root.zig");

pub fn validateAll() void {
    x86.validateAll();
    neon.validateAll();
}

pub fn exerciseAll() !void {
    try x86.exerciseAll();
    try neon.exerciseAll();
    try neon.exerciseMirrors();
}

test "ISA Math validates x86 semantics and NEON mirrors" {
    runtime_abi.isa.init();
    defer runtime_abi.isa.deinit();

    try std.testing.expectEqual(x86.tableCount(), neon.tableCount());
    validateAll();
    try exerciseAll();
}
