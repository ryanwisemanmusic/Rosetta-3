const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MUL",
    .family = "MUL",
    .path = "MUL/MUL.inc",
    .source_table_path = "MUL/MUL.inc",
    .target_isa = .x86,
    .operation = .mul,
    .register_model = .implicit_accumulator,
    .flag_model = .mul_overflow_pair,
};
