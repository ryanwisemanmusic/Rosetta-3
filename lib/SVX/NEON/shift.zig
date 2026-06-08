const std = @import("std");
const svx = @import("../types.zig");

fn shlScalar(comptime T: type, value: T, amount: usize) T {
    const bits = @bitSizeOf(T);
    if (amount >= bits) return 0;
    const U = svx.Unsigned(T);
    const S = std.math.Log2Int(U);
    const shifted = @as(U, @bitCast(value)) << @as(S, @intCast(amount));
    return @bitCast(shifted);
}

fn shrScalar(comptime T: type, value: T, amount: usize) T {
    const bits = @bitSizeOf(T);
    if (amount >= bits) return 0;
    const U = svx.Unsigned(T);
    const S = std.math.Log2Int(U);
    const shifted = @as(U, @bitCast(value)) >> @as(S, @intCast(amount));
    return @bitCast(shifted);
}

fn sarScalar(comptime T: type, value: T, amount: usize) T {
    const bits = @bitSizeOf(T);
    if (amount >= bits) {
        return if ((comptime svx.isSignedInt(T)) and value < 0) -1 else 0;
    }
    const S = std.math.Log2Int(svx.Unsigned(T));
    return value >> @as(S, @intCast(amount));
}

fn satShlScalar(comptime T: type, value: T, amount: usize) T {
    if (amount >= @bitSizeOf(T)) {
        if (value == 0) return 0;
        return if ((comptime svx.isSignedInt(T)) and value < 0) std.math.minInt(T) else std.math.maxInt(T);
    }
    if (comptime svx.isSignedInt(T)) {
        const W = svx.WideSigned(T);
        const result = @as(W, value) << @intCast(amount);
        const hi = @as(W, std.math.maxInt(T));
        const lo = @as(W, std.math.minInt(T));
        if (result > hi) return std.math.maxInt(T);
        if (result < lo) return std.math.minInt(T);
        return @intCast(result);
    }
    const W = svx.WideUnsigned(T);
    const result = @as(W, value) << @intCast(amount);
    const hi = @as(W, std.math.maxInt(T));
    if (result > hi) return std.math.maxInt(T);
    return @intCast(result);
}

pub fn shl(comptime T: type, value: svx.Vec(T), amount: usize) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = shlScalar(T, value[lane], amount);
    return result;
}

pub fn shr(comptime T: type, value: svx.Vec(T), amount: usize) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = shrScalar(T, value[lane], amount);
    return result;
}

pub fn sar(comptime T: type, value: svx.Vec(T), amount: usize) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = sarScalar(T, value[lane], amount);
    return result;
}

pub fn saturatingShl(comptime T: type, value: svx.Vec(T), amount: usize) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = satShlScalar(T, value[lane], amount);
    return result;
}

pub fn roundingShr(comptime T: type, value: svx.Vec(T), amount: usize) svx.Vec(T) {
    if (amount == 0) return value;
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        const addend = shlScalar(T, 1, amount - 1);
        result[lane] = shrScalar(T, value[lane] +% addend, amount);
    }
    return result;
}
