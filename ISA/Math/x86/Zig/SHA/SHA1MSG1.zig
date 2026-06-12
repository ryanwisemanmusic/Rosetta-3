const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "SHA1MSG1",
    .family = "SHA",
    .path = "SHA/SHA1MSG1.inc",
    .source_table_path = "SHA/SHA1MSG1.inc",
    .target_isa = .x86,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "SHA1MSG1", .path = "SHA/SHA1MSG1.inc", .encoding_count = 1, .source_path_len = 16 } },
    .{ .documented_contract = .{ .name = "SHA1MSG1", .path = "SHA/SHA1MSG1.inc", .encoding_count = 1, .source_path_len = 16 } },
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

test "x86 SHA1MSG1 documented-contract proofs match table metadata" {
    try verifyProofs();
}
