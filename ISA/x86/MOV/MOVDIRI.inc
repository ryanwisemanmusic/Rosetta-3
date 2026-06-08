// MOVDIRI.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVDIRI/MOVDIRI.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVDIRI.inc"
x86_handler = "x86_movdiri"
neon_lowering = "arm64_move_from_x86_mov-diri"
lowering_kind = "arm64_direct_store"

name = "MOVDIRI"
category = "data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F 38 F9 /r", form = "MOVDIRI m32, r32", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movdiri_m32_r32" },
  { opcode = "REX.W + 0F 38 F9 /r", form = "MOVDIRI m64, r64", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_movdiri_m64_r64" },
]

operand_encoding = [
  { op_en = "MR", operand_1 = "ModRM:r/m (w)", operand_2 = "ModRM:reg (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["SRC"]
writes = ["DEST"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
Require CPL == 0;
DirectStore(DEST, SRC);
"""

mode_semantics = """
Direct-store of a doubleword/quadword; bypasses cache hierarchy.
"""

exceptions = {
general = ["#GP", "#PF", "#UD"]
}

handler = "x86_movdiri"
jit_lowering = "arm64_move_from_x86_mov-diri"
fallback = "zig_movdiri_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVDIRI: direct-store doubleword
// ARM64: STR with non-temporal hint (STNP)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVDIRI bypasses cache hierarchy; ARM64 lowering should use non-temporal store hint."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]