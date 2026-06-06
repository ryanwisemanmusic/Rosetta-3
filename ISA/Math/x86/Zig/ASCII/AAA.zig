const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAA",
    .family = "ASCII",
    .path = "ASCII/AAA.inc",
    .source_table_path = "ASCII/AAA.inc",
    .target_isa = .x86,
    .operation = .aaa,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};
