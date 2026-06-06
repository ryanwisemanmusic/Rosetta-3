const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "IDIV",
    .family = "DIV",
    .path = "DIV/IDIV.inc",
    .source_table_path = "DIV/IDIV.inc",
    .target_isa = .x86,
    .operation = .idiv,
    .register_model = .implicit_dividend,
    .flag_model = .undefined_after_divide,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .idiv = .{ .width = .bits8, .high = 0xff, .low = 0xf6, .divisor = 0xfd, .expected = .{ .dest = 3, .quotient = 3, .remainder = 0xff, .flags = .{ .cf = .undefined, .of = .undefined } } } },
    .{ .idiv = .{ .width = .bits16, .high = 0xffff, .low = 0xfff6, .divisor = 3, .expected = .{ .dest = 0xfffd, .quotient = 0xfffd, .remainder = 0xffff, .flags = .{ .cf = .undefined, .of = .undefined } } } },
    .{ .idiv = .{ .width = .bits8, .high = 0xff, .low = 0x80, .divisor = 0xff, .expected = .{ .trap = .divide_error } } },
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

test "x86 IDIV hardcoded math proofs match core" {
    try verifyProofs();
}
