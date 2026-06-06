const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SUBPD",
    .family = "SUB",
    .path = "SUB/SUBPD.inc",
    .source_table_path = "SUB/SUBPD.inc",
    .target_isa = .neon,
    .operation = .subpd,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .subpd = .{ .lhs = .{ 1.0, -2.0 }, .rhs = .{ 4.0, 2.0 }, .expected = .{ -3.0, -4.0 } } },
    .{ .subpd = .{ .lhs = .{ -5.5, 0.25 }, .rhs = .{ 2.5, -0.75 }, .expected = .{ -8.0, 1.0 } } },
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

test "neon SUBPD hardcoded math proofs match core" {
    try verifyProofs();
}
