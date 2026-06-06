const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "IMUL",
    .family = "MUL",
    .path = "MUL/IMUL.inc",
    .source_table_path = "MUL/IMUL.inc",
    .target_isa = .neon,
    .operation = .imul,
    .register_model = .implicit_accumulator,
    .flag_model = .mul_overflow_pair,
};
