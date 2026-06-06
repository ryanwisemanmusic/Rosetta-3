const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "INC",
    .family = "INC-DEC",
    .path = "INC-DEC/INC.inc",
    .source_table_path = "INC-DEC/INC.inc",
    .target_isa = .x86,
    .operation = .inc,
    .register_model = .gpr_unary,
    .flag_model = .preserve_cf_arithmetic,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .inc = .{ .width = .bits8, .value = 0x7f, .input = .{ .cf = true }, .expected = .{ .dest = 0x80, .flags = .{ .of = .set, .cf = .set, .sf = .set } } } },
    .{ .inc = .{ .width = .bits8, .value = 0xff, .input = .{ .cf = false }, .expected = .{ .dest = 0, .flags = .{ .zf = .set, .cf = .clear } } } },
    .{ .inc = .{ .width = .bits16, .value = 0, .input = .{ .cf = true }, .expected = .{ .dest = 1, .flags = .{ .zf = .clear, .cf = .set } } } },
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

test "x86 INC hardcoded math proofs match core" {
    try verifyProofs();
}
