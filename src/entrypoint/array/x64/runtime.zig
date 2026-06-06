const common = @import("entrypoint_array_preserve_common");

pub const ArrayPreserve = common.ArrayPreserve;

pub fn init(memory: []u8, base: u32, element_size: u16, capacity: u32) ArrayPreserve {
    return common.initArrayPreserve("entrypoint-x64-array", memory, base, element_size, capacity);
}

pub const push = common.arrayPush;
pub const pop = common.arrayPop;
pub const get = common.arrayGet;
pub const set = common.arraySet;

test "x64 array init" {
    var memory = [_]u8{0xFF} ** 16;
    const arr = init(&memory, 0, 8, 1);
    try std.testing.expectEqual(@as(u32, 0), arr.base);
    try std.testing.expectEqual(@as(u8, 0), memory[0]);
    try std.testing.expectEqual(@as(u8, 0), memory[7]);
}
