const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "DIVPS",
    .family = "DIV",
    .path = "DIV/DIVPS.inc",
    .source_table_path = "DIV/DIVPS.inc",
    .target_isa = .x86,
    .operation = .divps,
    .register_model = .simd_packed,
    .flag_model = .mxcsr_float,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .divps = .{ .lhs = .{ 10, -8, 6, -4 }, .rhs = .{ 2, 4, 3, 2 }, .expected = .{ 5, -2, 2, -2 } } },
    .{ .divps = .{ .lhs = .{ 1, 9, 25, 49 }, .rhs = .{ 1, 3, 5, 7 }, .expected = .{ 1, 3, 5, 7 } } },
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

test "x86 DIVPS hardcoded math proofs match core" {
    try verifyProofs();
}
