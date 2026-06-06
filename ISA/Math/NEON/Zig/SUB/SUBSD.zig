const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SUBSD",
    .family = "SUB",
    .path = "SUB/SUBSD.inc",
    .source_table_path = "SUB/SUBSD.inc",
    .target_isa = .neon,
    .operation = .subsd,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};
