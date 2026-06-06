const common = @import("entrypoint_stack_placement_common");
const builtin = @import("builtin");
const neon = @import("entrypoint_stack_placement_neon");

pub const StackPlacement = common.StackPlacement;
pub const StackInitResult = common.StackInitResult;

pub fn apply(memory: []u8, placement: StackPlacement) StackInitResult {
    if (builtin.cpu.arch == .aarch64) {
        return neon.apply(memory, placement);
    }
    return common.applyStackPlacement("entrypoint-x86-stack", memory, placement);
}

test "x86 stack init returns flat sp" {
    var memory = [_]u8{0xFF} ** 64;
    const placement = StackPlacement{
        .base = 0,
        .size = 64,
        .alignment = 4,
        .grows_down = true,
    };
    const result = apply(&memory, placement);
    try std.testing.expectEqual(@as(u64, 64), result.sp);
    try std.testing.expectEqual(@as(u16, 0), result.ss);
    try std.testing.expectEqual(@as(u8, 0), memory[0]);
    try std.testing.expectEqual(@as(u8, 0), memory[63]);
}
