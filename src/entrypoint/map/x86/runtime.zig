const common = @import("entrypoint_map_preserve_common");
const builtin = @import("builtin");
const neon = @import("entrypoint_map_preserve_neon");

pub const MapPreserve = common.MapPreserve;

pub fn init(memory: []u8, base: u32, capacity: u32) MapPreserve {
    if (builtin.cpu.arch == .aarch64) {
        return neon.init(memory, base, capacity);
    }
    return common.initMapPreserve("entrypoint-x86-map", memory, base, capacity);
}

pub const insert = common.mapInsert;
pub const lookup = common.mapLookup;
pub const remove = common.mapRemove;

test "x86 map init" {
    var memory = [_]u8{0xFF} ** 32;
    const map = init(&memory, 0, 1);
    try std.testing.expectEqual(@as(u32, 0), map.base);
    try std.testing.expectEqual(@as(u8, 0), memory[0]);
}
