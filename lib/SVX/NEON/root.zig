const std = @import("std");

pub const svx = @import("../types.zig");
pub const arithmetic = @import("arithmetic.zig");
pub const bitwise = @import("bitwise.zig");
pub const compare = @import("compare.zig");
pub const predicate = @import("predicate.zig");
pub const shift = @import("shift.zig");
pub const vector = @import("vector.zig");

test "NEON backend handles 16-bit saturated arithmetic and predication" {
    const a = svx.fromArray(i16, .{ 32760, -20, 40, -32768, 5, 6, 7, 8 });
    const b = svx.fromArray(i16, .{ 20, -32760, -10, -1, 5, 7, 9, 11 });
    const saturated = arithmetic.saturatingAdd(i16, a, b);
    const arr = svx.toArray(i16, saturated);
    try std.testing.expectEqual(@as(i16, 32767), arr[0]);
    try std.testing.expectEqual(@as(i16, -32768), arr[1]);
    try std.testing.expectEqual(@as(i16, 30), arr[2]);

    const mask = compare.gt(i16, a, b);
    const selected = predicate.select(i16, mask, a, b);
    const selected_arr = svx.toArray(i16, selected);
    try std.testing.expectEqual(@as(i16, 32760), selected_arr[0]);
    try std.testing.expectEqual(@as(i16, -20), selected_arr[1]);
    try std.testing.expectEqual(@as(i16, 40), selected_arr[2]);
}

test "NEON backend handles 32-bit load gather shift and reduction semantics" {
    const raw = [_]u32{ 3, 8, 13, 21, 34, 55, 89, 144 };
    const gathered = vector.gather(u32, &raw, .{ 6, 4, 2, 0 });
    const shifted = shift.shl(u32, gathered, 1);
    const shifted_arr = svx.toArray(u32, shifted);
    try std.testing.expectEqual(@as(u32, 178), shifted_arr[0]);
    try std.testing.expectEqual(@as(u32, 68), shifted_arr[1]);
    try std.testing.expectEqual(@as(u32, 26), shifted_arr[2]);
    try std.testing.expectEqual(@as(u32, 6), shifted_arr[3]);
    try std.testing.expectEqual(@as(u64, 278), arithmetic.reduceAdd(u32, shifted));
}
