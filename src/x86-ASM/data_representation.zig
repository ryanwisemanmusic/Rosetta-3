const std = @import("std");
const core = @import("family_core.zig");

pub const IntegerRepr = struct {
    width: core.OperandWidth,
    signedness: core.Signedness,
    raw: u64,
};

pub fn bitMask(width: core.OperandWidth) u64 {
    return switch (width) {
        .byte => 0xFF,
        .word => 0xFFFF,
        .dword => 0xFFFF_FFFF,
        .qword => std.math.maxInt(u64),
        else => std.math.maxInt(u64),
    };
}

pub fn truncateTo(width: core.OperandWidth, value: u64) u64 {
    return value & bitMask(width);
}

pub fn zeroExtend(width: core.OperandWidth, value: u64) u64 {
    return truncateTo(width, value);
}

pub fn signExtend(width: core.OperandWidth, value: u64) u64 {
    const narrowed = truncateTo(width, value);
    return switch (width) {
        .byte => @bitCast(@as(i64, @as(i8, @bitCast(@as(u8, @truncate(narrowed)))))),
        .word => @bitCast(@as(i64, @as(i16, @bitCast(@as(u16, @truncate(narrowed)))))),
        .dword => @bitCast(@as(i64, @as(i32, @bitCast(@as(u32, @truncate(narrowed)))))),
        .qword => narrowed,
        else => narrowed,
    };
}

pub fn loadLittleEndian(bytes: []const u8, width: core.OperandWidth) u64 {
    var result: u64 = 0;
    for (bytes[0..@min(bytes.len, width.bytes())], 0..) |byte, index| {
        result |= @as(u64, byte) << @intCast(index * 8);
    }
    return result;
}

pub fn storeLittleEndian(out: []u8, width: core.OperandWidth, value: u64) void {
    const count = @min(out.len, width.bytes());
    for (0..count) |index| {
        out[index] = @truncate(value >> @intCast(index * 8));
    }
}

test "zero and sign extension match x86 expectations" {
    try std.testing.expectEqual(@as(u64, 0x80), zeroExtend(.byte, 0x180));
    try std.testing.expectEqual(@as(u64, 0xFFFF_FFFF_FFFF_FF80), signExtend(.byte, 0x80));
    try std.testing.expectEqual(@as(u64, 0xFFFF_FFFF_FFFF_8000), signExtend(.word, 0x8000));
}

test "little endian helpers round-trip dword" {
    var bytes: [4]u8 = undefined;
    storeLittleEndian(&bytes, .dword, 0x7856_3412);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x12, 0x34, 0x56, 0x78 }, &bytes);
    try std.testing.expectEqual(@as(u64, 0x7856_3412), loadLittleEndian(&bytes, .dword));
}
