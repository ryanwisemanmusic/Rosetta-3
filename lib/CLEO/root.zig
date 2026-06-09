const std = @import("std");

pub const types = @import("types.zig");
pub const wide = @import("wide.zig");
pub const neon = @import("NEON/root.zig");
pub const cpu = @import("cpu.zig");
pub const ops = @import("ops.zig");
pub const registry = @import("registry.zig");
pub const SSE = @import("SSE/root.zig");
pub const AVX = registry.AVX;
pub const AVX2 = registry.AVX2;
pub const AVX512F = registry.AVX512F;
pub const AVX512DQ = registry.AVX512DQ;
pub const AVX512BW = registry.AVX512BW;
pub const SYSTEM = registry.SYSTEM;

pub fn validateAll() void {
    registry.validateAll() catch unreachable;
}

pub fn exerciseAll() !void {
    try registry.validateAll();
    try exerciseAvx256();
    try exerciseAvx512();
    try exerciseAvx2Moves();
    try exerciseSystemWidths();
}

fn exerciseAvx256() !void {
    const features = types.FeatureSet.cleoEmulated();
    const lhs = wide.fromArray(256, f32, .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    const rhs = wide.fromArray(256, f32, .{ 10, 20, 30, 40, 50, 60, 70, 80 });
    const add = try AVX.ADDPS.execute(256, lhs, rhs, features);
    const add_lanes = wide.toArray(256, f32, add);
    try std.testing.expectEqual(@as(f32, 11), add_lanes[0]);
    try std.testing.expectEqual(@as(f32, 88), add_lanes[7]);

    const addsub = try AVX.ADDSUBPS.execute(256, lhs, rhs, features);
    const addsub_lanes = wide.toArray(256, f32, addsub);
    try std.testing.expectEqual(@as(f32, -9), addsub_lanes[0]);
    try std.testing.expectEqual(@as(f32, 22), addsub_lanes[1]);
}

fn exerciseAvx512() !void {
    const features = types.FeatureSet.cleoEmulated();
    const lhs = wide.fromArray(512, f64, .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    const rhs = wide.fromArray(512, f64, .{ 8, 7, 6, 5, 4, 3, 2, 1 });
    const sum = try AVX512F.ADDPD.execute(512, lhs, rhs, features);
    try neon.block128.validateRoundTrip(512, sum);
    const lanes = wide.toArray(512, f64, sum);
    try std.testing.expectEqual(@as(f64, 9), lanes[0]);
    try std.testing.expectEqual(@as(f64, 9), lanes[7]);

    const merge = wide.fromArray(512, f64, .{ 100, 100, 100, 100, 100, 100, 100, 100 });
    const masked = try AVX512F.ADDPD.executeMasked(512, merge, lhs, rhs, 0b01010101, .merge, features);
    const masked_lanes = wide.toArray(512, f64, masked);
    try std.testing.expectEqual(@as(f64, 9), masked_lanes[0]);
    try std.testing.expectEqual(@as(f64, 100), masked_lanes[1]);

    const a = wide.fromArray(512, u32, .{ 0x80000000, 0, 0xFFFFFFFF, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 });
    const b = wide.fromArray(512, u32, .{ 0, 0x80000000, 1, 1, 2, 3, 4, 5, 0x80000000, 7, 8, 9, 10, 11, 12, 13 });
    const x = try AVX512DQ.XORPS.execute(512, a, b, features);
    const mask = wide.movMaskPS(512, x);
    try std.testing.expect((mask & 0b11) == 0b11);
}

fn exerciseAvx2Moves() !void {
    const features = types.FeatureSet.cleoEmulated();
    const value = wide.Wide(256).splatByte(0xA5);
    const moved = try AVX2.MOVDQU.move(256, value, features);
    try std.testing.expect(value.equal(moved));

    var aligned: [64]u8 align(64) = [_]u8{0x55} ** 64;
    const loaded = try ops.loadForInstruction(256, AVX2.MOVDQA.meta, aligned[0..], features);
    try std.testing.expectEqual(@as(u8, 0x55), loaded.bytes[0]);
}

fn exerciseSystemWidths() !void {
    const features = types.FeatureSet.cleoEmulated();
    const key = wide.Wide(256).splatByte(0xCC);
    const moved_key = try SYSTEM.LOADIWKEY.move(256, key, features);
    try std.testing.expect(key.equal(moved_key));

    const line = wide.Wide(512).splatByte(0x11);
    const copied = try SYSTEM.MOVDIR64B.move(512, line, features);
    try std.testing.expect(line.equal(copied));

    var lanes: [32]u32 = undefined;
    for (0..lanes.len) |i| lanes[i] = @intCast(i);
    const thousand_twenty_four = wide.fromArray(1024, u32, lanes);
    try neon.block128.validateRoundTrip(1024, thousand_twenty_four);
}

pub export fn cleo_host_feature_mask() u64 {
    return cpu.hostFeatureMask();
}

pub export fn cleo_emulated_feature_mask() u64 {
    return cpu.emulatedFeatureMask();
}

pub export fn cleo_wide_instruction_count() usize {
    return registry.tableCount();
}

pub export fn cleo_validate_registry() c_int {
    registry.validateAll() catch return -1;
    return 0;
}

test "CLEO root validates wide AVX lowering layer" {
    try std.testing.expectEqual(@as(usize, 58), registry.tableCount());
    validateAll();
    try exerciseAll();
}
