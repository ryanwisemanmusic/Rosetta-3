const svx = @import("../types.zig");

pub fn and_(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return a & b;
}

pub fn or_(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return a | b;
}

pub fn xor(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return a ^ b;
}

pub fn not(comptime T: type, a: svx.Vec(T)) svx.Vec(T) {
    return ~a;
}

pub fn bic(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return a & ~b;
}

pub fn orn(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Vec(T) {
    return a | ~b;
}

pub fn bsl(comptime T: type, mask: svx.Vec(T), if_true: svx.Vec(T), if_false: svx.Vec(T)) svx.Vec(T) {
    return (mask & if_true) | (~mask & if_false);
}

pub fn countLeadingZeros(comptime T: type, value: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = @intCast(@clz(value[lane]));
    return result;
}

pub fn countOnes(comptime T: type, value: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = @intCast(@popCount(value[lane]));
    return result;
}
