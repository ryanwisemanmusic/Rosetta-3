// MOVDQ2Q.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVDQ2Q/MOVDQ2Q.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVDQ2Q.inc"
x86_handler = "x86_movdq2q"
neon_lowering = "arm64_move_from_x86_mov-dq2q"
lowering_kind = "arm64_simd_move"

name = "MOVDQ2Q"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "F2 0F D6 /r", form = "MOVDQ2Q mm1, xmm1", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movdq2q_mmx_xmm" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["xmm1"]
writes = ["mm1"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
mm1[63:0] := xmm1[63:0];
"""

mode_semantics = """
Moves the lower 64-bit quadword from an XMM register to an MMX register.
"""

exceptions = {
simd = ["#UD"]
}

handler = "x86_movdq2q"
jit_lowering = "arm64_move_from_x86_mov-dq2q"
fallback = "zig_movdq2q_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVDQ2Q: XMM lower quadword -> MMX
// ARM64: MOV v0.2d, v1.2d // FMOV or X to D transfer; MMX stubs via GPR
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVDQ2Q transfers the low 64 bits of XMM to MMX. ARM64 has no MMX; lower via GPR stubs."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]