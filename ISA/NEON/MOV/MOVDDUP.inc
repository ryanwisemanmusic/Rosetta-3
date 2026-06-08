// MOV/MOVDDUP.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVDDUP.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVDDUP.inc"
x86_handler = "x86_movddup"
neon_lowering = "arm64_move_from_x86_mov-ddup"
lowering_kind = "arm64_documented_contract"

// MOVDDUP.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVDDUP/MOVDDUP.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVDDUP"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVDDUP"

encodings = [
  { opcode = "F2 0F 12 /r", form = "MOVDDUP xmm1, xmm2/m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movddup_xmm_xmmm64" },
  { opcode = "VEX.256.F2.0F 12 /r", form = "VMOVDDUP ymm1, ymm2/m256", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovddup_ymm_ymmm256" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["SRC"]
writes = ["DEST"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
DEST[63:0] := SRC[63:0];
DEST[127:64] := SRC[63:0];
"""

mode_semantics = """
If the source is memory, only 64 bits are loaded; the result is a 128-bit register with the low 64 bits duplicated.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movddup"
jit_lowering = "arm64_move_from_x86_mov-ddup"
fallback = "zig_movddup_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVDDUP: duplicate low 64-bit double-precision
// ARM64: LD1R { v0.2d }, [x0]  or  DUP v0.2d, v0.d[0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVDDUP broadcasts the low 64-bit double-precision value across the destination register."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
