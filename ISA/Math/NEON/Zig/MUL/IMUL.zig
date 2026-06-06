const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "IMUL",
    .family = "MUL",
    .path = "MUL/IMUL.inc",
    .source_table_path = "MUL/IMUL.inc",
    .target_isa = .neon,
    .operation = .imul,
    .register_model = .implicit_accumulator,
    .flag_model = .mul_overflow_pair,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .imul = .{ .width = .bits8, .lhs = 0x80, .rhs = 2, .expected = .{ .dest = 0, .high = 0xff, .flags = .{ .cf = .set, .of = .set } } } },
    .{ .imul = .{ .width = .bits8, .lhs = 0xff, .rhs = 1, .expected = .{ .dest = 0xff, .high = 0xff, .flags = .{ .cf = .clear, .of = .clear } } } },
    .{ .imul = .{ .width = .bits16, .lhs = 0x7fff, .rhs = 2, .expected = .{ .dest = 0xfffe, .high = 0, .flags = .{ .cf = .set, .of = .set } } } },
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

test "neon IMUL hardcoded math proofs match core" {
    try verifyProofs();
}
