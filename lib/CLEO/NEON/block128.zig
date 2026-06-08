const std = @import("std");
const wide = @import("../wide.zig");
const types = @import("../types.zig");

pub const Block128 = wide.Wide(types.VECTOR_BLOCK_BITS);

pub fn blockCount(comptime bits: usize) usize {
    types.validateWideWidth(bits);
    return bits / types.VECTOR_BLOCK_BITS;
}

pub fn split(comptime bits: usize, value: wide.Wide(bits)) [blockCount(bits)]Block128 {
    var blocks: [blockCount(bits)]Block128 = undefined;
    for (0..blockCount(bits)) |block| {
        const start = block * types.VECTOR_BLOCK_BYTES;
        const end = start + types.VECTOR_BLOCK_BYTES;
        var bytes: [types.VECTOR_BLOCK_BYTES]u8 = undefined;
        @memcpy(bytes[0..], value.bytes[start..end]);
        blocks[block] = Block128.fromBytes(bytes);
    }
    return blocks;
}

pub fn join(comptime bits: usize, blocks: [blockCount(bits)]Block128) wide.Wide(bits) {
    var result = wide.Wide(bits).zero();
    for (0..blockCount(bits)) |block| {
        const start = block * types.VECTOR_BLOCK_BYTES;
        const end = start + types.VECTOR_BLOCK_BYTES;
        @memcpy(result.bytes[start..end], blocks[block].bytes[0..]);
    }
    return result;
}

pub fn validateRoundTrip(comptime bits: usize, value: wide.Wide(bits)) !void {
    const blocks = split(bits, value);
    const merged = join(bits, blocks);
    try std.testing.expect(value.equal(merged));
}

test "NEON block splitter preserves 512-bit byte order" {
    var data: [64]u8 = undefined;
    for (0..64) |i| data[i] = @intCast(i);
    const value = wide.Wide(512).fromBytes(data);
    const blocks = split(512, value);
    try std.testing.expectEqual(@as(u8, 0), blocks[0].bytes[0]);
    try std.testing.expectEqual(@as(u8, 16), blocks[1].bytes[0]);
    try validateRoundTrip(512, value);
}
