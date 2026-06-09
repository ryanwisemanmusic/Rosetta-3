const std = @import("std");
const types = @import("types.zig");

pub const BinaryOp = enum {
    add,
    sub,
    mul,
    div,
    bit_or,
    bit_xor,
    addsub,
};

pub const MaskMode = enum {
    merge,
    zero,
};

pub fn Wide(comptime bits: usize) type {
    types.validateWideWidth(bits);
    return struct {
        pub const bit_count = bits;
        pub const byte_count = bits / 8;
        pub const block_count = bits / types.VECTOR_BLOCK_BITS;

        bytes: [byte_count]u8,

        pub fn zero() @This() {
            return .{ .bytes = [_]u8{0} ** byte_count };
        }

        pub fn fromBytes(bytes: [byte_count]u8) @This() {
            return .{ .bytes = bytes };
        }

        pub fn splatByte(byte: u8) @This() {
            return .{ .bytes = [_]u8{byte} ** byte_count };
        }

        pub fn equal(self: @This(), other: @This()) bool {
            return std.mem.eql(u8, self.bytes[0..], other.bytes[0..]);
        }
    };
}

pub fn laneCount(comptime bits: usize, comptime T: type) usize {
    return types.laneCount(bits, T);
}

pub fn fromArray(comptime bits: usize, comptime T: type, array: [laneCount(bits, T)]T) Wide(bits) {
    var result = Wide(bits).zero();
    @memcpy(result.bytes[0..], std.mem.asBytes(&array));
    return result;
}

pub fn toArray(comptime bits: usize, comptime T: type, value: Wide(bits)) [laneCount(bits, T)]T {
    var result: [laneCount(bits, T)]T = undefined;
    @memcpy(std.mem.asBytes(&result), value.bytes[0..]);
    return result;
}

pub fn load(comptime bits: usize, comptime T: type, src: []const T) types.SafetyError!Wide(bits) {
    const lanes = comptime laneCount(bits, T);
    if (src.len < lanes) return types.SafetyError.BufferTooSmall;
    var tmp: [lanes]T = undefined;
    for (0..lanes) |lane| tmp[lane] = src[lane];
    return fromArray(bits, T, tmp);
}

pub fn store(comptime bits: usize, comptime T: type, dst: []T, value: Wide(bits)) types.SafetyError!void {
    const lanes = comptime laneCount(bits, T);
    if (dst.len < lanes) return types.SafetyError.BufferTooSmall;
    const tmp = toArray(bits, T, value);
    for (0..lanes) |lane| dst[lane] = tmp[lane];
}

pub fn loadBytes(comptime bits: usize, src: []const u8) types.SafetyError!Wide(bits) {
    const byte_count = bits / 8;
    if (src.len < byte_count) return types.SafetyError.BufferTooSmall;
    var result = Wide(bits).zero();
    @memcpy(result.bytes[0..], src[0..byte_count]);
    return result;
}

pub fn storeBytes(comptime bits: usize, dst: []u8, value: Wide(bits)) types.SafetyError!void {
    const byte_count = bits / 8;
    if (dst.len < byte_count) return types.SafetyError.BufferTooSmall;
    @memcpy(dst[0..byte_count], value.bytes[0..]);
}

pub fn loadBytesAligned(comptime bits: usize, src: []const u8, alignment: types.Alignment) types.SafetyError!Wide(bits) {
    const required = alignment.bytes();
    if (required > 1 and @intFromPtr(src.ptr) % required != 0) return types.SafetyError.MisalignedMemory;
    return loadBytes(bits, src);
}

pub fn storeBytesAligned(comptime bits: usize, dst: []u8, value: Wide(bits), alignment: types.Alignment) types.SafetyError!void {
    const required = alignment.bytes();
    if (required > 1 and @intFromPtr(dst.ptr) % required != 0) return types.SafetyError.MisalignedMemory;
    try storeBytes(bits, dst, value);
}

fn zeroValue(comptime T: type) T {
    return switch (@typeInfo(T)) {
        .float => @as(T, 0.0),
        .int => @as(T, 0),
        else => @compileError("CLEO only supports integer and float lane types"),
    };
}

