const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SUBSS",
    .family = "SUB",
    .path = "SUB/SUBSS.inc",
    .source_table_path = "SUB/SUBSS.inc",
    .target_isa = .x86,
    .operation = .subss,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};
