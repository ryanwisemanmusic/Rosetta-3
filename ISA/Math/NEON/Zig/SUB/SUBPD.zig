const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SUBPD",
    .family = "SUB",
    .path = "SUB/SUBPD.inc",
    .source_table_path = "SUB/SUBPD.inc",
    .target_isa = .neon,
    .operation = .subpd,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};
