const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "DIV",
    .family = "DIV",
    .path = "DIV/DIV.inc",
    .source_table_path = "DIV/DIV.inc",
    .target_isa = .x86,
    .operation = .div,
    .register_model = .implicit_dividend,
    .flag_model = .undefined_after_divide,
};
