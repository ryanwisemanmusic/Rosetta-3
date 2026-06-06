const common = @import("entrypoint_stack_placement_common");

pub const StackPlacement = common.StackPlacement;
pub const StackInitResult = common.StackInitResult;

pub fn apply(memory: []u8, placement: StackPlacement) StackInitResult {
    return common.applyStackPlacement("entrypoint-x64-stack", memory, placement);
}

test "x64 stack init returns flat 16-byte aligned sp" {
    var memory = [_]u8{0xFF} ** 128;
    const placement = StackPlacement{
        .base = 0,
        .size = 100,
        .alignment = 16,
        .grows_down = true,
    };
    const result = apply(&memory, placement);
    try std.testing.expectEqual(@as(u64, 96), result.sp);
    try std.testing.expectEqual(@as(u16, 0), result.ss);
    try std.testing.expect(result.sp % 16 == 0);
}
