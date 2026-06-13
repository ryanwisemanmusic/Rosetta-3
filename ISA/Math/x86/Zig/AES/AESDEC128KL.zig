const core = @import("../../../core.zig");
const proofs = @import("../../../proofs.zig");

pub const meta = core.InstructionMathMeta{
    .name = "AESDEC128KL",
    .family = "AES",
    .path = "AES/AESDEC128KL.inc",
    .source_table_path = "AES/AESDEC128KL.inc",
    .target_isa = .x86,
    .operation = .documented_contract,
    .register_model = .documented_contract,
    .flag_model = .documented_contract,
};

pub const proof_cases = [_]proofs.ProofCase{
    .{ .documented_contract = .{ .name = "AESDEC128KL", .path = "AES/AESDEC128KL.inc", .encoding_count = 1, .source_path_len = 19 } },
    .{ .documented_contract = .{ .name = "AESDEC128KL", .path = "AES/AESDEC128KL.inc", .encoding_count = 1, .source_path_len = 19 } },
};

pub const proof_report = proofs.ProofReport{
    .meta = meta,
    .cases = proof_cases[0..],
};
