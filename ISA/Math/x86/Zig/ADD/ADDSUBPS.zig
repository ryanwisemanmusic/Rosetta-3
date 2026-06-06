const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

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

pub const proof_cases = [_]proofs.ProofCase{
    .{ .addsubps = .{ .lhs = .{ 5.0, 5.0, 5.0, 5.0 }, .rhs = .{ 1.0, 2.0, 3.0, 4.0 }, .expected = .{ 4.0, 7.0, 2.0, 9.0 } } },
    .{ .addsubps = .{ .lhs = .{ 1.0, -1.0, 10.0, -10.0 }, .rhs = .{ 2.0, -2.0, 3.0, 4.0 }, .expected = .{ -1.0, -3.0, 7.0, -6.0 } } },
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

test "x86 ADDSUBPS hardcoded math proofs match core" {
    try verifyProofs();
}
