const common = @import("entrypoint_array_preserve_common");

pub const ArrayPreserve = common.ArrayPreserve;

pub fn init(memory: []u8, base: u32, element_size: u16, capacity: u32) ArrayPreserve {
    const start: usize = @intCast(base);
    const total_size: usize = @as(usize, capacity) * element_size;
    const end = start + total_size;
    if (end > memory.len) {
        return common.initArrayPreserve("entrypoint-dos-array", memory, base, element_size, capacity);
    }
    @memset(memory[start..end], 0);
    return .{ .base = base, .element_size = element_size, .capacity = capacity, .count = 0 };
}

pub const push = common.arrayPush;
pub const pop = common.arrayPop;
pub const get = common.arrayGet;
pub const set = common.arraySet;

test "DOS array init" {
    var memory = [_]u8{0xFF} ** 32;
    const arr = init(&memory, 0x1000, 2, 4);
    try std.testing.expectEqual(@as(u32, 0x1000), arr.base);
    try std.testing.expectEqual(@as(u8, 0), memory[0x1000]);
}
