const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDSD",
    .family = "ADD",
    .path = "ADD/ADDSD.inc",
    .source_table_path = "ADD/ADDSD.inc",
    .target_isa = .neon,
    .operation = .addsd,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .addsd_legacy = .{ .dest_or_src1 = .{ 1.0, 9.0 }, .src = .{ 2.0, 99.0 }, .expected = .{ 3.0, 9.0 } } },
    .{ .addsd_vex = .{ .dest_or_src1 = .{ 1.0, 6.0 }, .src = .{ 2.0, 99.0 }, .expected = .{ 3.0, 6.0 } } },
    .{ .addsd_legacy = .{ .dest_or_src1 = .{ -5.5, -7.0 }, .src = .{ 2.5, 3.0 }, .expected = .{ -3.0, -7.0 } } },
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

test "neon ADDSD hardcoded math proofs match core" {
    try verifyProofs();
}
