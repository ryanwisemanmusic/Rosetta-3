const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADCX",
    .family = "ADD",
    .path = "ADD/ADCX.inc",
    .source_table_path = "ADD/ADCX.inc",
    .target_isa = .neon,
    .operation = .adcx,
    .register_model = .gpr_carry_chain,
    .flag_model = .carry_only,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .adcx = .{ .width = .bits32, .lhs = 0xffff_ffff, .rhs = 0, .input = .{ .cf = true }, .expected = .{ .dest = 0, .flags = .{ .cf = .set, .of = .preserve } } } },
    .{ .adcx = .{ .width = .bits64, .lhs = 5, .rhs = 6, .input = .{ .cf = false }, .expected = .{ .dest = 11, .flags = .{ .cf = .clear, .of = .preserve } } } },
    .{ .adcx = .{ .width = .bits8, .lhs = 0xfe, .rhs = 1, .input = .{ .cf = true }, .expected = .{ .dest = 0, .flags = .{ .cf = .set, .of = .preserve } } } },
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

test "neon ADCX hardcoded math proofs match core" {
    try verifyProofs();
}
