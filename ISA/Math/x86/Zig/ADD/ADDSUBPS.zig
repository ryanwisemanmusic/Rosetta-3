const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDSUBPS",
    .family = "ADD",
    .path = "ADD/ADDSUBPS.inc",
    .source_table_path = "ADD/ADDSUBPS.inc",
    .target_isa = .x86,
    .operation = .addsubps,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};
