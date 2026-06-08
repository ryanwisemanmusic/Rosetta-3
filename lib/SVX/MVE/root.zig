const std = @import("std");
const neon = @import("../NEON/root.zig");
const svx = @import("../types.zig");

pub const coverage = @import("coverage.zig");

pub const mve_pred16_t = svx.Predicate16;
pub const int16x8_t = svx.i16x8;
pub const uint16x8_t = svx.u16x8;
pub const int32x4_t = svx.i32x4;
pub const uint32x4_t = svx.u32x4;
pub const float32x4_t = svx.f32x4;

pub fn vctp16q(remaining: usize) mve_pred16_t {
    return neon.predicate.vctp16q(remaining);
}

pub fn vctp32q(remaining: usize) mve_pred16_t {
    return neon.predicate.vctp32q(remaining);
}

pub fn vpnot(predicate: mve_pred16_t) mve_pred16_t {
    return neon.predicate.not(predicate);
}

pub fn vpselq_s16(a: int16x8_t, b: int16x8_t, predicate: mve_pred16_t) int16x8_t {
    return neon.predicate.select(i16, predicate, a, b);
}

pub fn vpselq_u16(a: uint16x8_t, b: uint16x8_t, predicate: mve_pred16_t) uint16x8_t {
    return neon.predicate.select(u16, predicate, a, b);
}

pub fn vpselq_s32(a: int32x4_t, b: int32x4_t, predicate: mve_pred16_t) int32x4_t {
    return neon.predicate.select(i32, predicate, a, b);
}

pub fn vpselq_u32(a: uint32x4_t, b: uint32x4_t, predicate: mve_pred16_t) uint32x4_t {
    return neon.predicate.select(u32, predicate, a, b);
}

pub fn vdupq_n_s16(value: i16) int16x8_t {
    return neon.vector.dup(i16, value);
}

pub fn vdupq_n_u16(value: u16) uint16x8_t {
    return neon.vector.dup(u16, value);
}

pub fn vdupq_n_s32(value: i32) int32x4_t {
    return neon.vector.dup(i32, value);
}

pub fn vdupq_n_u32(value: u32) uint32x4_t {
    return neon.vector.dup(u32, value);
}

pub fn vld1q_s16(src: []const i16) int16x8_t {
    return neon.vector.load(i16, src);
}

pub fn vld1q_u16(src: []const u16) uint16x8_t {
    return neon.vector.load(u16, src);
}

pub fn vld1q_s32(src: []const i32) int32x4_t {
    return neon.vector.load(i32, src);
}

pub fn vld1q_u32(src: []const u32) uint32x4_t {
    return neon.vector.load(u32, src);
}

pub fn vst1q_s16(dst: []i16, value: int16x8_t) void {
    neon.vector.store(i16, dst, value);
}

pub fn vst1q_u16(dst: []u16, value: uint16x8_t) void {
    neon.vector.store(u16, dst, value);
}

pub fn vst1q_s32(dst: []i32, value: int32x4_t) void {
    neon.vector.store(i32, dst, value);
}

pub fn vst1q_u32(dst: []u32, value: uint32x4_t) void {
    neon.vector.store(u32, dst, value);
}

pub fn vldrhq_gather_offset_s16(base: []const i16, offsets: [8]usize) int16x8_t {
    return neon.vector.gather(i16, base, offsets);
}

pub fn vldrhq_gather_offset_u16(base: []const u16, offsets: [8]usize) uint16x8_t {
    return neon.vector.gather(u16, base, offsets);
}

pub fn vldrwq_gather_offset_s32(base: []const i32, offsets: [4]usize) int32x4_t {
    return neon.vector.gather(i32, base, offsets);
}

pub fn vldrwq_gather_offset_u32(base: []const u32, offsets: [4]usize) uint32x4_t {
    return neon.vector.gather(u32, base, offsets);
}

pub fn vstrhq_scatter_offset_s16(base: []i16, offsets: [8]usize, value: int16x8_t) void {
    neon.vector.scatter(i16, base, offsets, value);
}

pub fn vstrwq_scatter_offset_u32(base: []u32, offsets: [4]usize, value: uint32x4_t) void {
    neon.vector.scatter(u32, base, offsets, value);
}

pub fn vrevq_s16(value: int16x8_t) int16x8_t {
    return neon.vector.reverse(i16, value);
}

pub fn vrevq_s32(value: int32x4_t) int32x4_t {
    return neon.vector.reverse(i32, value);
}

pub fn vgetq_lane_s16(value: int16x8_t, lane: usize) i16 {
    return neon.vector.getLane(i16, value, lane);
}

pub fn vsetq_lane_s16(element: i16, value: int16x8_t, lane: usize) int16x8_t {
    return neon.vector.setLane(i16, value, lane, element);
}

pub fn vreinterpretq_u16_s16(value: int16x8_t) uint16x8_t {
    return neon.vector.reinterpret(u16, i16, value);
}

pub fn vreinterpretq_s16_u16(value: uint16x8_t) int16x8_t {
    return neon.vector.reinterpret(i16, u16, value);
}

