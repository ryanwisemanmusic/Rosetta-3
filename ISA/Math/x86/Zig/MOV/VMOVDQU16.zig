const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "VMOVDQU16",
    .family = "MOV",
    .path = "MOV/VMOVDQU16.inc",
    .source_table_path = "MOV/VMOVDQU16.inc",
    .target_isa = .x86,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "VMOVDQU16", .path = "MOV/VMOVDQU16.inc", .encoding_count = 1, .source_path_len = 17 } },
    .{ .documented_contract = .{ .name = "VMOVDQU16", .path = "MOV/VMOVDQU16.inc", .encoding_count = 1, .source_path_len = 17 } },
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

test "x86 VMOVDQU16 documented-contract proofs match table metadata" {
    try verifyProofs();
}
