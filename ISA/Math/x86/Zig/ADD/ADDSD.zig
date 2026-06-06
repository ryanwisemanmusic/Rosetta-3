const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDSD",
    .family = "ADD",
    .path = "ADD/ADDSD.inc",
    .source_table_path = "ADD/ADDSD.inc",
    .target_isa = .x86,
    .operation = .addsd,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};
