const common = @import("entrypoint_map_preserve_common");

pub const MapPreserve = common.MapPreserve;

pub fn init(memory: []u8, base: u32, capacity: u32) MapPreserve {
    const start: usize = @intCast(base);
    const total_size: usize = capacity * @sizeOf(common.MapEntry);
    const end = start + total_size;
    if (end > memory.len) {
        return common.initMapPreserve("entrypoint-neon-map", memory, base, capacity);
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

    return .{ .base = base, .capacity = capacity, .count = 0 };
}

pub const insert = common.mapInsert;
pub const lookup = common.mapLookup;
pub const remove = common.mapRemove;

test "NEON map init" {
    var memory = [_]u8{0xFF} ** 32;
    const map = init(&memory, 4, 1);
    try std.testing.expectEqual(@as(u32, 4), map.base);
    try std.testing.expectEqual(@as(u8, 0), memory[4]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[3]);
}
