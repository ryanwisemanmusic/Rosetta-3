const std = @import("std");

pub const types = @import("types.zig");
pub const NEON = @import("NEON/root.zig");
pub const MVE = @import("MVE/root.zig");

pub const Predicate16 = types.Predicate16;

test "SVX root exposes MVE over NEON" {
    const a = MVE.vdupq_n_s32(100);
    const b = MVE.vdupq_n_s32(23);
    const diff = MVE.vsubq_s32(a, b);
    try std.testing.expectEqual(@as(i32, 77), types.toArray(i32, diff)[0]);
    try std.testing.expect(MVE.coverage.complete());
}