fn applyBinaryScalar(comptime T: type, lhs: T, rhs: T, comptime op: BinaryOp, lane: usize) T {
    return switch (op) {
        .add => if (@typeInfo(T) == .float) lhs + rhs else lhs +% rhs,
        .sub => if (@typeInfo(T) == .float) lhs - rhs else lhs -% rhs,
        .mul => if (@typeInfo(T) == .float) lhs * rhs else lhs *% rhs,
        .div => if (@typeInfo(T) == .float) lhs / rhs else @divTrunc(lhs, rhs),
        .bit_or => lhs | rhs,
        .bit_xor => lhs ^ rhs,
        .addsub => if ((lane & 1) == 0)
            (if (@typeInfo(T) == .float) lhs - rhs else lhs -% rhs)
        else
            (if (@typeInfo(T) == .float) lhs + rhs else lhs +% rhs),
    };
}

pub fn mapBinary(comptime bits: usize, comptime T: type, lhs: Wide(bits), rhs: Wide(bits), comptime op: BinaryOp) Wide(bits) {
    const lanes = comptime laneCount(bits, T);
    const a = toArray(bits, T, lhs);
    const b = toArray(bits, T, rhs);
    var out: [lanes]T = undefined;
    for (0..lanes) |lane| out[lane] = applyBinaryScalar(T, a[lane], b[lane], op, lane);
    return fromArray(bits, T, out);
}

pub fn mapBinaryMasked(comptime bits: usize, comptime T: type, merge: Wide(bits), lhs: Wide(bits), rhs: Wide(bits), mask: u64, mode: MaskMode, comptime op: BinaryOp) Wide(bits) {
    const lanes = comptime laneCount(bits, T);
    const base = toArray(bits, T, merge);
    const a = toArray(bits, T, lhs);
    const b = toArray(bits, T, rhs);
    var out: [lanes]T = undefined;
    for (0..lanes) |lane| {
        const bit = (@as(u64, 1) << @intCast(lane));
        if ((mask & bit) != 0) {
            out[lane] = applyBinaryScalar(T, a[lane], b[lane], op, lane);
        } else {
            out[lane] = if (mode == .zero) zeroValue(T) else base[lane];
        }
    }
    return fromArray(bits, T, out);
}

pub fn movMaskPS(comptime bits: usize, value: Wide(bits)) u32 {
    const lanes = comptime laneCount(bits, u32);
    const data = toArray(bits, u32, value);
    var result: u32 = 0;
    for (0..lanes) |lane| {
        if ((data[lane] & 0x80000000) != 0) result |= @as(u32, 1) << @intCast(lane);
    }
    return result;
}

pub fn movMaskPD(comptime bits: usize, value: Wide(bits)) u32 {
    const lanes = comptime laneCount(bits, u64);
    const data = toArray(bits, u64, value);
    var result: u32 = 0;
    for (0..lanes) |lane| {
        if ((data[lane] & 0x8000000000000000) != 0) result |= @as(u32, 1) << @intCast(lane);
    }
    return result;
}

pub fn duplicateOddF32(comptime bits: usize, value: Wide(bits)) Wide(bits) {
    const lanes = comptime laneCount(bits, u32);
    const src = toArray(bits, u32, value);
    var out: [lanes]u32 = undefined;
    for (0..lanes) |lane| {
        const odd_lane = (lane & ~@as(usize, 1)) + 1;
        out[lane] = src[odd_lane];
    }
    return fromArray(bits, u32, out);
}

pub fn duplicateEvenF32(comptime bits: usize, value: Wide(bits)) Wide(bits) {
    const lanes = comptime laneCount(bits, u32);
    const src = toArray(bits, u32, value);
    var out: [lanes]u32 = undefined;
    for (0..lanes) |lane| out[lane] = src[lane & ~@as(usize, 1)];
    return fromArray(bits, u32, out);
}

pub fn duplicateLowF64Per128(comptime bits: usize, value: Wide(bits)) Wide(bits) {
    const lanes = comptime laneCount(bits, u64);
    const src = toArray(bits, u64, value);
    var out: [lanes]u64 = undefined;
    for (0..lanes) |lane| out[lane] = src[(lane / 2) * 2];
    return fromArray(bits, u64, out);
}

test "CLEO wide values round-trip typed arrays" {
    const data = [_]f32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    const value = fromArray(256, f32, data);
    try std.testing.expectEqual(data, toArray(256, f32, value));
}

test "CLEO maps 1024-bit integer lanes through 128-bit-safe storage" {
    var lhs: [32]u32 = undefined;
    var rhs: [32]u32 = undefined;
    for (0..32) |i| {
        lhs[i] = @intCast(i);
        rhs[i] = 10;
    }
    const out = mapBinary(1024, u32, fromArray(1024, u32, lhs), fromArray(1024, u32, rhs), .add);
    const got = toArray(1024, u32, out);
    try std.testing.expectEqual(@as(u32, 41), got[31]);
}
