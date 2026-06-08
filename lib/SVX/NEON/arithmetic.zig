const std = @import("std");
const svx = @import("../types.zig");

fn satAddScalar(comptime T: type, a: T, b: T) T {
    if (comptime svx.isSignedInt(T)) {
        const W = svx.WideSigned(T);
        const result = @as(W, a) + @as(W, b);
        const hi = @as(W, std.math.maxInt(T));
        const lo = @as(W, std.math.minInt(T));
        if (result > hi) return std.math.maxInt(T);
        if (result < lo) return std.math.minInt(T);
        return @intCast(result);
    }
    const W = svx.WideUnsigned(T);
    const result = @as(W, a) + @as(W, b);
    const hi = @as(W, std.math.maxInt(T));
    if (result > hi) return std.math.maxInt(T);
    return @intCast(result);
}

fn satSubScalar(comptime T: type, a: T, b: T) T {
    if (comptime svx.isSignedInt(T)) {
        const W = svx.WideSigned(T);
        const result = @as(W, a) - @as(W, b);
        const hi = @as(W, std.math.maxInt(T));
        const lo = @as(W, std.math.minInt(T));
        if (result > hi) return std.math.maxInt(T);
        if (result < lo) return std.math.minInt(T);
        return @intCast(result);
    }
    if (a < b) return 0;
    return a - b;
}

fn satCastScalar(comptime Dst: type, value: anytype) Dst {
    const W = @TypeOf(value);
    const hi = @as(W, std.math.maxInt(Dst));
    const lo = @as(W, std.math.minInt(Dst));
    if (value > hi) return std.math.maxInt(Dst);
    if (value < lo) return std.math.minInt(Dst);
    return @intCast(value);
}

pub fn add(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    if (comptime svx.isFloat(T)) return a + b;
    return a +% b;
}

pub fn sub(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    if (comptime svx.isFloat(T)) return a - b;
    return a -% b;
}

pub fn mul(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    if (comptime svx.isFloat(T)) return a * b;
    return a *% b;
}

pub fn mla(comptime T: type, acc: svx.Vec(T), a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return add(T, acc, mul(T, a, b));
}

pub fn mls(comptime T: type, acc: svx.Vec(T), a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return sub(T, acc, mul(T, a, b));
}

pub fn saturatingAdd(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = satAddScalar(T, a[lane], b[lane]);
    return result;
}

pub fn saturatingSub(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = satSubScalar(T, a[lane], b[lane]);
    return result;
}

pub fn abs(comptime T: type, a: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    if (comptime !svx.isSignedInt(T)) return a;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        if (a[lane] == std.math.minInt(T)) {
            result[lane] = std.math.maxInt(T);
        } else if (a[lane] < 0) {
            result[lane] = -a[lane];
        } else {
            result[lane] = a[lane];
        }
    }
    return result;
}

pub fn neg(comptime T: type, a: svx.Vec(T)) svx.Vec(T) {
    if (comptime svx.isFloat(T)) return -a;
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = @as(T, 0) -% a[lane];
    return result;
}

pub fn saturatingNeg(comptime T: type, a: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        if ((comptime svx.isSignedInt(T)) and a[lane] == std.math.minInt(T)) {
            result[lane] = std.math.maxInt(T);
        } else {
            result[lane] = @as(T, 0) - a[lane];
        }
    }
    return result;
}

pub fn min(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = @min(a[lane], b[lane]);
    return result;
}

pub fn max(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = @max(a[lane], b[lane]);
    return result;
}

pub fn absDiff(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        result[lane] = if (a[lane] >= b[lane]) a[lane] - b[lane] else b[lane] - a[lane];
    }
    return result;
}

pub fn absDiffAcc(comptime T: type, acc: svx.Vec(T), a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return add(T, acc, absDiff(T, a, b));
}

pub fn qdmulh(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    if (comptime !svx.isSignedInt(T)) @compileError("qdmulh requires signed integer lanes");
    const W = svx.WideSigned(T);
    const shift = @bitSizeOf(T);
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        const product = @as(W, a[lane]) * @as(W, b[lane]) * 2;
        result[lane] = satCastScalar(T, product >> shift);
    }
    return result;
}

pub fn qrdmulh(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    if (comptime !svx.isSignedInt(T)) @compileError("qrdmulh requires signed integer lanes");
    const W = svx.WideSigned(T);
    const shift = @bitSizeOf(T);
    const rounding = @as(W, 1) << @intCast(shift - 1);
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        const product = @as(W, a[lane]) * @as(W, b[lane]) * 2;
        result[lane] = satCastScalar(T, (product + rounding) >> shift);
    }
    return result;
}

pub fn reduceAdd(comptime T: type, value: svx.Vec(T)) svx.Accumulator(T) {
    const W = svx.Accumulator(T);
    var total: W = 0;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| total += @as(W, value[lane]);
    return total;
}

pub fn reduceMin(comptime T: type, value: svx.Vec(T)) T {
    var result = value[0];
    const lane_count = comptime svx.lanesFor(T);
    inline for (1..lane_count) |lane| result = @min(result, value[lane]);
    return result;
}

pub fn reduceMax(comptime T: type, value: svx.Vec(T)) T {
    var result = value[0];
    const lane_count = comptime svx.lanesFor(T);
    inline for (1..lane_count) |lane| result = @max(result, value[lane]);
    return result;
}
