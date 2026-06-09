const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "DIVSS",
    .family = "DIV",
    .path = "DIV/DIVSS.inc",
    .source_table_path = "DIV/DIVSS.inc",
    .target_isa = .neon,
    .operation = .divss,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .divss_legacy = .{ .dest_or_src1 = .{ 12, 9, 8, 7 }, .src = .{ 3, 1, 1, 1 }, .expected = .{ 4, 9, 8, 7 } } },
    .{ .divss_vex = .{ .dest_or_src1 = .{ 12, 6, 5, 4 }, .src = .{ 3, 99, 99, 99 }, .expected = .{ 4, 6, 5, 4 } } },
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

test "neon DIVSS hardcoded math proofs match core" {
    try verifyProofs();
}
