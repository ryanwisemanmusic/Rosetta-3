// MOV/MOVAPS.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVAPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVAPS.inc"
x86_handler = "x86_movaps"
neon_lowering = "arm64_move_from_x86_mov-aps"
lowering_kind = "arm64_documented_contract"

// MOVAPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVAPS/MOVAPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVAPS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVAPS"

encodings = [
  { opcode = "0F 28 /r", form = "MOVAPS xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movaps_xmm_xmmm128" },
  { opcode = "0F 29 /r", form = "MOVAPS xmm2/m128, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movaps_xmmm128_xmm" },
  { opcode = "VEX.128.0F 28 /r", form = "VMOVAPS xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovaps_xmm_xmmm128" },
  { opcode = "VEX.256.0F 28 /r", form = "VMOVAPS ymm1, ymm2/m256", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovaps_ymm_ymmm256" },
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
Require 16-byte alignment for memory operand;
"""

mode_semantics = """
In 64-bit mode, default operation size is 128/256 bits.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movaps"
jit_lowering = "arm64_move_from_x86_mov-aps"
fallback = "zig_movaps_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVAPS: aligned packed single-precision load/store
// ARM64: LD1 { v0.4s }, [x0]  or  ST1 { v0.4s }, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVAPS requires 16-byte alignment; ARM64 LD1/ST1 with aligned address."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
