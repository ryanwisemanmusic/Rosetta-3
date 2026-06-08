const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "MOVNTPS",
    .family = "MOV",
    .path = "MOV/MOVNTPS.inc",
    .source_table_path = "MOV/MOVNTPS.inc",
    .target_isa = .neon,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "MOVNTPS", .path = "MOV/MOVNTPS.inc", .encoding_count = 2, .source_path_len = 15 } },
    .{ .documented_contract = .{ .name = "MOVNTPS", .path = "MOV/MOVNTPS.inc", .encoding_count = 2, .source_path_len = 15 } },
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

test "neon MOVNTPS documented-contract proofs match table metadata" {
    try verifyProofs();
}
