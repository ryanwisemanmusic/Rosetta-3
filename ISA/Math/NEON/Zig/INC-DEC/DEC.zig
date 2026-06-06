const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "DEC",
    .family = "INC-DEC",
    .path = "INC-DEC/DEC.inc",
    .source_table_path = "INC-DEC/DEC.inc",
    .target_isa = .neon,
    .operation = .dec,
    .register_model = .gpr_unary,
    .flag_model = .preserve_cf_arithmetic,
};
