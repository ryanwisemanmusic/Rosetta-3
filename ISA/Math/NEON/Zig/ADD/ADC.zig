const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADC",
    .family = "ADD",
    .path = "ADD/ADC.inc",
    .source_table_path = "ADD/ADC.inc",
    .target_isa = .neon,
    .operation = .adc,
    .register_model = .gpr_carry_chain,
    .flag_model = .arithmetic_full,
};
