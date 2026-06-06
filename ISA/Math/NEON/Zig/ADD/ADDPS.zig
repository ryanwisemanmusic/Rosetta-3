const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDPS",
    .family = "ADD",
    .path = "ADD/ADDPS.inc",
    .source_table_path = "ADD/ADDPS.inc",
    .target_isa = .neon,
    .operation = .addps,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .addps = .{ .lhs = .{ 1.0, -0.0, 10.0, -2.0 }, .rhs = .{ 2.0, 0.0, -5.0, 2.0 }, .expected = .{ 3.0, 0.0, 5.0, 0.0 } } },
    .{ .addps = .{ .lhs = .{ -5.5, 0.25, 7.0, -8.0 }, .rhs = .{ 2.5, -0.75, 1.0, -2.0 }, .expected = .{ -3.0, -0.5, 8.0, -10.0 } } },
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

test "neon ADDPS hardcoded math proofs match core" {
    try verifyProofs();
}
