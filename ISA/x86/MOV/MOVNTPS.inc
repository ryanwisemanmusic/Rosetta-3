// MOVNTPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVNTPS/MOVNTPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVNTPS.inc"
x86_handler = "x86_movntps"
neon_lowering = "arm64_move_from_x86_mov-ntps"
lowering_kind = "arm64_non_temporal_store"

name = "MOVNTPS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F 2B /r", form = "MOVNTPS m128, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movntps_m128_xmm" },
  { opcode = "VEX.256.0F 2B /r", form = "VMOVNTPS m256, ymm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_vmovntps_m256_ymm" },
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
Non-temporal store of packed single-precision values.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movntps"
jit_lowering = "arm64_move_from_x86_mov-ntps"
fallback = "zig_movntps_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVNTPS: non-temporal single-precision store
// ARM64: STNP with non-temporal hint
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVNTPS stores single-precision data without cache pollution."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]