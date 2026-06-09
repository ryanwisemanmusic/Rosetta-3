const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "DIVSD",
    .family = "DIV",
    .path = "DIV/DIVSD.inc",
    .source_table_path = "DIV/DIVSD.inc",
    .target_isa = .neon,
    .operation = .divsd,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .divsd_legacy = .{ .dest_or_src1 = .{ 12, 9 }, .src = .{ 3, 1 }, .expected = .{ 4, 9 } } },
    .{ .divsd_vex = .{ .dest_or_src1 = .{ 12, 6 }, .src = .{ 3, 99 }, .expected = .{ 4, 6 } } },
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

test "neon DIVSD hardcoded math proofs match core" {
    try verifyProofs();
}
