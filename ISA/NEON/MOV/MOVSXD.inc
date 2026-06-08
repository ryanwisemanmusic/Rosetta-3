// MOV/MOVSXD.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVSXD.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVSXD.inc"
x86_handler = "x86_movsx"
neon_lowering = "arm64_move_from_x86_mov-sx"
lowering_kind = "arm64_documented_contract"

// MOVSXD.inc
// Generated documented alias from ISA/x86/MOV/MOVSX.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

name = "MOVSXD"
family = "MOV"
category = "data_transfer"
instruction_family = "MOV"
alias_of = "MOVSX"

encodings = [
  { opcode = "see MOV/MOVSX.inc", form = "MOVSXD documented alias of MOVSX", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_movsxd" },
]

operand_encoding = [
  { op_en = "ALIAS", operand_1 = "see source_contract", operand_2 = "see source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["see source_contract"]
writes = ["see source_contract"]
flags_read = []
flags_written = []
flags_affected = []
flags_model = "preserve source_contract flag behavior"
lock_allowed = false

semantic = """
MOVSXD is documented as an alias or width-specialized form of MOVSX.
Execute the matching MOVSX source-contract form exactly.
"""

source_contract = """
// MOVSX.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVSX/MOVSX.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVSX"
category = "data_transfer"
instruction_family = "MOV"
alias_info = "MOVSXD"

encodings = [
  { opcode = "0F BE /r", form = "MOVSX r16, r/m8", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movsx_r16_rm8" },
  { opcode = "0F BE /r", form = "MOVSX r32, r/m8", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movsx_r32_rm8" },
  { opcode = "REX.W + 0F BE /r", form = "MOVSX r64, r/m8", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movsx_r64_rm8" },
  { opcode = "0F BF /r", form = "MOVSX r32, r/m16", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movsx_r32_rm16" },
  { opcode = "REX.W + 0F BF /r", form = "MOVSX r64, r/m16", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movsx_r64_rm16" },
  { opcode = "63 /r", form = "MOVSXD r32, r/m32", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movsxd_r32_rm32" },
  { opcode = "REX.W + 63 /r", form = "MOVSXD r64, r/m32", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movsxd_r64_rm32" },
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
DEST := sign_extend(SRC);
"""

mode_semantics = """
Sign-extends an 8-bit, 16-bit, or 32-bit source to a larger destination size. In 64-bit mode, REX.W extends to 64 bits.
"""

exceptions = {
general = ["#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movsx"
jit_lowering = "arm64_move_from_x86_mov-sx"
fallback = "zig_movsx_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVSX: sign-extend move
// ARM64: SXTB/SXTH/SXTW  or  LDRSB/LDRSH/LDRSW
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVSX sign-extends a smaller operand to a larger destination; ARM64 SXTB/SXTH/SXTW."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_movsxd"
jit_lowering = "arm64_documented_alias_from_x86_movsxd"
fallback = "zig_movsxd_fallback"
