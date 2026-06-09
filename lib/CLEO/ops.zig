const types = @import("types.zig");
const wide = @import("wide.zig");

pub fn executeBinary(comptime bits: usize, meta: types.InstructionMeta, lhs: wide.Wide(bits), rhs: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    try types.validateMeta(meta);
    try types.requireFeature(meta, features);
    try types.requireWidth(meta, bits);
    return switch (meta.operation) {
        .add_ps => wide.mapBinary(bits, f32, lhs, rhs, .add),
        .add_pd => wide.mapBinary(bits, f64, lhs, rhs, .add),
        .sub_ps => wide.mapBinary(bits, f32, lhs, rhs, .sub),
        .sub_pd => wide.mapBinary(bits, f64, lhs, rhs, .sub),
        .mul_ps => wide.mapBinary(bits, f32, lhs, rhs, .mul),
        .mul_pd => wide.mapBinary(bits, f64, lhs, rhs, .mul),
        .div_ps => wide.mapBinary(bits, f32, lhs, rhs, .div),
        .div_pd => wide.mapBinary(bits, f64, lhs, rhs, .div),
        .addsub_ps => wide.mapBinary(bits, f32, lhs, rhs, .addsub),
        .addsub_pd => wide.mapBinary(bits, f64, lhs, rhs, .addsub),
        .or_ps => wide.mapBinary(bits, u32, lhs, rhs, .bit_or),
        .or_pd => wide.mapBinary(bits, u64, lhs, rhs, .bit_or),
        .xor_ps => wide.mapBinary(bits, u32, lhs, rhs, .bit_xor),
        .xor_pd => wide.mapBinary(bits, u64, lhs, rhs, .bit_xor),
        .and_ps => wide.mapBinary(bits, u32, lhs, rhs, .bit_and),
        .and_pd => wide.mapBinary(bits, u64, lhs, rhs, .bit_and),
        .andn_ps => wide.mapBinary(bits, u32, lhs, rhs, .bit_andnot),
        .andn_pd => wide.mapBinary(bits, u64, lhs, rhs, .bit_andnot),
        .cmp_ps => wide.mapBinary(bits, f32, lhs, rhs, .cmp),
        .cmp_pd => wide.mapBinary(bits, f64, lhs, rhs, .cmp),
        else => types.SafetyError.UnsupportedInstructionWidth,
    };
}

pub fn executeBinaryMasked(comptime bits: usize, meta: types.InstructionMeta, merge: wide.Wide(bits), lhs: wide.Wide(bits), rhs: wide.Wide(bits), mask: u64, mode: wide.MaskMode, features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    try types.validateMeta(meta);
    try types.requireFeature(meta, features);
    try types.requireWidth(meta, bits);
    if (!meta.supports_masking) return types.SafetyError.UnsupportedInstructionWidth;
    return switch (meta.operation) {
        .add_ps => wide.mapBinaryMasked(bits, f32, merge, lhs, rhs, mask, mode, .add),
        .add_pd => wide.mapBinaryMasked(bits, f64, merge, lhs, rhs, mask, mode, .add),
        .sub_ps => wide.mapBinaryMasked(bits, f32, merge, lhs, rhs, mask, mode, .sub),
        .sub_pd => wide.mapBinaryMasked(bits, f64, merge, lhs, rhs, mask, mode, .sub),
        .mul_ps => wide.mapBinaryMasked(bits, f32, merge, lhs, rhs, mask, mode, .mul),
        .mul_pd => wide.mapBinaryMasked(bits, f64, merge, lhs, rhs, mask, mode, .mul),
        .div_ps => wide.mapBinaryMasked(bits, f32, merge, lhs, rhs, mask, mode, .div),
        .div_pd => wide.mapBinaryMasked(bits, f64, merge, lhs, rhs, mask, mode, .div),
        .or_ps => wide.mapBinaryMasked(bits, u32, merge, lhs, rhs, mask, mode, .bit_or),
        .or_pd => wide.mapBinaryMasked(bits, u64, merge, lhs, rhs, mask, mode, .bit_or),
        .xor_ps => wide.mapBinaryMasked(bits, u32, merge, lhs, rhs, mask, mode, .bit_xor),
        .xor_pd => wide.mapBinaryMasked(bits, u64, merge, lhs, rhs, mask, mode, .bit_xor),
        .and_ps => wide.mapBinaryMasked(bits, u32, merge, lhs, rhs, mask, mode, .bit_and),
        .and_pd => wide.mapBinaryMasked(bits, u64, merge, lhs, rhs, mask, mode, .bit_and),
        .andn_ps => wide.mapBinaryMasked(bits, u32, merge, lhs, rhs, mask, mode, .bit_andnot),
        .andn_pd => wide.mapBinaryMasked(bits, u64, merge, lhs, rhs, mask, mode, .bit_andnot),
        .cmp_ps => wide.mapBinaryMasked(bits, f32, merge, lhs, rhs, mask, mode, .cmp),
        .cmp_pd => wide.mapBinaryMasked(bits, f64, merge, lhs, rhs, mask, mode, .cmp),
        else => types.SafetyError.UnsupportedInstructionWidth,
    };
}

pub fn executeMove(comptime bits: usize, meta: types.InstructionMeta, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    try types.validateMeta(meta);
    try types.requireFeature(meta, features);
    try types.requireWidth(meta, bits);
    return switch (meta.operation) {
        .move, .aligned_move, .unaligned_move, .non_temporal_move, .system_512, .key_256 => value,
        .duplicate_odd_ps => wide.duplicateOddF32(bits, value),
        .duplicate_even_ps => wide.duplicateEvenF32(bits, value),
        .duplicate_low_pd => wide.duplicateLowF64Per128(bits, value),
        else => types.SafetyError.UnsupportedInstructionWidth,
    };
}

pub fn executeMovMask(comptime bits: usize, meta: types.InstructionMeta, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!u32 {
    try types.validateMeta(meta);
    try types.requireFeature(meta, features);
    try types.requireWidth(meta, bits);
    return switch (meta.operation) {
        .movemask_ps => wide.movMaskPS(bits, value),
        .movemask_pd => wide.movMaskPD(bits, value),
        else => types.SafetyError.UnsupportedInstructionWidth,
    };
}

pub fn loadForInstruction(comptime bits: usize, meta: types.InstructionMeta, src: []const u8, features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    try types.validateMeta(meta);
    try types.requireFeature(meta, features);
    try types.requireWidth(meta, bits);
    return wide.loadBytesAligned(bits, src, meta.alignment);
}

pub fn storeForInstruction(comptime bits: usize, meta: types.InstructionMeta, dst: []u8, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!void {
    try types.validateMeta(meta);
    try types.requireFeature(meta, features);
    try types.requireWidth(meta, bits);
    try wide.storeBytesAligned(bits, dst, value, meta.alignment);
}
