const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADDPD",
    .family = "ADD",
    .path = "ADD/ADDPD.inc",
    .source_table_path = "ADD/ADDPD.inc",
    .target_isa = .x86,
    .operation = .addpd,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .addpd = .{ .lhs = .{ 1.0, -2.0 }, .rhs = .{ 4.0, 2.0 }, .expected = .{ 5.0, 0.0 } } },
    .{ .addpd = .{ .lhs = .{ -5.5, 0.25 }, .rhs = .{ 2.5, -0.75 }, .expected = .{ -3.0, -0.5 } } },
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

test "x86 ADDPD hardcoded math proofs match core" {
    try verifyProofs();
}
