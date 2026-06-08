// MOV/MOVNTI.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVNTI.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVNTI.inc"
x86_handler = "x86_movnti"
neon_lowering = "arm64_move_from_x86_mov-nti"
lowering_kind = "arm64_documented_contract"

// MOVNTI.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVNTI/MOVNTI.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVNTI"
category = "data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F C3 /r", form = "MOVNTI m32, r32", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movnti_m32_r32" },
  { opcode = "REX.W + 0F C3 /r", form = "MOVNTI m64, r64", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_movnti_m64_r64" },
]

operand_encoding = [
  { op_en = "MR", operand_1 = "ModRM:r/m (w)", operand_2 = "ModRM:reg (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["r32"]
writes = ["m32"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
NonTemporalStore(DEST, SRC);
"""

mode_semantics = """
Non-temporal store of a doubleword/quadword.
"""

exceptions = {
general = ["#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movnti"
jit_lowering = "arm64_move_from_x86_mov-nti"
fallback = "zig_movnti_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVNTI: non-temporal integer store
// ARM64: STTR or STLR (store with release/non-temporal hint)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVNTI bypasses cache; ARM64 STLR or STNP with non-temporal hint."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
