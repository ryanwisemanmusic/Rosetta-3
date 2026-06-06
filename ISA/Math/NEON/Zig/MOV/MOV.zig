const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MOV",
    .family = "MOV",
    .path = "MOV/MOV.inc",
    .source_table_path = "MOV/MOV.inc",
    .target_isa = .neon,
    .operation = .mov,
    .register_model = .gpr_transfer,
    .flag_model = .no_flags,
};
