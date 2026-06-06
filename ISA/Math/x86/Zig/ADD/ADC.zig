const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "ADC",
    .family = "ADD",
    .path = "ADD/ADC.inc",
    .source_table_path = "ADD/ADC.inc",
    .target_isa = .x86,
    .operation = .adc,
    .register_model = .gpr_carry_chain,
    .flag_model = .arithmetic_full,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .adc = .{ .width = .bits16, .lhs = 0xffff, .rhs = 0, .input = .{ .cf = true }, .expected = .{ .dest = 0, .flags = .{ .cf = .set, .zf = .set, .of = .clear } } } },
    .{ .adc = .{ .width = .bits8, .lhs = 0x7f, .rhs = 0, .input = .{ .cf = true }, .expected = .{ .dest = 0x80, .flags = .{ .cf = .clear, .of = .set, .sf = .set } } } },
    .{ .adc = .{ .width = .bits32, .lhs = 0xffff_fffe, .rhs = 1, .input = .{ .cf = true }, .expected = .{ .dest = 0, .flags = .{ .cf = .set, .zf = .set } } } },
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

test "x86 ADC hardcoded math proofs match core" {
    try verifyProofs();
}
