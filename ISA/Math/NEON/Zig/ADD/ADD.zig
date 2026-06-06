const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADD",
    .family = "ADD",
    .path = "ADD/ADD.inc",
    .source_table_path = "ADD/ADD.inc",
    .target_isa = .neon,
    .operation = .add,
    .register_model = .gpr_binary,
    .flag_model = .arithmetic_full,
};
