const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MULPD",
    .family = "MUL",
    .path = "MUL/MULPD.inc",
    .source_table_path = "MUL/MULPD.inc",
    .target_isa = .neon,
    .operation = .mulpd,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .mulpd = .{ .lhs = .{ 1.5, -2.0 }, .rhs = .{ 4.0, 3.0 }, .expected = .{ 6.0, -6.0 } } },
    .{ .mulpd = .{ .lhs = .{ -5.5, 0.25 }, .rhs = .{ 2.0, -4.0 }, .expected = .{ -11.0, -1.0 } } },
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

test "neon MULPD hardcoded math proofs match core" {
    try verifyProofs();
}
