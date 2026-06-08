const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "leave_16",
    .family = "procedure_exit",
    .path = "CALL-RET/LEAVE.inc",
    .source_table_path = "CALL-RET/LEAVE.inc",
    .target_isa = .x86,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "leave_16", .path = "CALL-RET/LEAVE.inc", .encoding_count = 1, .source_path_len = 18 } },
    .{ .documented_contract = .{ .name = "leave_16", .path = "CALL-RET/LEAVE.inc", .encoding_count = 1, .source_path_len = 18 } },
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

test "x86 leave_16 documented-contract proofs match table metadata" {
    try verifyProofs();
}
