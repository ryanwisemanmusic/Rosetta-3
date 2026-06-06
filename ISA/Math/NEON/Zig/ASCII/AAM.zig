const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAM",
    .family = "ASCII",
    .path = "ASCII/AAM.inc",
    .source_table_path = "ASCII/AAM.inc",
    .target_isa = .neon,
    .operation = .aam,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};
