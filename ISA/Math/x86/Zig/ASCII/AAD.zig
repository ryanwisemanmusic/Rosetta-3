const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAD",
    .family = "ASCII",
    .path = "ASCII/AAD.inc",
    .source_table_path = "ASCII/AAD.inc",
    .target_isa = .x86,
    .operation = .aad,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .aad = .{ .ah = 4, .al = 2, .immediate = 10, .expected = .{ .ax = 42, .al = 42, .ah = 0, .flags = .{ .zf = .clear, .sf = .clear, .pf = .clear } } } },
    .{ .aad = .{ .ah = 0xff, .al = 0xff, .immediate = 0xff, .expected = .{ .ax = 0, .al = 0, .ah = 0, .flags = .{ .zf = .set, .sf = .clear, .pf = .set } } } },
    .{ .aad = .{ .ah = 1, .al = 2, .immediate = 16, .expected = .{ .ax = 0x12, .al = 0x12, .ah = 0, .flags = .{ .zf = .clear, .sf = .clear, .pf = .set } } } },
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

test "x86 AAD hardcoded math proofs match core" {
    try verifyProofs();
}
