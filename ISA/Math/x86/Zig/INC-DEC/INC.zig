const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "INC",
    .family = "INC-DEC",
    .path = "INC-DEC/INC.inc",
    .source_table_path = "INC-DEC/INC.inc",
    .target_isa = .x86,
    .operation = .inc,
    .register_model = .gpr_unary,
    .flag_model = .preserve_cf_arithmetic,
};
