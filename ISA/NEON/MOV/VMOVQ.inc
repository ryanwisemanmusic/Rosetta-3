// MOV/VMOVQ.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/VMOVQ.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/VMOVQ.inc"
x86_handler = "x86_movq"
neon_lowering = "arm64_move_from_x86_mov-q"
lowering_kind = "arm64_documented_contract"

// VMOVQ.inc
// Generated documented alias from ISA/x86/MOV/MOVQ.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

name = "VMOVQ"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVQ"

encodings = [
  { opcode = "see MOV/MOVQ.inc", form = "VMOVQ documented alias of MOVQ", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovq" },
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
VMOVQ is documented as an alias or width-specialized form of MOVQ.
Execute the matching MOVQ source-contract form exactly.
"""

source_contract = """
// MOVQ.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVQ/MOVQ.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVQ"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVQ"

encodings = [
  { opcode = "F3 0F 7E /r", form = "MOVQ xmm1, xmm2/m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movq_xmm_xmmm64" },
  { opcode = "66 0F D6 /r", form = "MOVQ xmm2/m64, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movq_xmmm64_xmm" },
  { opcode = "0F 6F /r", form = "MOVQ mm1, mm2/m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movq_mmx_mmmm64" },
  { opcode = "0F 7F /r", form = "MOVQ mm2/m64, mm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movq_mmmm64_mmx" },
  { opcode = "REX.W + 8B /r", form = "MOVQ r64, r/m64", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_movq_r64_rm64" },
  { opcode = "REX.W + 89 /r", form = "MOVQ r/m64, r64", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_movq_rm64_r64" },
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
DEST := SRC;
// MOVQ moves a 64-bit quadword between GPR/MMX/XMM registers or memory.
"""

mode_semantics = """
MOVQ with REX.W promotes to 64-bit GPR move. MOVQ between XMM registers zeros the upper 64 bits.
"""

exceptions = {
simd = ["#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movq"
jit_lowering = "arm64_move_from_x86_mov-q"
fallback = "zig_movq_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVQ: move 64 bits
// ARM64: FMOV D0, X0  or  MOV X0, V0.d[0]  or  MOV v0.d[0], x0
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVQ transfers 64 bits; ARM64 FMOV Dn, Xn / MOV Xn, Vn.d[0] / INS."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovq"
jit_lowering = "arm64_documented_alias_from_x86_vmovq"
fallback = "zig_vmovq_fallback"


