// MOV/MOVQ2DQ.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVQ2DQ.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVQ2DQ.inc"
x86_handler = "x86_movq2dq"
neon_lowering = "arm64_move_from_x86_mov-q2dq"
lowering_kind = "arm64_documented_contract"

// MOVQ2DQ.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVQ2DQ/MOVQ2DQ.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVQ2DQ"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "F3 0F D6 /r", form = "MOVQ2DQ xmm1, mm1", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movq2dq_xmm_mmx" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["mm1"]
writes = ["xmm1"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
xmm1[63:0] := mm1[63:0];
xmm1[127:64] := 0;
"""

mode_semantics = """
Moves the 64-bit quadword from an MMX register to the lower quadword of an XMM register, zeroing the upper quadword.
"""

exceptions = {
simd = ["#UD"]
}

handler = "x86_movq2dq"
jit_lowering = "arm64_move_from_x86_mov-q2dq"
fallback = "zig_movq2dq_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVQ2DQ: MMX quadword -> XMM (zero-extend)
// ARM64: FMOV D0, X0  // MMX stubs via GPR
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVQ2DQ transfers 64-bit MMX value to XMM, zeroing upper 64 bits. MMX stubs via GPR."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
