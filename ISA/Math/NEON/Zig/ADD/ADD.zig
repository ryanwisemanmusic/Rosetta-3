const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADD",
    .family = "ADD",
    .path = "ADD/ADD.inc",
    .source_table_path = "ADD/ADD.inc",
    .target_isa = .neon,
    .operation = .add,
    .register_model = .gpr_binary,
    .flag_model = .arithmetic_full,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .add = .{ .width = .bits8, .lhs = 0xff, .rhs = 1, .expected = .{ .dest = 0, .flags = .{ .cf = .set, .zf = .set, .of = .clear, .af = .set, .sf = .clear } } } },
    .{ .add = .{ .width = .bits8, .lhs = 0x7f, .rhs = 1, .expected = .{ .dest = 0x80, .flags = .{ .cf = .clear, .of = .set, .sf = .set, .af = .set } } } },
    .{ .add = .{ .width = .bits64, .lhs = 0xffff_ffff_ffff_fffe, .rhs = 2, .expected = .{ .dest = 0, .flags = .{ .cf = .set, .zf = .set, .of = .clear } } } },
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

test "neon ADD hardcoded math proofs match core" {
    try verifyProofs();
}
