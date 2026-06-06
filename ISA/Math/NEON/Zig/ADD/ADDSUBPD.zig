const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDSUBPD",
    .family = "ADD",
    .path = "ADD/ADDSUBPD.inc",
    .source_table_path = "ADD/ADDSUBPD.inc",
    .target_isa = .neon,
    .operation = .addsubpd,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .addsubpd = .{ .lhs = .{ 5.0, 5.0 }, .rhs = .{ 1.0, 2.0 }, .expected = .{ 4.0, 7.0 } } },
    .{ .addsubpd = .{ .lhs = .{ 1.0, -1.0 }, .rhs = .{ 2.0, -2.0 }, .expected = .{ -1.0, -3.0 } } },
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

test "neon ADDSUBPD hardcoded math proofs match core" {
    try verifyProofs();
}
