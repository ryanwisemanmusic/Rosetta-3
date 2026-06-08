// VMOVLPD.inc
// Generated documented alias from ISA/x86/MOV/MOVLPD.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

source_isa = "x86"
name = "VMOVLPD"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVLPD"

encodings = [
  { opcode = "see MOV/MOVLPD.inc", form = "VMOVLPD documented alias of MOVLPD", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovlpd" },
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
VMOVLPD is documented as an alias or width-specialized form of MOVLPD.
Execute the matching MOVLPD source-contract form exactly.
"""

source_contract = """
// MOVLPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVLPD/MOVLPD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVLPD.inc"
x86_handler = "x86_movlpd"
neon_lowering = "arm64_move_from_x86_mov-lpd"
lowering_kind = "arm64_simd_move"

name = "MOVLPD"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "66 0F 12 /r", form = "MOVLPD xmm1, m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movlpd_xmm_m64" },
  { opcode = "66 0F 13 /r", form = "MOVLPD m64, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movlpd_m64_xmm" },
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
// MOVLPD load: xmm1[63:0] := m64;
xmm1[127:64] unchanged;
// MOVLPD store: m64 := xmm1[63:0];
"""

mode_semantics = """
Load/store the lower 64-bit double-precision value of an XMM register from/to memory.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movlpd"
jit_lowering = "arm64_move_from_x86_mov-lpd"
fallback = "zig_movlpd_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVLPD: low quadword double-precision load/store
// ARM64 load: LD1 { v0.d[0] }, [x0]
// ARM64 store: ST1 { v0.d[0] }, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVLPD accesses the lower 64 bits of an XMM register; ARM64 LD1/ST1 with lane index 0."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovlpd"
jit_lowering = "arm64_documented_alias_from_x86_vmovlpd"
fallback = "zig_vmovlpd_fallback"
