const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "IDIV",
    .family = "DIV",
    .path = "DIV/IDIV.inc",
    .source_table_path = "DIV/IDIV.inc",
    .target_isa = .x86,
    .operation = .idiv,
    .register_model = .implicit_dividend,
    .flag_model = .undefined_after_divide,
};