pub fn vreinterpretq_u32_s32(value: int32x4_t) uint32x4_t {
    return neon.vector.reinterpret(u32, i32, value);
}

pub fn vreinterpretq_s32_u32(value: uint32x4_t) int32x4_t {
    return neon.vector.reinterpret(i32, u32, value);
}

pub fn vaddq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.add(i16, a, b);
}

pub fn vaddq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.arithmetic.add(u16, a, b);
}

pub fn vaddq_s32(a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.add(i32, a, b);
}

pub fn vaddq_u32(a: uint32x4_t, b: uint32x4_t) uint32x4_t {
    return neon.arithmetic.add(u32, a, b);
}

pub fn vaddq_m_s16(inactive: int16x8_t, a: int16x8_t, b: int16x8_t, predicate: mve_pred16_t) int16x8_t {
    return neon.predicate.merge(i16, inactive, vaddq_s16(a, b), predicate);
}

pub fn vqaddq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.saturatingAdd(i16, a, b);
}

pub fn vqaddq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.arithmetic.saturatingAdd(u16, a, b);
}

pub fn vqaddq_s32(a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.saturatingAdd(i32, a, b);
}

pub fn vqaddq_u32(a: uint32x4_t, b: uint32x4_t) uint32x4_t {
    return neon.arithmetic.saturatingAdd(u32, a, b);
}

pub fn vsubq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.sub(i16, a, b);
}

pub fn vsubq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.arithmetic.sub(u16, a, b);
}

pub fn vsubq_s32(a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.sub(i32, a, b);
}

pub fn vsubq_u32(a: uint32x4_t, b: uint32x4_t) uint32x4_t {
    return neon.arithmetic.sub(u32, a, b);
}

pub fn vqsubq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.saturatingSub(i16, a, b);
}

pub fn vqsubq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.arithmetic.saturatingSub(u16, a, b);
}

pub fn vqsubq_s32(a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.saturatingSub(i32, a, b);
}

pub fn vmulq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.mul(i16, a, b);
}

pub fn vmulq_s32(a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.mul(i32, a, b);
}

pub fn vmlaq_s16(acc: int16x8_t, a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.mla(i16, acc, a, b);
}

pub fn vmlaq_s32(acc: int32x4_t, a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.mla(i32, acc, a, b);
}

pub fn vmlsq_s16(acc: int16x8_t, a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.mls(i16, acc, a, b);
}

pub fn vmlsq_s32(acc: int32x4_t, a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.mls(i32, acc, a, b);
}

pub fn vqdmulhq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.qdmulh(i16, a, b);
}

pub fn vqdmulhq_s32(a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.qdmulh(i32, a, b);
}

pub fn vqrdmulhq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.qrdmulh(i16, a, b);
}

pub fn vqrdmulhq_s32(a: int32x4_t, b: int32x4_t) int32x4_t {
    return neon.arithmetic.qrdmulh(i32, a, b);
}

pub fn vabsq_s16(value: int16x8_t) int16x8_t {
    return neon.arithmetic.abs(i16, value);
}

pub fn vabsq_s32(value: int32x4_t) int32x4_t {
    return neon.arithmetic.abs(i32, value);
}

pub fn vnegq_s16(value: int16x8_t) int16x8_t {
    return neon.arithmetic.neg(i16, value);
}

pub fn vqnegq_s16(value: int16x8_t) int16x8_t {
    return neon.arithmetic.saturatingNeg(i16, value);
}

pub fn vabdq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.absDiff(i16, a, b);
}

pub fn vabaq_s16(acc: int16x8_t, a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.absDiffAcc(i16, acc, a, b);
}

pub fn vmaxq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.max(i16, a, b);
}

pub fn vminq_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    return neon.arithmetic.min(i16, a, b);
}

pub fn vandq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.bitwise.and_(u16, a, b);
}

pub fn vorrq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.bitwise.or_(u16, a, b);
}

pub fn veorq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.bitwise.xor(u16, a, b);
}

pub fn vbicq_u16(a: uint16x8_t, b: uint16x8_t) uint16x8_t {
    return neon.bitwise.bic(u16, a, b);
}

pub fn vmvnq_u16(a: uint16x8_t) uint16x8_t {
    return neon.bitwise.not(u16, a);
}

pub fn vclzq_u32(a: uint32x4_t) uint32x4_t {
    return neon.bitwise.countLeadingZeros(u32, a);
}

pub fn vcntq_u16(a: uint16x8_t) uint16x8_t {
    return neon.bitwise.countOnes(u16, a);
}

pub fn vshlq_n_s16(a: int16x8_t, amount: usize) int16x8_t {
    return neon.shift.shl(i16, a, amount);
}

pub fn vshrq_n_u16(a: uint16x8_t, amount: usize) uint16x8_t {
    return neon.shift.shr(u16, a, amount);
}

pub fn vshrq_n_s32(a: int32x4_t, amount: usize) int32x4_t {
    return neon.shift.sar(i32, a, amount);
}

