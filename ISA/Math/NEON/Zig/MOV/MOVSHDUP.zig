const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MOVSHDUP",
    .family = "MOV",
    .path = "MOV/MOVSHDUP.inc",
    .source_table_path = "MOV/MOVSHDUP.inc",
    .target_isa = .neon,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "MOVSHDUP", .path = "MOV/MOVSHDUP.inc", .encoding_count = 2, .source_path_len = 16 } },
    .{ .documented_contract = .{ .name = "MOVSHDUP", .path = "MOV/MOVSHDUP.inc", .encoding_count = 2, .source_path_len = 16 } },
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

test "neon MOVSHDUP documented-contract proofs match table metadata" {
    try verifyProofs();
}
