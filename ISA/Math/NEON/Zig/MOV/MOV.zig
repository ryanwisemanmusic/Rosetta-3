const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MOV",
    .family = "MOV",
    .path = "MOV/MOV.inc",
    .source_table_path = "MOV/MOV.inc",
    .target_isa = .neon,
    .operation = .mov,
    .register_model = .gpr_transfer,
    .flag_model = .no_flags,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .mov = .{ .width = .bits16, .src = 0xffff_fff0, .expected = .{ .dest = 0xfff0, .flags = .{ .cf = .preserve, .of = .preserve } } } },
    .{ .mov = .{ .width = .bits8, .src = 0x123, .expected = .{ .dest = 0x23, .flags = .{ .cf = .preserve, .zf = .preserve } } } },
    .{ .mov = .{ .width = .bits64, .src = 0x8000_0000_0000_0001, .expected = .{ .dest = 0x8000_0000_0000_0001, .flags = .{ .cf = .preserve, .of = .preserve } } } },
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

test "neon MOV hardcoded math proofs match core" {
    try verifyProofs();
}
