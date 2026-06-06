const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDSS",
    .family = "ADD",
    .path = "ADD/ADDSS.inc",
    .source_table_path = "ADD/ADDSS.inc",
    .target_isa = .x86,
    .operation = .addss,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};
