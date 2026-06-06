const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

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

pub const proof_cases = [_]proofs.ProofCase{
    .{ .subps = .{ .lhs = .{ 1.0, 0.0, 8.0, -2.0 }, .rhs = .{ 2.0, 0.0, 3.0, 2.0 }, .expected = .{ -1.0, 0.0, 5.0, -4.0 } } },
    .{ .subps = .{ .lhs = .{ -5.5, 0.25, 7.0, -8.0 }, .rhs = .{ 2.5, -0.75, 1.0, -2.0 }, .expected = .{ -8.0, 1.0, 6.0, -6.0 } } },
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

test "x86 SUBPS hardcoded math proofs match core" {
    try verifyProofs();
}
