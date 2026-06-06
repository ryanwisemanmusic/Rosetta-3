const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAS",
    .family = "ASCII",
    .path = "ASCII/AAS.inc",
    .source_table_path = "ASCII/AAS.inc",
    .target_isa = .neon,
    .operation = .aas,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};
