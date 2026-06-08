// MOVAPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVAPD/MOVAPD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVAPD.inc"
x86_handler = "x86_movapd"
neon_lowering = "arm64_move_from_x86_mov-apd"
lowering_kind = "arm64_simd_move"

name = "MOVAPD"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVAPD"

encodings = [
  { opcode = "66 0F 28 /r", form = "MOVAPD xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movapd_xmm_xmmm128" },
  { opcode = "66 0F 29 /r", form = "MOVAPD xmm2/m128, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movapd_xmmm128_xmm" },
  { opcode = "VEX.128.66.0F 28 /r", form = "VMOVAPD xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovapd_xmm_xmmm128" },
  { opcode = "VEX.256.66.0F 28 /r", form = "VMOVAPD ymm1, ymm2/m256", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovapd_ymm_ymmm256" },
  { opcode = "VEX.128.66.0F 29 /r", form = "VMOVAPD xmm2/m128, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_vmovapd_xmmm128_xmm" },
  { opcode = "VEX.256.66.0F 29 /r", form = "VMOVAPD ymm2/m256, ymm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_vmovapd_ymmm256_ymm" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
  { op_en = "MR", operand_1 = "ModRM:r/m (w)", operand_2 = "ModRM:reg (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["xmm2_or_m128"]
writes = ["xmm1"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
DEST := SRC;
Require 16-byte alignment unless VEX/EVEX exception;
"""

mode_semantics = """
In 64-bit mode, default operation size is 128/256 bits. VEX.W/EVEX.W control operation size.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movapd"
jit_lowering = "arm64_move_from_x86_mov-apd"
fallback = "zig_movapd_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVAPD: aligned packed double-precision load/store
// ARM64: LD1 { v0.2d }, [x0]  or  ST1 { v0.2d }, [x0]
// For VMOVAPD 256-bit: LD1 { v0.4d }, [x0]  or  ST1 { v0.4d }, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVAPD requires 16-byte alignment; ARM64 LD1/ST1 with aligned address."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]