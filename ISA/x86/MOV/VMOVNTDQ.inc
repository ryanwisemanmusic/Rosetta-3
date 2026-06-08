// VMOVNTDQ.inc
// Generated documented alias from ISA/x86/MOV/MOVNTDQ.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

source_isa = "x86"
name = "VMOVNTDQ"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVNTDQ"

encodings = [
  { opcode = "see MOV/MOVNTDQ.inc", form = "VMOVNTDQ documented alias of MOVNTDQ", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovntdq" },
]

operand_encoding = [
  { op_en = "ALIAS", operand_1 = "see source_contract", operand_2 = "see source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["see source_contract"]
writes = ["see source_contract"]
flags_read = []
flags_written = []
flags_affected = []
flags_model = "preserve source_contract flag behavior"
lock_allowed = false

semantic = """
VMOVNTDQ is documented as an alias or width-specialized form of MOVNTDQ.
Execute the matching MOVNTDQ source-contract form exactly.
"""

source_contract = """
// MOVNTDQ.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVNTDQ/MOVNTDQ.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVNTDQ.inc"
x86_handler = "x86_movntdq"
neon_lowering = "arm64_move_from_x86_mov-ntdq"
lowering_kind = "arm64_non_temporal_store"

name = "MOVNTDQ"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "66 0F E7 /r", form = "MOVNTDQ m128, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movntdq_m128_xmm" },
  { opcode = "VEX.256.66.0F E7 /r", form = "VMOVNTDQ m256, ymm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_vmovntdq_m256_ymm" },
]

operand_encoding = [
  { op_en = "MR", operand_1 = "ModRM:r/m (w)", operand_2 = "ModRM:reg (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["xmm1"]
writes = ["m128"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
NonTemporalStore(DEST, SRC);
"""

mode_semantics = """
Non-temporal store of packed integers; minimizes cache pollution.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movntdq"
jit_lowering = "arm64_move_from_x86_mov-ntdq"
fallback = "zig_movntdq_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVNTDQ: non-temporal 128-bit integer store
// ARM64: STNP or ST1 with non-temporal hint
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVNTDQ uses write-combining non-temporal hint; ARM64 STNP or equivalent."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovntdq"
jit_lowering = "arm64_documented_alias_from_x86_vmovntdq"
fallback = "zig_vmovntdq_fallback"
