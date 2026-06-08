const std = @import("std");
const svx = @import("../types.zig");
const pred = @import("predicate.zig");

pub fn zero(comptime T: type) svx.Vec(T) {
    return @splat(@as(T, 0));
}

pub fn dup(comptime T: type, value: T) svx.Vec(T) {
    return @splat(value);
}

pub fn load(comptime T: type, src: []const T) svx.Vec(T) {
    std.debug.assert(src.len >= svx.lanesFor(T));
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = src[lane];
    return result;
}

pub fn loadPredicated(comptime T: type, inactive: svx.Vec(T), src: []const T, predicate: svx.Predicate16) svx.Vec(T) {
    std.debug.assert(src.len >= svx.lanesFor(T));
    var result = inactive;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        if (predicate.active(lane)) result[lane] = src[lane];
    }
    return result;
}

pub fn store(comptime T: type, dst: []T, value: svx.Vec(T)) void {
    std.debug.assert(dst.len >= svx.lanesFor(T));
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| dst[lane] = value[lane];
}

pub fn storePredicated(comptime T: type, dst: []T, value: svx.Vec(T), predicate: svx.Predicate16) void {
    std.debug.assert(dst.len >= svx.lanesFor(T));
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        if (predicate.active(lane)) dst[lane] = value[lane];
    }
}

pub fn loadStrided(comptime T: type, src: []const T, stride: usize) svx.Vec(T) {
    std.debug.assert(stride > 0);
    std.debug.assert(src.len >= (svx.lanesFor(T) - 1) * stride + 1);
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = src[lane * stride];
    return result;
}

pub fn storeStrided(comptime T: type, dst: []T, stride: usize, value: svx.Vec(T)) void {
    std.debug.assert(stride > 0);
    std.debug.assert(dst.len >= (svx.lanesFor(T) - 1) * stride + 1);
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| dst[lane * stride] = value[lane];
}

pub fn gather(comptime T: type, base: []const T, offsets: [svx.lanesFor(T)]usize) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        std.debug.assert(offsets[lane] < base.len);
        result[lane] = base[offsets[lane]];
    }
    return result;
}

pub fn scatter(comptime T: type, base: []T, offsets: [svx.lanesFor(T)]usize, value: svx.Vec(T)) void {
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        std.debug.assert(offsets[lane] < base.len);
        base[offsets[lane]] = value[lane];
    }
}

pub fn reverse(comptime T: type, value: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lanes = comptime svx.lanesFor(T);
    inline for (0..lanes) |lane| result[lane] = value[lanes - 1 - lane];
    return result;
}

pub fn getLane(comptime T: type, value: svx.Vec(T), lane: usize) T {
    std.debug.assert(lane < svx.lanesFor(T));
    const array = svx.toArray(T, value);
    return array[lane];
}

pub fn setLane(comptime T: type, value: svx.Vec(T), lane: usize, element: T) svx.Vec(T) {
    std.debug.assert(lane < svx.lanesFor(T));
    var array = svx.toArray(T, value);
    array[lane] = element;
    return svx.fromArray(T, array);
}

pub fn reinterpret(comptime To: type, comptime From: type, value: svx.Vec(From)) svx.Vec(To) {
    if (@sizeOf(svx.Vec(To)) != @sizeOf(svx.Vec(From))) {
        @compileError("SVX reinterpret requires equal vector sizes");
    }
    return @bitCast(value);
}

pub fn predicatedMove(comptime T: type, inactive: svx.Vec(T), active: svx.Vec(T), predicate: svx.Predicate16) svx.Vec(T) {
    return pred.merge(T, inactive, active, predicate);
}
