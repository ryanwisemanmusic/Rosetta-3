const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAA",
    .family = "ASCII",
    .path = "ASCII/AAA.inc",
    .source_table_path = "ASCII/AAA.inc",
    .target_isa = .x86,
    .operation = .aaa,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .aaa = .{ .ax = 0x000a, .expected = .{ .ax = 0x0100, .al = 0, .ah = 1, .flags = .{ .af = .set, .cf = .set } } } },
    .{ .aaa = .{ .ax = 0x0009, .expected = .{ .ax = 0x0009, .al = 9, .ah = 0, .flags = .{ .af = .clear, .cf = .clear } } } },
    .{ .aaa = .{ .ax = 0x0201, .input = .{ .af = true }, .expected = .{ .ax = 0x0307, .al = 7, .ah = 3, .flags = .{ .af = .set, .cf = .set } } } },
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

test "x86 AAA hardcoded math proofs match core" {
    try verifyProofs();
}
