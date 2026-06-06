const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const ArrayPreserve = struct {
    base: u32,
    element_size: u16,
    capacity: u32,
    count: u32,
};

pub fn initArrayPreserve(
    comptime domain: []const u8,
    memory: []u8,
    base: u32,
    element_size: u16,
    capacity: u32,
) ArrayPreserve {
    const start: usize = @intCast(base);
    const total_size: usize = @as(usize, capacity) * element_size;
    const end = start + total_size;
    if (end > memory.len) {
        runtime_abi.common.violation(
            domain,
            "array_bounds",
            "{s}: base=0x{x} element_size={d} capacity={d} memory={d}",
            .{ "array", base, element_size, capacity, memory.len },
        );
    }
    @memset(memory[start..end], 0);
    return .{
        .base = base,
        .element_size = element_size,
        .capacity = capacity,
        .count = 0,
    };
}

pub fn arrayPush(arr: *ArrayPreserve, memory: []u8, data: []const u8) void {
    if (arr.count >= arr.capacity) return;
    if (data.len != arr.element_size) return;
    const start: usize = @intCast(arr.base) + @as(usize, arr.count) * arr.element_size;
    @memcpy(memory[start .. start + arr.element_size], data);
    arr.count += 1;
}

pub fn arrayPop(arr: *ArrayPreserve, memory: []u8, dest: []u8) void {
    if (arr.count == 0) return;
    if (dest.len < arr.element_size) return;
    arr.count -= 1;
    const start: usize = @intCast(arr.base) + @as(usize, arr.count) * arr.element_size;
    @memcpy(dest[0..arr.element_size], memory[start .. start + arr.element_size]);
}

pub fn arrayGet(arr: *const ArrayPreserve, memory: []u8, index: u32, dest: []u8) void {
    if (index >= arr.count) return;
    if (dest.len < arr.element_size) return;
    const start: usize = @intCast(arr.base) + @as(usize, index) * arr.element_size;
    @memcpy(dest[0..arr.element_size], memory[start .. start + arr.element_size]);
}

pub fn arraySet(arr: *ArrayPreserve, memory: []u8, index: u32, data: []const u8) void {
    if (index >= arr.capacity) return;
    if (data.len != arr.element_size) return;
    const start: usize = @intCast(arr.base) + @as(usize, index) * arr.element_size;
    @memcpy(memory[start .. start + arr.element_size], data);
    if (index >= arr.count) arr.count = index + 1;
}

test "initArrayPreserve zeros region" {
    var memory = [_]u8{0xFF} ** 32;
    const arr = initArrayPreserve("test", &memory, 8, 4, 3);
    try std.testing.expectEqual(@as(u32, 8), arr.base);
    try std.testing.expectEqual(@as(u16, 4), arr.element_size);
    try std.testing.expectEqual(@as(u32, 3), arr.capacity);
    try std.testing.expectEqual(@as(u32, 0), arr.count);
    try std.testing.expectEqual(@as(u8, 0), memory[8]);
    try std.testing.expectEqual(@as(u8, 0), memory[19]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[7]);
}

test "arrayPush and arrayPop round-trip" {
    var memory = [_]u8{0} ** 32;
    var arr = initArrayPreserve("test", &memory, 0, 4, 4);
    const val1 = [_]u8{ 0xAA, 0xBB, 0xCC, 0xDD };
    const val2 = [_]u8{ 0x11, 0x22, 0x33, 0x44 };
    arrayPush(&arr, &memory, &val1);
    arrayPush(&arr, &memory, &val2);
    try std.testing.expectEqual(@as(u32, 2), arr.count);
    var buf: [4]u8 = undefined;
    arrayPop(&arr, &memory, &buf);
    try std.testing.expectEqualSlices(u8, &val2, &buf);
    arrayPop(&arr, &memory, &buf);
    try std.testing.expectEqualSlices(u8, &val1, &buf);
    try std.testing.expectEqual(@as(u32, 0), arr.count);
}

test "arrayGet and arraySet by index" {
    var memory = [_]u8{0} ** 32;
    var arr = initArrayPreserve("test", &memory, 0, 8, 3);
    const v1 = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 };
    const v2 = [_]u8{ 9, 10, 11, 12, 13, 14, 15, 16 };
    arraySet(&arr, &memory, 1, &v1);
    arraySet(&arr, &memory, 2, &v2);
    var buf: [8]u8 = undefined;
    arrayGet(&arr, &memory, 1, &buf);
    try std.testing.expectEqualSlices(u8, &v1, &buf);
    arrayGet(&arr, &memory, 2, &buf);
    try std.testing.expectEqualSlices(u8, &v2, &buf);
}
