// VMOVNTDQA.inc
// Generated documented alias from ISA/x86/MOV/MOVNTDQA.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

source_isa = "x86"
name = "VMOVNTDQA"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVNTDQA"

encodings = [
  { opcode = "see MOV/MOVNTDQA.inc", form = "VMOVNTDQA documented alias of MOVNTDQA", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovntdqa" },
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
VMOVNTDQA is documented as an alias or width-specialized form of MOVNTDQA.
Execute the matching MOVNTDQA source-contract form exactly.
"""

source_contract = """
// MOVNTDQA.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVNTDQA/MOVNTDQA.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVNTDQA.inc"
x86_handler = "x86_movntdqa"
neon_lowering = "arm64_move_from_x86_mov-ntdqa"
lowering_kind = "arm64_non_temporal_load"

name = "MOVNTDQA"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "66 0F 38 2A /r", form = "MOVNTDQA xmm1, m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movntdqa_xmm_m128" },
  { opcode = "VEX.256.66.0F 38 2A /r", form = "VMOVNTDQA ymm1, m256", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovntdqa_ymm_m256" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["m128"]
writes = ["xmm1"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
xmm1 := NonTemporalLoad(m128);
"""

mode_semantics = """
Non-temporal load with minimal cache pollution.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movntdqa"
jit_lowering = "arm64_move_from_x86_mov-ntdqa"
fallback = "zig_movntdqa_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVNTDQA: non-temporal 128-bit integer load
// ARM64: LDNP or LD1 with non-temporal hint
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVNTDQA is a non-temporal load hint; ARM64 LDNP or equivalent."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovntdqa"
jit_lowering = "arm64_documented_alias_from_x86_vmovntdqa"
fallback = "zig_vmovntdqa_fallback"
