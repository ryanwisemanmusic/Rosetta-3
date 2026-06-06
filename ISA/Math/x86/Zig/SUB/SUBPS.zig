const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SUBPS",
    .family = "SUB",
    .path = "SUB/SUBPS.inc",
    .source_table_path = "SUB/SUBPS.inc",
    .target_isa = .x86,
    .operation = .subps,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};
