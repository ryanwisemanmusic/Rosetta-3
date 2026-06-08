// MOV/VMOVD.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/VMOVD.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/VMOVD.inc"
x86_handler = "x86_movd"
neon_lowering = "arm64_move_from_x86_mov-d"
lowering_kind = "arm64_documented_contract"

// VMOVD.inc
// Generated documented alias from ISA/x86/MOV/MOVD.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

name = "VMOVD"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVD"

encodings = [
  { opcode = "see MOV/MOVD.inc", form = "VMOVD documented alias of MOVD", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovd" },
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
VMOVD is documented as an alias or width-specialized form of MOVD.
Execute the matching MOVD source-contract form exactly.
"""

source_contract = """
// MOVD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVD/MOVD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVD"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVD"

encodings = [
  { opcode = "66 0F 6E /r", form = "MOVD xmm1, r32/m32", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movd_xmm_r32m32" },
  { opcode = "66 0F 7E /r", form = "MOVD r32/m32, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movd_r32m32_xmm" },
  { opcode = "0F 6E /r", form = "MOVD mm1, r32/m32", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movd_mmx_r32m32" },
  { opcode = "0F 7E /r", form = "MOVD r32/m32, mm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movd_r32m32_mmx" },
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
// MOVD moves a 32-bit doubleword between GPR/MMX/XMM and another GPR/MMX/XMM or memory.
"""

mode_semantics = """
In 64-bit mode, a REX.W prefix promotes MOVD to MOVQ (64-bit operation).
"""

exceptions = {
simd = ["#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movd"
jit_lowering = "arm64_move_from_x86_mov-d"
fallback = "zig_movd_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVD: move 32-bit between GPR and SIMD
// ARM64: FMOV S0, W0  or  MOV W0, V0.S[0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVD transfers 32 bits between GPR and SIMD registers; ARM64 FMOV Sd, Wn / MOV Wd, Vn.S[0]."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovd"
jit_lowering = "arm64_documented_alias_from_x86_vmovd"
fallback = "zig_vmovd_fallback"


