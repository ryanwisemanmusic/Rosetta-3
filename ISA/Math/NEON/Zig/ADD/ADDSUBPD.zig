const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDSUBPD",
    .family = "ADD",
    .path = "ADD/ADDSUBPD.inc",
    .source_table_path = "ADD/ADDSUBPD.inc",
    .target_isa = .neon,
    .operation = .addsubpd,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};
