// MOV/VMOVLHPS.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/VMOVLHPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/VMOVLHPS.inc"
x86_handler = "x86_movlhps"
neon_lowering = "arm64_move_from_x86_mov-lhps"
lowering_kind = "arm64_documented_contract"

// VMOVLHPS.inc
// Generated documented alias from ISA/x86/MOV/MOVLHPS.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

name = "VMOVLHPS"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVLHPS"

encodings = [
  { opcode = "see MOV/MOVLHPS.inc", form = "VMOVLHPS documented alias of MOVLHPS", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovlhps" },
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
VMOVLHPS is documented as an alias or width-specialized form of MOVLHPS.
Execute the matching MOVLHPS source-contract form exactly.
"""

source_contract = """
// MOVLHPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVLHPS/MOVLHPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVLHPS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F 16 /r", form = "MOVLHPS xmm1, xmm2", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movlhps_xmm_xmm" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["xmm1", "xmm2"]
writes = ["xmm1"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
xmm1[127:64] := xmm2[63:0];
xmm1[63:0] unchanged;
"""

mode_semantics = """
Moves the lower 64 bits of xmm2 to the upper 64 bits of xmm1.
"""

exceptions = {
simd = ["#UD"]
}

handler = "x86_movlhps"
jit_lowering = "arm64_move_from_x86_mov-lhps"
fallback = "zig_movlhps_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVLHPS: low-to-high packed single
// ARM64: MOV v0.d[1], v1.d[0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVLHPS copies lower half of source to upper half of destination; ARM64 INS."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovlhps"
jit_lowering = "arm64_documented_alias_from_x86_vmovlhps"
fallback = "zig_vmovlhps_fallback"