pub fn vrshrq_n_u16(a: uint16x8_t, amount: usize) uint16x8_t {
    return neon.shift.roundingShr(u16, a, amount);
}

pub fn vqshlq_n_s16(a: int16x8_t, amount: usize) int16x8_t {
    return neon.shift.saturatingShl(i16, a, amount);
}

pub fn vceqq_s16(a: int16x8_t, b: int16x8_t) mve_pred16_t {
    return neon.compare.eq(i16, a, b);
}

pub fn vcgtq_s16(a: int16x8_t, b: int16x8_t) mve_pred16_t {
    return neon.compare.gt(i16, a, b);
}

pub fn vcgeq_s16(a: int16x8_t, b: int16x8_t) mve_pred16_t {
    return neon.compare.ge(i16, a, b);
}

pub fn vcltq_s16(a: int16x8_t, b: int16x8_t) mve_pred16_t {
    return neon.compare.lt(i16, a, b);
}

pub fn vcleq_s16(a: int16x8_t, b: int16x8_t) mve_pred16_t {
    return neon.compare.le(i16, a, b);
}

pub fn vaddvq_s16(value: int16x8_t) i32 {
    return neon.arithmetic.reduceAdd(i16, value);
}

pub fn vaddvq_u32(value: uint32x4_t) u64 {
    return neon.arithmetic.reduceAdd(u32, value);
}

pub fn vmaxvq_s16(value: int16x8_t) i16 {
    return neon.arithmetic.reduceMax(i16, value);
}

pub fn vminvq_s16(value: int16x8_t) i16 {
    return neon.arithmetic.reduceMin(i16, value);
}

pub fn vcaddq_rot90_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    var result: int16x8_t = undefined;
    inline for (0..4) |pair| {
        const lane = pair * 2;
        result[lane] = a[lane] -% b[lane + 1];
        result[lane + 1] = a[lane + 1] +% b[lane];
    }
    return result;
}

pub fn vcaddq_rot270_s16(a: int16x8_t, b: int16x8_t) int16x8_t {
    var result: int16x8_t = undefined;
    inline for (0..4) |pair| {
        const lane = pair * 2;
        result[lane] = a[lane] +% b[lane + 1];
        result[lane + 1] = a[lane + 1] -% b[lane];
    }
    return result;
}

pub fn vcmlaq_rot0_s16(acc: int16x8_t, a: int16x8_t, b: int16x8_t) int16x8_t {
    var result = acc;
    inline for (0..4) |pair| {
        const lane = pair * 2;
        const ar = a[lane];
        const ai = a[lane + 1];
        const br = b[lane];
        const bi = b[lane + 1];
        result[lane] +%= ar *% br -% ai *% bi;
        result[lane + 1] +%= ar *% bi +% ai *% br;
    }
    return result;
}

test "MVE facade maps 16-bit arithmetic and tail predication through NEON" {
    const sat_a = svx.fromArray(i16, .{ 32760, 4, 6, 8, 10, 12, 14, 16 });
    const a = svx.fromArray(i16, .{ 100, 4, 6, 8, 10, 12, 14, 16 });
    const b = svx.fromArray(i16, .{ 20, 3, 5, 7, 9, 11, 13, 15 });
    const added = vqaddq_s16(sat_a, b);
    try std.testing.expectEqual(@as(i16, 32767), svx.toArray(i16, added)[0]);

    const inactive = vdupq_n_s16(-1);
    const pred = vctp16q(3);
    const merged = vaddq_m_s16(inactive, a, b, pred);
    const arr = svx.toArray(i16, merged);
    try std.testing.expectEqual(@as(i16, 120), arr[0]);
    try std.testing.expectEqual(@as(i16, 7), arr[1]);
    try std.testing.expectEqual(@as(i16, 11), arr[2]);
    try std.testing.expectEqual(@as(i16, -1), arr[3]);
}

test "MVE facade maps gather scatter compare reductions and complex pairs" {
    const memory = [_]u32{ 1, 2, 4, 8, 16, 32, 64, 128 };
    const gathered = vldrwq_gather_offset_u32(&memory, .{ 7, 5, 3, 1 });
    try std.testing.expectEqual(@as(u64, 170), vaddvq_u32(gathered));

    var out = [_]u32{0} ** 8;
    vstrwq_scatter_offset_u32(&out, .{ 0, 2, 4, 6 }, gathered);
    try std.testing.expectEqual(@as(u32, 128), out[0]);
    try std.testing.expectEqual(@as(u32, 32), out[2]);

    const a = svx.fromArray(i16, .{ 1, 2, 3, 4, -5, 6, -7, 8 });
    const b = svx.fromArray(i16, .{ 10, 20, 30, 40, 50, 60, 70, 80 });
    const complex = vcaddq_rot90_s16(a, b);
    const arr = svx.toArray(i16, complex);
    try std.testing.expectEqual(@as(i16, -19), arr[0]);
    try std.testing.expectEqual(@as(i16, 12), arr[1]);
    try std.testing.expect(vcgtq_s16(b, a).active(0));
    try std.testing.expect(coverage.complete());
}
