const std = @import("std");
const core = @import("../x86-ASM/family_core.zig");
const ia32 = @import("../x86-ASM/ia32_state.zig");
const x64 = @import("x64_state.zig");

pub const FamilyCpuState = union(core.ExecutionMode) {
    ia32: ia32.Ia32State,
    x64: x64.X64State,

    pub fn mode(self: FamilyCpuState) core.ExecutionMode {
        return switch (self) {
            .ia32 => .ia32,
            .x64 => .x64,
        };
    }
};

test "bridge exposes both execution modes under one family state" {
    const state = FamilyCpuState{ .x64 = .{} };
    try std.testing.expectEqual(core.ExecutionMode.x64, state.mode());
}
