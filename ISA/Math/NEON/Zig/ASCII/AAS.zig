const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAS",
    .family = "ASCII",
    .path = "ASCII/AAS.inc",
    .source_table_path = "ASCII/AAS.inc",
    .target_isa = .neon,
    .operation = .aas,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .aas = .{ .ax = 0x020f, .expected = .{ .ax = 0x0109, .al = 9, .ah = 1, .flags = .{ .af = .set, .cf = .set } } } },
    .{ .aas = .{ .ax = 0x0009, .expected = .{ .ax = 0x0009, .al = 9, .ah = 0, .flags = .{ .af = .clear, .cf = .clear } } } },
    .{ .aas = .{ .ax = 0x0100, .input = .{ .af = true }, .expected = .{ .ax = 0xff0a, .al = 0x0a, .ah = 0xff, .flags = .{ .af = .set, .cf = .set } } } },
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

test "neon AAS hardcoded math proofs match core" {
    try verifyProofs();
}
