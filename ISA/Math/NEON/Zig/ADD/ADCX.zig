const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADCX",
    .family = "ADD",
    .path = "ADD/ADCX.inc",
    .source_table_path = "ADD/ADCX.inc",
    .target_isa = .neon,
    .operation = .adcx,
    .register_model = .gpr_carry_chain,
    .flag_model = .carry_only,
};
