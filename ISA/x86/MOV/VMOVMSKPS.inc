// VMOVMSKPS.inc
// Generated documented alias from ISA/x86/MOV/MOVMSKPS.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

source_isa = "x86"
name = "VMOVMSKPS"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVMSKPS"

encodings = [
  { opcode = "see MOV/MOVMSKPS.inc", form = "VMOVMSKPS documented alias of MOVMSKPS", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovmskps" },
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
VMOVMSKPS is documented as an alias or width-specialized form of MOVMSKPS.
Execute the matching MOVMSKPS source-contract form exactly.
"""

source_contract = """
// MOVMSKPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVMSKPS/MOVMSKPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVMSKPS.inc"
x86_handler = "x86_movmskps"
neon_lowering = "arm64_move_from_x86_mov-mskps"
lowering_kind = "arm64_simd_extract"

name = "MOVMSKPS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F 50 /r", form = "MOVMSKPS r32, xmm2", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movmskps_r32_xmm" },
  { opcode = "VEX.256.0F 50 /r", form = "VMOVMSKPS r32, ymm2", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovmskps_r32_ymm" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["xmm2_or_ymm2"]
writes = ["r32"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
r32[0] := xmm2[31];
r32[1] := xmm2[63];
r32[2] := xmm2[95];
r32[3] := xmm2[127];
"""

mode_semantics = """
Extracts the sign bits of each packed single-precision value into a GPR.
"""

exceptions = {
simd = ["#UD"]
}

handler = "x86_movmskps"
jit_lowering = "arm64_move_from_x86_mov-mskps"
fallback = "zig_movmskps_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVMSKPS: extract sign mask from packed single
// ARM64: SSHR + MOV + ORR to extract 4 sign bits into GPR
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVMSKPS moves sign bits to a GPR; ARM64 lowering must extract and pack sign bits."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovmskps"
jit_lowering = "arm64_documented_alias_from_x86_vmovmskps"
fallback = "zig_vmovmskps_fallback"
