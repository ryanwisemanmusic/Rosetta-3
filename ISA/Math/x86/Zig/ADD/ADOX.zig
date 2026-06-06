const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

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

pub const proof_cases = [_]proofs.ProofCase{
    .{ .adox = .{ .width = .bits32, .lhs = 0xffff_ffff, .rhs = 0, .input = .{ .of = true }, .expected = .{ .dest = 0, .flags = .{ .of = .set, .cf = .preserve } } } },
    .{ .adox = .{ .width = .bits64, .lhs = 5, .rhs = 6, .input = .{ .of = false }, .expected = .{ .dest = 11, .flags = .{ .of = .clear, .cf = .preserve } } } },
    .{ .adox = .{ .width = .bits8, .lhs = 0xfe, .rhs = 1, .input = .{ .of = true }, .expected = .{ .dest = 0, .flags = .{ .of = .set, .cf = .preserve } } } },
};

pub const proof_report = proofs.ProofReport{
    .meta = meta,
    .cases = proof_cases[0..],
};

pub fn proofReport() proofs.ProofReport {
    return proof_report;
}

pub fn verifyProofs() !void {
    try proofs.verifyReport(proofReport());
}

test "x86 ADOX hardcoded math proofs match core" {
    try verifyProofs();
}
