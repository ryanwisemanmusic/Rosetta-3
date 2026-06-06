const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SUB",
    .family = "SUB",
    .path = "SUB/SUB.inc",
    .source_table_path = "SUB/SUB.inc",
    .target_isa = .x86,
    .operation = .sub,
    .register_model = .gpr_binary,
    .flag_model = .arithmetic_full,
};
