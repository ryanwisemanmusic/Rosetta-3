const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const StackPlacement = struct {
    base: u32,
    size: u32,
    alignment: u8,
    grows_down: bool,
};

pub const StackInitResult = struct {
    sp: u64,
    ss: u16,
};

pub fn computePhysicalSp(base: u32, size: u32, alignment: u8) u64 {
    const top: u64 = @as(u64, base) + size;
    if (alignment == 0) return top;
    const align_val: u64 = alignment;
    return top & ~(align_val - 1);
}

pub fn applyStackPlacement(
    comptime domain: []const u8,
    memory: []u8,
    placement: StackPlacement,
) StackInitResult {
    const start: usize = @intCast(placement.base);
    const size: usize = @intCast(placement.size);
    const end = start + size;
    if (end > memory.len) {
        runtime_abi.common.violation(
            domain,
            "stack_bounds",
            "{s}: base=0x{x} size={d} memory={d}",
            .{ "stack", placement.base, placement.size, memory.len },
        );
    }
    @memset(memory[start..end], 0);
    const sp = computePhysicalSp(placement.base, placement.size, placement.alignment);
    return .{ .sp = sp, .ss = 0 };
}

test "computePhysicalSp aligns correctly" {
    try std.testing.expectEqual(@as(u64, 0x1800), computePhysicalSp(0x1000, 0x800, 16));
    try std.testing.expectEqual(@as(u64, 0x1004), computePhysicalSp(0x1000, 4, 4));
    try std.testing.expectEqual(@as(u64, 0x1000), computePhysicalSp(0x1000, 0, 16));
}

test "zero alignment returns raw top" {
    try std.testing.expectEqual(@as(u64, 0x1800), computePhysicalSp(0x1000, 0x800, 0));
}

test "applyStackPlacement zeros region and returns sp" {
    var memory = [_]u8{0xFF} ** 64;
    const placement = StackPlacement{
        .base = 16,
        .size = 32,
        .alignment = 16,
        .grows_down = true,
    };
    const result = applyStackPlacement("test-stack", &memory, placement);
    try std.testing.expectEqual(@as(u64, 48), result.sp);
    try std.testing.expectEqual(@as(u16, 0), result.ss);
    try std.testing.expectEqual(@as(u8, 0), memory[16]);
    try std.testing.expectEqual(@as(u8, 0), memory[47]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[15]);
}
