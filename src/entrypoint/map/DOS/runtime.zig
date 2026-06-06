const common = @import("entrypoint_map_preserve_common");

pub const MapPreserve = common.MapPreserve;

pub fn init(memory: []u8, base: u32, capacity: u32) MapPreserve {
    const start: usize = @intCast(base);
    const total_size: usize = capacity * @sizeOf(common.MapEntry);
    const end = start + total_size;
    if (end > memory.len) {
        return common.initMapPreserve("entrypoint-dos-map", memory, base, capacity);
    }
    @memset(memory[start..end], 0);
    return .{ .base = base, .capacity = capacity, .count = 0 };
}

pub const insert = common.mapInsert;
pub const lookup = common.mapLookup;
pub const remove = common.mapRemove;

test "DOS map init" {
    var memory = [_]u8{0xFF} ** 32;
    const map = init(&memory, 0x1000, 1);
    try std.testing.expectEqual(@as(u32, 0x1000), map.base);
    try std.testing.expectEqual(@as(u8, 0), memory[0x1000]);
}
