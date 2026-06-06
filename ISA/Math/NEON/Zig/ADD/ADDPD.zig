const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDPD",
    .family = "ADD",
    .path = "ADD/ADDPD.inc",
    .source_table_path = "ADD/ADDPD.inc",
    .target_isa = .neon,
    .operation = .addpd,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};
