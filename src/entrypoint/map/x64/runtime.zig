const common = @import("entrypoint_map_preserve_common");

pub const MapPreserve = common.MapPreserve;

pub fn init(memory: []u8, base: u32, capacity: u32) MapPreserve {
    return common.initMapPreserve("entrypoint-x64-map", memory, base, capacity);
}

pub const insert = common.mapInsert;
pub const lookup = common.mapLookup;
pub const remove = common.mapRemove;

test "x64 map init" {
    var memory = [_]u8{0xFF} ** 32;
    const map = init(&memory, 0, 1);
    try std.testing.expectEqual(@as(u32, 0), map.base);
    try std.testing.expectEqual(@as(u8, 0), memory[0]);
}
