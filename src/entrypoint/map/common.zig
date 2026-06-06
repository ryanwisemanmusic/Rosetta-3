const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const MapEntry = extern struct {
    key: u64,
    value: u64,
};

pub const MapPreserve = struct {
    base: u32,
    capacity: u32,
    count: u32,
};

pub fn initMapPreserve(
    comptime domain: []const u8,
    memory: []u8,
    base: u32,
    capacity: u32,
) MapPreserve {
    const start: usize = @intCast(base);
    const entry_size = @sizeOf(MapEntry);
    const total_size: usize = capacity * entry_size;
    const end = start + total_size;
    if (end > memory.len) {
        runtime_abi.common.violation(
            domain,
            "map_bounds",
            "{s}: base=0x{x} capacity={d} memory={d}",
            .{ "map", base, capacity, memory.len },
        );
    }
    @memset(memory[start..end], 0);
    return .{ .base = base, .capacity = capacity, .count = 0 };
}

fn entryPtr(memory: []u8, map_base: u32, index: u32) *align(1) MapEntry {
    const offset: usize = @intCast(map_base) + @as(usize, index) * @sizeOf(MapEntry);
    return @ptrCast(&memory[offset]);
}

pub fn mapInsert(map: *MapPreserve, memory: []u8, key: u64, value: u64) void {
    for (0..map.count) |i| {
        const e = entryPtr(memory, map.base, @intCast(i));
        if (e.key == key) {
            e.value = value;
            return;
        }
    }
    if (map.count >= map.capacity) return;
    const e = entryPtr(memory, map.base, map.count);
    e.key = key;
    e.value = value;
    map.count += 1;
}

pub fn mapLookup(map: *const MapPreserve, memory: []u8, key: u64) ?u64 {
    for (0..map.count) |i| {
        const e = entryPtr(memory, map.base, @intCast(i));
        if (e.key == key) return e.value;
    }
    return null;
}

pub fn mapRemove(map: *MapPreserve, memory: []u8, key: u64) bool {
    for (0..map.count) |i| {
        const e = entryPtr(memory, map.base, @intCast(i));
        if (e.key == key) {
            const last = entryPtr(memory, map.base, map.count - 1);
            e.key = last.key;
            e.value = last.value;
            map.count -= 1;
            return true;
        }
    }
    return false;
}

test "initMapPreserve zeros region" {
    var memory = [_]u8{0xFF} ** 48;
    const map = initMapPreserve("test", &memory, 8, 2);
    try std.testing.expectEqual(@as(u32, 8), map.base);
    try std.testing.expectEqual(@as(u32, 2), map.capacity);
    try std.testing.expectEqual(@as(u32, 0), map.count);
    try std.testing.expectEqual(@as(u8, 0), memory[8]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[7]);
}

test "mapInsert and mapLookup round-trip" {
    var memory = [_]u8{0} ** 64;
    var map = initMapPreserve("test", &memory, 0, 4);
    mapInsert(&map, &memory, 0x100, 0xABCD);
    mapInsert(&map, &memory, 0x200, 0xEF01);
    try std.testing.expectEqual(@as(u32, 2), map.count);
    try std.testing.expectEqual(@as(?u64, 0xABCD), mapLookup(&map, &memory, 0x100));
    try std.testing.expectEqual(@as(?u64, 0xEF01), mapLookup(&map, &memory, 0x200));
    try std.testing.expectEqual(@as(?u64, null), mapLookup(&map, &memory, 0x300));
}

test "mapInsert updates existing key" {
    var memory = [_]u8{0} ** 64;
    var map = initMapPreserve("test", &memory, 0, 4);
    mapInsert(&map, &memory, 0x100, 0xAAAA);
    mapInsert(&map, &memory, 0x100, 0xBBBB);
    try std.testing.expectEqual(@as(u32, 1), map.count);
    try std.testing.expectEqual(@as(?u64, 0xBBBB), mapLookup(&map, &memory, 0x100));
}

test "mapRemove removes entry" {
    var memory = [_]u8{0} ** 64;
    var map = initMapPreserve("test", &memory, 0, 4);
    mapInsert(&map, &memory, 0x100, 0xAAAA);
    mapInsert(&map, &memory, 0x200, 0xBBBB);
    try std.testing.expect(mapRemove(&map, &memory, 0x100));
    try std.testing.expectEqual(@as(u32, 1), map.count);
    try std.testing.expectEqual(@as(?u64, null), mapLookup(&map, &memory, 0x100));
    try std.testing.expectEqual(@as(?u64, 0xBBBB), mapLookup(&map, &memory, 0x200));
}
