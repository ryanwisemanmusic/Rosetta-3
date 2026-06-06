const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAD",
    .family = "ASCII",
    .path = "ASCII/AAD.inc",
    .source_table_path = "ASCII/AAD.inc",
    .target_isa = .neon,
    .operation = .aad,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};
