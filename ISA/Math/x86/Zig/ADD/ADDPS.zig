const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDPS",
    .family = "ADD",
    .path = "ADD/ADDPS.inc",
    .source_table_path = "ADD/ADDPS.inc",
    .target_isa = .x86,
    .operation = .addps,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};
