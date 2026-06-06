const common = @import("entrypoint_stack_placement_common");

pub const StackPlacement = common.StackPlacement;
pub const StackInitResult = common.StackInitResult;

pub fn apply(memory: []u8, placement: StackPlacement) StackInitResult {
    const start: usize = @intCast(placement.base);
    const size: usize = @intCast(placement.size);
    const end = start + size;
    if (end > memory.len) {
        common.applyStackPlacement("entrypoint-dos-stack", memory, placement);
        return .{ .sp = 0, .ss = 0 };
    }
    @memset(memory[start..end], 0);
    const phys_sp = common.computePhysicalSp(placement.base, placement.size, placement.alignment);
    const ss: u16 = @intCast(placement.base >> 4);
    const sp_offset: u64 = phys_sp - (@as(u64, ss) << 4);
    return .{ .sp = sp_offset, .ss = ss };
}

test "DOS stack init returns segmented result" {
    var memory = [_]u8{0xFF} ** 256;
    const placement = StackPlacement{
        .base = 0x10000,
        .size = 0x100,
        .alignment = 16,
        .grows_down = true,
    };
    const result = apply(&memory, placement);
    try std.testing.expectEqual(@as(u16, 0x1000), result.ss);
    try std.testing.expectEqual(@as(u64, 0x100), result.sp);
    try std.testing.expectEqual(@as(u8, 0), memory[0x10000]);
    try std.testing.expectEqual(@as(u8, 0), memory[0x100FF]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[0x0FFF]);
}
