const types = @import("types.zig");
const ops = @import("ops.zig");
const wide = @import("wide.zig");

pub fn safety(meta: types.InstructionMeta, features: types.FeatureSet) types.SafetyReport {
    return types.safetyReport(meta, features);
}

pub fn validate(meta: types.InstructionMeta) types.SafetyError!void {
    try types.validateMeta(meta);
}

pub fn binary(comptime bits: usize, meta: types.InstructionMeta, lhs: wide.Wide(bits), rhs: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeBinary(bits, meta, lhs, rhs, features);
}

pub fn binaryMasked(comptime bits: usize, meta: types.InstructionMeta, merge: wide.Wide(bits), lhs: wide.Wide(bits), rhs: wide.Wide(bits), mask: u64, mode: wide.MaskMode, features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeBinaryMasked(bits, meta, merge, lhs, rhs, mask, mode, features);
}

pub fn move(comptime bits: usize, meta: types.InstructionMeta, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeMove(bits, meta, value, features);
}

pub fn movMask(comptime bits: usize, meta: types.InstructionMeta, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!u32 {
    return ops.executeMovMask(bits, meta, value, features);
}
