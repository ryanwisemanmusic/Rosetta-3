const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MULSD",
    .family = "MUL",
    .path = "MUL/MULSD.inc",
    .source_table_path = "MUL/MULSD.inc",
    .target_isa = .neon,
    .operation = .mulsd,
    .register_model = .simd_scalar,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .mulsd_legacy = .{ .dest_or_src1 = .{ 3, 9 }, .src = .{ 4, 1 }, .expected = .{ 12, 9 } } },
    .{ .mulsd_vex = .{ .dest_or_src1 = .{ 3, 6 }, .src = .{ 4, 99 }, .expected = .{ 12, 6 } } },
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

test "neon MULSD hardcoded math proofs match core" {
    try verifyProofs();
}
