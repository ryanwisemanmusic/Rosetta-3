// MOV/MOVNTPD.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVNTPD.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVNTPD.inc"
x86_handler = "x86_movntpd"
neon_lowering = "arm64_move_from_x86_mov-ntpd"
lowering_kind = "arm64_documented_contract"

// MOVNTPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVNTPD/MOVNTPD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVNTPD"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "66 0F 2B /r", form = "MOVNTPD m128, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movntpd_m128_xmm" },
  { opcode = "VEX.256.66.0F 2B /r", form = "VMOVNTPD m256, ymm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_vmovntpd_m256_ymm" },
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
Non-temporal store of packed double-precision values.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movntpd"
jit_lowering = "arm64_move_from_x86_mov-ntpd"
fallback = "zig_movntpd_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVNTPD: non-temporal double-precision store
// ARM64: STNP with non-temporal hint
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVNTPD stores double-precision data without cache pollution."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
