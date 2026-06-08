// MOVDIR64B.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVDIR64B/MOVDIR64B.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVDIR64B.inc"
x86_handler = "x86_movdir64b"
neon_lowering = "arm64_move_from_x86_mov-dir64b"
lowering_kind = "arm64_direct_store"

name = "MOVDIR64B"
category = "data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "66 0F 38 F8 /r", form = "MOVDIR64B r64, m512", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movdir64b_r64_m512" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (r)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["SRC"]
writes = ["DEST"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
Require DEST 64-byte aligned;
Require CPL == 0;
DirectStore(DEST, SRC[511:0]);
"""

mode_semantics = """
Direct-store: processor does not write to cache hierarchy. Destination must be 64-byte aligned. Source is 64 bytes of memory.
"""

exceptions = {
general = ["#GP", "#PF", "#UD"]
}

handler = "x86_movdir64b"
jit_lowering = "arm64_move_from_x86_mov-dir64b"
fallback = "zig_movdir64b_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVDIR64B: 64-byte direct store (write-combining)
// ARM64: STNP or STP with non-cacheable hint; emulated via memcpy with DC ZVA
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVDIR64B uses write-combining protocol; ARM64 lowering may emulate with DC ZVA or non-temporal stores."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]