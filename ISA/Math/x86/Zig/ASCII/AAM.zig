const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AAM",
    .family = "ASCII",
    .path = "ASCII/AAM.inc",
    .source_table_path = "ASCII/AAM.inc",
    .target_isa = .x86,
    .operation = .aam,
    .register_model = .ascii_ax,
    .flag_model = .ascii_adjust,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .aam = .{ .al = 42, .immediate = 10, .expected = .{ .ax = 0x0402, .al = 2, .ah = 4, .flags = .{ .zf = .clear, .sf = .clear, .pf = .clear } } } },
    .{ .aam = .{ .al = 0, .immediate = 10, .expected = .{ .ax = 0, .al = 0, .ah = 0, .flags = .{ .zf = .set, .sf = .clear, .pf = .set } } } },
    .{ .aam = .{ .al = 1, .immediate = 0, .expected = .{ .trap = .divide_error } } },
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

test "x86 AAM hardcoded math proofs match core" {
    try verifyProofs();
}
