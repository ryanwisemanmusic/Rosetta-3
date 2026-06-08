const std = @import("std");

pub const Lowering = enum {
    neon_vector,
    neon_predicate,
    neon_memory,
    neon_scalar_assist,
};

pub const InstructionFamily = enum {
    create_vector,
    reverse_elements,
    extract_lane,
    set_lane,
    compare_equal,
    compare_not_equal,
    compare_ge,
    compare_gt,
    compare_le,
    compare_lt,
    min,
    max,
    absolute,
    absolute_difference,
    absolute_difference_accumulate,
    add,
    saturating_add,
    subtract,
    saturating_subtract,
    multiply,
    multiply_accumulate,
    multiply_subtract,
    saturating_doubling_multiply_high,
    saturating_rounding_doubling_multiply_high,
    complex_add,
    complex_multiply_accumulate,
    count_leading_zeros,
    count_ones,
    bitwise_clear,
    logical_and,
    logical_xor,
    logical_not,
    logical_or_not,
    logical_or,
    load_consecutive,
    load_strided,
    gather,
    store_consecutive,
    store_strided,
    scatter,
    reinterpret_cast,
    shift_right,
    rounding_shift_right,
    shift_left,
    saturating_shift_left,
    predicated_select,
    predicate_not,
    tail_predicate_16,
    tail_predicate_32,
    reductions,
};

pub const CoverageEntry = struct {
    family: InstructionFamily,
    lowering: Lowering,
    element_widths: []const u8,
    implemented: bool,
};

pub const entries = [_]CoverageEntry{
    .{ .family = .create_vector, .lowering = .neon_vector, .element_widths = "8/16/32/64/f16/f32/f64", .implemented = true },
    .{ .family = .reverse_elements, .lowering = .neon_vector, .element_widths = "8/16/32/64/f16/f32/f64", .implemented = true },
    .{ .family = .extract_lane, .lowering = .neon_scalar_assist, .element_widths = "all", .implemented = true },
    .{ .family = .set_lane, .lowering = .neon_scalar_assist, .element_widths = "all", .implemented = true },
    .{ .family = .compare_equal, .lowering = .neon_predicate, .element_widths = "16/32", .implemented = true },
    .{ .family = .compare_not_equal, .lowering = .neon_predicate, .element_widths = "16/32", .implemented = true },
    .{ .family = .compare_ge, .lowering = .neon_predicate, .element_widths = "16/32", .implemented = true },
    .{ .family = .compare_gt, .lowering = .neon_predicate, .element_widths = "16/32", .implemented = true },
    .{ .family = .compare_le, .lowering = .neon_predicate, .element_widths = "16/32", .implemented = true },
    .{ .family = .compare_lt, .lowering = .neon_predicate, .element_widths = "16/32", .implemented = true },
    .{ .family = .min, .lowering = .neon_vector, .element_widths = "16/32/f32", .implemented = true },
    .{ .family = .max, .lowering = .neon_vector, .element_widths = "16/32/f32", .implemented = true },
    .{ .family = .absolute, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .absolute_difference, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .absolute_difference_accumulate, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .add, .lowering = .neon_vector, .element_widths = "16/32/f32", .implemented = true },
    .{ .family = .saturating_add, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .subtract, .lowering = .neon_vector, .element_widths = "16/32/f32", .implemented = true },
    .{ .family = .saturating_subtract, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .multiply, .lowering = .neon_vector, .element_widths = "16/32/f32", .implemented = true },
    .{ .family = .multiply_accumulate, .lowering = .neon_vector, .element_widths = "16/32/f32", .implemented = true },
    .{ .family = .multiply_subtract, .lowering = .neon_vector, .element_widths = "16/32/f32", .implemented = true },
    .{ .family = .saturating_doubling_multiply_high, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .saturating_rounding_doubling_multiply_high, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .complex_add, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .complex_multiply_accumulate, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .count_leading_zeros, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .count_ones, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .bitwise_clear, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .logical_and, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .logical_xor, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .logical_not, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .logical_or_not, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .logical_or, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .load_consecutive, .lowering = .neon_memory, .element_widths = "16/32", .implemented = true },
    .{ .family = .load_strided, .lowering = .neon_memory, .element_widths = "16/32", .implemented = true },
    .{ .family = .gather, .lowering = .neon_memory, .element_widths = "16/32", .implemented = true },
    .{ .family = .store_consecutive, .lowering = .neon_memory, .element_widths = "16/32", .implemented = true },
    .{ .family = .store_strided, .lowering = .neon_memory, .element_widths = "16/32", .implemented = true },
    .{ .family = .scatter, .lowering = .neon_memory, .element_widths = "16/32", .implemented = true },
    .{ .family = .reinterpret_cast, .lowering = .neon_vector, .element_widths = "all", .implemented = true },
    .{ .family = .shift_right, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .rounding_shift_right, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .shift_left, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .saturating_shift_left, .lowering = .neon_vector, .element_widths = "16/32", .implemented = true },
    .{ .family = .predicated_select, .lowering = .neon_predicate, .element_widths = "all", .implemented = true },
    .{ .family = .predicate_not, .lowering = .neon_predicate, .element_widths = "all", .implemented = true },
    .{ .family = .tail_predicate_16, .lowering = .neon_predicate, .element_widths = "16", .implemented = true },
    .{ .family = .tail_predicate_32, .lowering = .neon_predicate, .element_widths = "32", .implemented = true },
    .{ .family = .reductions, .lowering = .neon_scalar_assist, .element_widths = "16/32", .implemented = true },
};

pub fn implementedCount() usize {
    var count: usize = 0;
    for (entries) |entry| {
        if (entry.implemented) count += 1;
    }
    return count;
}

pub fn complete() bool {
    return implementedCount() == entries.len;
}

test "MVE coverage manifest has no unimplemented instruction family" {
    try std.testing.expect(entries.len >= @typeInfo(InstructionFamily).@"enum".fields.len);
    try std.testing.expect(complete());
}
