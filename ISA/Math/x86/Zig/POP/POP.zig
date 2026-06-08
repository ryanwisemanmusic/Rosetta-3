const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "POP",
    .family = "POP",
    .path = "POP/POP.inc",
    .source_table_path = "POP/POP.inc",
    .target_isa = .x86,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "POP", .path = "POP/POP.inc", .encoding_count = 15, .source_path_len = 11 } },
    .{ .documented_contract = .{ .name = "POP", .path = "POP/POP.inc", .encoding_count = 15, .source_path_len = 11 } },
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

test "x86 POP documented-contract proofs match table metadata" {
    try verifyProofs();
}
