const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MULPS",
    .family = "MUL",
    .path = "MUL/MULPS.inc",
    .source_table_path = "MUL/MULPS.inc",
    .target_isa = .x86,
    .operation = .mulps,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .mulps = .{ .lhs = .{ 1, -2, 3, -4 }, .rhs = .{ 5, 6, 7, 8 }, .expected = .{ 5, -12, 21, -32 } } },
    .{ .mulps = .{ .lhs = .{ 0.5, -1.5, 2.5, -3.5 }, .rhs = .{ 2, 2, 2, 2 }, .expected = .{ 1, -3, 5, -7 } } },
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

test "x86 MULPS hardcoded math proofs match core" {
    try verifyProofs();
}
