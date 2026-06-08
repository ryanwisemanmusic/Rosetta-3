// MOVZX.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVZX/MOVZX.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVZX.inc"
x86_handler = "x86_movzx"
neon_lowering = "arm64_move_from_x86_mov-zx"
lowering_kind = "arm64_zero_extend_move"

name = "MOVZX"
category = "data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F B6 /r", form = "MOVZX r16, r/m8", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movzx_r16_rm8" },
  { opcode = "0F B6 /r", form = "MOVZX r32, r/m8", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movzx_r32_rm8" },
  { opcode = "REX.W + 0F B6 /r", form = "MOVZX r64, r/m8", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movzx_r64_rm8" },
  { opcode = "0F B7 /r", form = "MOVZX r32, r/m16", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movzx_r32_rm16" },
  { opcode = "REX.W + 0F B7 /r", form = "MOVZX r64, r/m16", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movzx_r64_rm16" },
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
DEST := zero_extend(SRC);
"""

mode_semantics = """
Zero-extends an 8-bit or 16-bit source to a larger destination size. In 64-bit mode, REX.W extends to 64 bits.
"""

exceptions = {
general = ["#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movzx"
jit_lowering = "arm64_move_from_x86_mov-zx"
fallback = "zig_movzx_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVZX: zero-extend move
// ARM64: UXTB/UXTH  or  LDRB/LDRH with zero-extension
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVZX zero-extends a smaller operand to a larger destination; ARM64 UXTB/UXTH."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]