const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "JNC",
    .family = "Jcc",
    .path = "JMP/JNC.inc",
    .source_table_path = "JMP/JNC.inc",
    .target_isa = .neon,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "JNC", .path = "JMP/JNC.inc", .encoding_count = 3, .source_path_len = 11 } },
    .{ .documented_contract = .{ .name = "JNC", .path = "JMP/JNC.inc", .encoding_count = 3, .source_path_len = 11 } },
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

test "neon JNC documented-contract proofs match table metadata" {
    try verifyProofs();
}
