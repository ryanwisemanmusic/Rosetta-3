const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MUL",
    .family = "MUL",
    .path = "MUL/MUL.inc",
    .source_table_path = "MUL/MUL.inc",
    .target_isa = .neon,
    .operation = .mul,
    .register_model = .implicit_accumulator,
    .flag_model = .mul_overflow_pair,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .mul = .{ .width = .bits16, .lhs = 0xffff, .rhs = 2, .expected = .{ .dest = 0xfffe, .high = 1, .flags = .{ .cf = .set, .of = .set } } } },
    .{ .mul = .{ .width = .bits16, .lhs = 0x10, .rhs = 2, .expected = .{ .dest = 0x20, .high = 0, .flags = .{ .cf = .clear, .of = .clear } } } },
    .{ .mul = .{ .width = .bits8, .lhs = 0xff, .rhs = 0xff, .expected = .{ .dest = 1, .high = 0xfe, .flags = .{ .cf = .set, .of = .set } } } },
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

test "neon MUL hardcoded math proofs match core" {
    try verifyProofs();
}
