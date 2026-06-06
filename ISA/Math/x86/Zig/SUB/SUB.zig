const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SUB",
    .family = "SUB",
    .path = "SUB/SUB.inc",
    .source_table_path = "SUB/SUB.inc",
    .target_isa = .x86,
    .operation = .sub,
    .register_model = .gpr_binary,
    .flag_model = .arithmetic_full,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .sub = .{ .width = .bits8, .lhs = 0, .rhs = 1, .expected = .{ .dest = 0xff, .flags = .{ .cf = .set, .of = .clear, .sf = .set, .af = .set } } } },
    .{ .sub = .{ .width = .bits8, .lhs = 0x80, .rhs = 1, .expected = .{ .dest = 0x7f, .flags = .{ .cf = .clear, .of = .set, .sf = .clear } } } },
    .{ .sub = .{ .width = .bits64, .lhs = 0, .rhs = 1, .expected = .{ .dest = 0xffff_ffff_ffff_ffff, .flags = .{ .cf = .set, .sf = .set } } } },
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

test "x86 SUB hardcoded math proofs match core" {
    try verifyProofs();
}
