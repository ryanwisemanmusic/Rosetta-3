// MOVBE.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVBE/MOVBE.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVBE.inc"
x86_handler = "x86_movbe"
neon_lowering = "arm64_move_from_x86_mov-be"
lowering_kind = "arm64_byte_swap_move"

name = "MOVBE"
category = "data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F 38 F0 /r", form = "MOVBE r16, m16", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movbe_r16_m16" },
  { opcode = "0F 38 F0 /r", form = "MOVBE r32, m32", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movbe_r32_m32" },
  { opcode = "REX.W + 0F 38 F0 /r", form = "MOVBE r64, m64", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movbe_r64_m64" },
  { opcode = "0F 38 F1 /r", form = "MOVBE m16, r16", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movbe_m16_r16" },
  { opcode = "0F 38 F1 /r", form = "MOVBE m32, r32", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movbe_m32_r32" },
  { opcode = "REX.W + 0F 38 F1 /r", form = "MOVBE m64, r64", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_movbe_m64_r64" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
  { op_en = "MR", operand_1 = "ModRM:r/m (w)", operand_2 = "ModRM:reg (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["SRC"]
writes = ["DEST"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
DEST := byte_swap(SRC);
// MOVBE loads from memory with byte swap or stores to memory with byte swap.
"""

mode_semantics = """
In 64-bit mode, REX.W promotes operation to 64 bits. MOVBE performs a byte swap on the data during the move.
"""

exceptions = {
general = ["#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movbe"
jit_lowering = "arm64_move_from_x86_mov-be"
fallback = "zig_movbe_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVBE: big-endian move
// ARM64: REV16/REV32/REV64 then MOV, or LDR with REV
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVBE performs byte-swap during the move; ARM64 lowering must preserve endianness semantics."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]