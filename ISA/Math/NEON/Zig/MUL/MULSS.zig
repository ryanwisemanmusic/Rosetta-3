const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MULSS",
    .family = "MUL",
    .path = "MUL/MULSS.inc",
    .source_table_path = "MUL/MULSS.inc",
    .target_isa = .neon,
    .operation = .mulss,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .mulss_legacy = .{ .dest_or_src1 = .{ 3, 9, 8, 7 }, .src = .{ 4, 1, 1, 1 }, .expected = .{ 12, 9, 8, 7 } } },
    .{ .mulss_vex = .{ .dest_or_src1 = .{ 3, 6, 5, 4 }, .src = .{ 4, 99, 99, 99 }, .expected = .{ 12, 6, 5, 4 } } },
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

test "neon MULSS hardcoded math proofs match core" {
    try verifyProofs();
}
