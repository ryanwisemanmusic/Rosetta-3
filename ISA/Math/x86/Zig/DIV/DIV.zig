const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "DIV",
    .family = "DIV",
    .path = "DIV/DIV.inc",
    .source_table_path = "DIV/DIV.inc",
    .target_isa = .x86,
    .operation = .div,
    .register_model = .implicit_dividend,
    .flag_model = .undefined_after_divide,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .div = .{ .width = .bits8, .high = 0, .low = 0x10, .divisor = 4, .expected = .{ .dest = 4, .quotient = 4, .remainder = 0, .flags = .{ .cf = .undefined, .of = .undefined } } } },
    .{ .div = .{ .width = .bits16, .high = 0, .low = 0x1234, .divisor = 0x10, .expected = .{ .dest = 0x0123, .quotient = 0x0123, .remainder = 4, .flags = .{ .cf = .undefined, .of = .undefined } } } },
    .{ .div = .{ .width = .bits8, .high = 1, .low = 0, .divisor = 1, .expected = .{ .trap = .divide_error } } },
    .{ .div = .{ .width = .bits8, .high = 0, .low = 1, .divisor = 0, .expected = .{ .trap = .divide_error } } },
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

test "x86 DIV hardcoded math proofs match core" {
    try verifyProofs();
}
