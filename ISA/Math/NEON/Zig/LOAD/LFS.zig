const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "LFS",
    .family = "LDS/LES/LFS/LGS/LSS",
    .path = "LOAD/LFS.inc",
    .source_table_path = "LOAD/LFS.inc",
    .target_isa = .neon,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "LFS", .path = "LOAD/LFS.inc", .encoding_count = 15, .source_path_len = 12 } },
    .{ .documented_contract = .{ .name = "LFS", .path = "LOAD/LFS.inc", .encoding_count = 15, .source_path_len = 12 } },
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

test "neon LFS documented-contract proofs match table metadata" {
    try verifyProofs();
}
