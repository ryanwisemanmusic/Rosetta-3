const core = @import("../../../core.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADOX",
    .family = "ADD",
    .path = "ADD/ADOX.inc",
    .source_table_path = "ADD/ADOX.inc",
    .target_isa = .x86,
    .operation = .adox,
    .register_model = .gpr_carry_chain,
    .flag_model = .overflow_only,
};
