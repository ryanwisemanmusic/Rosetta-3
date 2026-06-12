const std = @import("std");
const types = @import("types.zig");

pub const BinaryOp = enum {
    add,
    sub,
    mul,
    div,
    bit_or,
    bit_xor,
    bit_and,
    bit_andnot,
    cmp,
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
        .bit_and => lhs & rhs,
        .bit_andnot => ~lhs & rhs,
        .cmp => blk: {
            const IntT = std.meta.Int(.unsigned, @bitSizeOf(T));
            break :blk @bitCast(if (lhs == rhs) ~@as(IntT, 0) else @as(IntT, 0));
        },
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

pub fn applyLaneMask(comptime bits: usize, comptime T: type, merge: Wide(bits), value: Wide(bits), mask: u64, mode: MaskMode) Wide(bits) {
    const lanes = comptime laneCount(bits, T);
    const base = toArray(bits, T, merge);
    const data = toArray(bits, T, value);
    var out: [lanes]T = undefined;
    for (0..lanes) |lane| {
        const bit = (@as(u64, 1) << @intCast(lane));
        out[lane] = if ((mask & bit) != 0)
            data[lane]
        else if (mode == .zero)
            zeroValue(T)
        else
            base[lane];
    }
    return fromArray(bits, T, out);
}

fn immediateBit(immediate: u8, lane: usize) bool {
    if (lane >= 8) return false;
    const shift: u3 = @intCast(lane);
    return ((immediate >> shift) & 1) != 0;
}

fn immediateTwoBits(immediate: u8, shift_bits: usize) usize {
    const shift: u3 = @intCast(shift_bits & 7);
    return @intCast((immediate >> shift) & 0x3);
}

fn signBitMask(comptime T: type) T {
    if (@typeInfo(T) != .int) @compileError("variable blend masks must use integer lane views");
    return @as(T, 1) << (@bitSizeOf(T) - 1);
}

pub fn blendImmediate(comptime bits: usize, comptime T: type, lhs: Wide(bits), rhs: Wide(bits), immediate: u8) Wide(bits) {
    const lanes = comptime laneCount(bits, T);
    const a = toArray(bits, T, lhs);
    const b = toArray(bits, T, rhs);
    var out: [lanes]T = undefined;
    for (0..lanes) |lane| out[lane] = if (immediateBit(immediate, lane)) b[lane] else a[lane];
    return fromArray(bits, T, out);
}

pub fn blendVariable(comptime bits: usize, comptime T: type, lhs: Wide(bits), rhs: Wide(bits), selector: Wide(bits)) Wide(bits) {
    const lanes = comptime laneCount(bits, T);
    const sign = comptime signBitMask(T);
    const a = toArray(bits, T, lhs);
    const b = toArray(bits, T, rhs);
    const select = toArray(bits, T, selector);
    var out: [lanes]T = undefined;
    for (0..lanes) |lane| out[lane] = if ((select[lane] & sign) != 0) b[lane] else a[lane];
    return fromArray(bits, T, out);
}

pub fn shuffleImmediatePS(comptime bits: usize, lhs: Wide(bits), rhs: Wide(bits), immediate: u8) Wide(bits) {
    const lanes = comptime laneCount(bits, u32);
    if (lanes % 4 != 0) @compileError("SHUFPS needs 128-bit groups of four f32 lanes");
    const a = toArray(bits, u32, lhs);
    const b = toArray(bits, u32, rhs);
    var out: [lanes]u32 = undefined;
    for (0..(lanes / 4)) |block| {
        const base = block * 4;
        out[base + 0] = a[base + immediateTwoBits(immediate, 0)];
        out[base + 1] = a[base + immediateTwoBits(immediate, 2)];
        out[base + 2] = b[base + immediateTwoBits(immediate, 4)];
        out[base + 3] = b[base + immediateTwoBits(immediate, 6)];
    }
    return fromArray(bits, u32, out);
}

pub fn shuffleImmediatePD(comptime bits: usize, lhs: Wide(bits), rhs: Wide(bits), immediate: u8) Wide(bits) {
    const lanes = comptime laneCount(bits, u64);
    if (lanes % 2 != 0) @compileError("SHUFPD needs 128-bit groups of two f64 lanes");
    const a = toArray(bits, u64, lhs);
    const b = toArray(bits, u64, rhs);
    var out: [lanes]u64 = undefined;
    for (0..(lanes / 2)) |pair| {
        const base = pair * 2;
        const lhs_lane: usize = if (immediateBit(immediate, pair * 2)) 1 else 0;
        const rhs_lane: usize = if (immediateBit(immediate, pair * 2 + 1)) 1 else 0;
        out[base + 0] = a[base + lhs_lane];
        out[base + 1] = b[base + rhs_lane];
    }
    return fromArray(bits, u64, out);
}

pub fn shuffleImmediatePSMasked(comptime bits: usize, merge: Wide(bits), lhs: Wide(bits), rhs: Wide(bits), immediate: u8, mask: u64, mode: MaskMode) Wide(bits) {
    const shuffled = shuffleImmediatePS(bits, lhs, rhs, immediate);
    return applyLaneMask(bits, u32, merge, shuffled, mask, mode);
}

pub fn shuffleImmediatePDMasked(comptime bits: usize, merge: Wide(bits), lhs: Wide(bits), rhs: Wide(bits), immediate: u8, mask: u64, mode: MaskMode) Wide(bits) {
    const shuffled = shuffleImmediatePD(bits, lhs, rhs, immediate);
    return applyLaneMask(bits, u64, merge, shuffled, mask, mode);
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

test "CLEO blends immediate lanes" {
    const lhs = fromArray(256, u32, .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    const rhs = fromArray(256, u32, .{ 10, 20, 30, 40, 50, 60, 70, 80 });
    const out = blendImmediate(256, u32, lhs, rhs, 0b10101010);
    try std.testing.expectEqual([_]u32{ 1, 20, 3, 40, 5, 60, 7, 80 }, toArray(256, u32, out));
}

test "CLEO blends variable lanes from mask sign bits" {
    const lhs = fromArray(256, u32, .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    const rhs = fromArray(256, u32, .{ 10, 20, 30, 40, 50, 60, 70, 80 });
    const selector = fromArray(256, u32, .{ 0x80000000, 0, 0x80000000, 0, 0, 0x80000000, 0, 0x80000000 });
    const out = blendVariable(256, u32, lhs, rhs, selector);
    try std.testing.expectEqual([_]u32{ 10, 2, 30, 4, 5, 60, 7, 80 }, toArray(256, u32, out));
}

test "CLEO shuffles packed single lanes per 128-bit block" {
    const lhs = fromArray(256, u32, .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    const rhs = fromArray(256, u32, .{ 10, 20, 30, 40, 50, 60, 70, 80 });
    const out = shuffleImmediatePS(256, lhs, rhs, 0b01_00_11_10);
    try std.testing.expectEqual([_]u32{ 3, 4, 10, 20, 7, 8, 50, 60 }, toArray(256, u32, out));
}

test "CLEO shuffles packed double lanes and applies AVX512 masks" {
    const merge = fromArray(512, u64, .{ 100, 101, 102, 103, 104, 105, 106, 107 });
    const lhs = fromArray(512, u64, .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    const rhs = fromArray(512, u64, .{ 10, 20, 30, 40, 50, 60, 70, 80 });
    const out = shuffleImmediatePDMasked(512, merge, lhs, rhs, 0b10_01_10_01, 0b01010101, .merge);
    try std.testing.expectEqual([_]u64{ 2, 101, 3, 103, 6, 105, 7, 107 }, toArray(512, u64, out));
}
