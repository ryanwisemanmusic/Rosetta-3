const types = @import("../types.zig");
const instruction = @import("../instruction.zig");
const wide = @import("../wide.zig");

pub const meta = types.InstructionMeta{
    .name = "VMOVDQU16",
    .family = "MOV",
    .source_path = "ISA/x86/MOV/VMOVDQU16.inc",
    .required_feature = .avx512bw,
    .max_width_bits = 512,
    .element_bits = 16,
    .operation = .unaligned_move,
    .alignment = .any,
    .supports_masking = true,
    .supports_broadcast = false,
};

pub fn plan() types.LoweringPlan {
    return meta.plan();
}

pub fn safety(features: types.FeatureSet) types.SafetyReport {
    return instruction.safety(meta, features);
}

pub fn validate() types.SafetyError!void {
    try instruction.validate(meta);
}

pub fn execute(comptime bits: usize, lhs: wide.Wide(bits), rhs: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return instruction.binary(bits, meta, lhs, rhs, features);
}

pub fn executeMasked(comptime bits: usize, merge: wide.Wide(bits), lhs: wide.Wide(bits), rhs: wide.Wide(bits), mask: u64, mode: wide.MaskMode, features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return instruction.binaryMasked(bits, meta, merge, lhs, rhs, mask, mode, features);
}

pub fn move(comptime bits: usize, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!wide.Wide(bits) {
    return instruction.move(bits, meta, value, features);
}

pub fn movMask(comptime bits: usize, value: wide.Wide(bits), features: types.FeatureSet) types.SafetyError!u32 {
    return instruction.movMask(bits, meta, value, features);
}
