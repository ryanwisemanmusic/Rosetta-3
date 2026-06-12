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

pub fn binaryImmediate(comptime bits: usize, meta: types.InstructionMeta, lhs: wide.Wide(bits), rhs: wide.Wide(bits), immediate: u8, features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeBinaryImmediate(bits, meta, lhs, rhs, immediate, features);
}

pub fn blendVariable(comptime bits: usize, meta: types.InstructionMeta, lhs: wide.Wide(bits), rhs: wide.Wide(bits), selector: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeBlendVariable(bits, meta, lhs, rhs, selector, features);
}

pub fn binaryMasked(comptime bits: usize, meta: types.InstructionMeta, merge: wide.Wide(bits), lhs: wide.Wide(bits), rhs: wide.Wide(bits), mask: u64, mode: wide.MaskMode, features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeBinaryMasked(bits, meta, merge, lhs, rhs, mask, mode, features);
}

pub fn binaryMaskedImmediate(comptime bits: usize, meta: types.InstructionMeta, merge: wide.Wide(bits), lhs: wide.Wide(bits), rhs: wide.Wide(bits), immediate: u8, mask: u64, mode: wide.MaskMode, features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeBinaryMaskedImmediate(bits, meta, merge, lhs, rhs, immediate, mask, mode, features);
}

pub fn move(comptime bits: usize, meta: types.InstructionMeta, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return ops.executeMove(bits, meta, value, features);
}

pub fn movMask(comptime bits: usize, meta: types.InstructionMeta, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!u32 {
    return ops.executeMovMask(bits, meta, value, features);
}
