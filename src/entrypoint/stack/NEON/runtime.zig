const common = @import("entrypoint_stack_placement_common");

pub const StackPlacement = common.StackPlacement;
pub const StackInitResult = common.StackInitResult;

pub fn apply(memory: []u8, placement: StackPlacement) StackInitResult {
    const start: usize = @intCast(placement.base);
    const size: usize = @intCast(placement.size);
    const end = start + size;
    if (end > memory.len) {
        return common.applyStackPlacement("entrypoint-neon-stack", memory, placement);
    }

    const zero16: @Vector(16, u8) = @splat(0);
    const zero_block: [16]u8 = @bitCast(zero16);
    var i: usize = 0;
    while (i + 16 <= size) : (i += 16) {
        @memcpy(memory[start + i .. start + i + 16], &zero_block);
    }
    while (i < size) : (i += 1) {
        memory[start + i] = 0;
    }

    const sp = common.computePhysicalSp(placement.base, placement.size, placement.alignment);
    return .{ .sp = sp, .ss = 0 };
}

test "NEON stack init returns flat sp with region zeroed" {
    var memory = [_]u8{0xFF} ** 64;
    const placement = StackPlacement{
        .base = 8,
        .size = 48,
        .alignment = 16,
        .grows_down = true,
    };
    const result = apply(&memory, placement);
    try std.testing.expectEqual(@as(u64, 56), result.sp);
    try std.testing.expectEqual(@as(u16, 0), result.ss);
    try std.testing.expectEqual(@as(u8, 0), memory[8]);
    try std.testing.expectEqual(@as(u8, 0), memory[55]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[7]);
}
