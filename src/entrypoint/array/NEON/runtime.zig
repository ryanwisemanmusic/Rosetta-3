const common = @import("entrypoint_array_preserve_common");

pub const ArrayPreserve = common.ArrayPreserve;

pub fn init(memory: []u8, base: u32, element_size: u16, capacity: u32) ArrayPreserve {
    const start: usize = @intCast(base);
    const total_size: usize = @as(usize, capacity) * element_size;
    const end = start + total_size;
    if (end > memory.len) {
        return common.initArrayPreserve("entrypoint-neon-array", memory, base, element_size, capacity);
    }

    const zero16: @Vector(16, u8) = @splat(0);
    const zero_block: [16]u8 = @bitCast(zero16);
    var i: usize = 0;
    while (i + 16 <= total_size) : (i += 16) {
        @memcpy(memory[start + i .. start + i + 16], &zero_block);
    }
    while (i < total_size) : (i += 1) {
        memory[start + i] = 0;
    }

    return .{ .base = base, .element_size = element_size, .capacity = capacity, .count = 0 };
}

pub const push = common.arrayPush;
pub const pop = common.arrayPop;
pub const get = common.arrayGet;
pub const set = common.arraySet;

test "NEON array init" {
    var memory = [_]u8{0xFF} ** 16;
    const arr = init(&memory, 2, 4, 2);
    try std.testing.expectEqual(@as(u32, 2), arr.base);
    try std.testing.expectEqual(@as(u8, 0), memory[2]);
    try std.testing.expectEqual(@as(u8, 0), memory[9]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[1]);
}
