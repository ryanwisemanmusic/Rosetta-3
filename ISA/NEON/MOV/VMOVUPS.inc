// MOV/VMOVUPS.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/VMOVUPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/VMOVUPS.inc"
x86_handler = "x86_movups"
neon_lowering = "arm64_move_from_x86_mov-ups"
lowering_kind = "arm64_documented_contract"

// VMOVUPS.inc
// Generated documented alias from ISA/x86/MOV/MOVUPS.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

name = "VMOVUPS"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVUPS"

encodings = [
  { opcode = "see MOV/MOVUPS.inc", form = "VMOVUPS documented alias of MOVUPS", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovups" },
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
VMOVUPS is documented as an alias or width-specialized form of MOVUPS.
Execute the matching MOVUPS source-contract form exactly.
"""

source_contract = """
// MOVUPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVUPS/MOVUPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVUPS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVUPS"

encodings = [
  { opcode = "0F 10 /r", form = "MOVUPS xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movups_xmm_xmmm128" },
  { opcode = "0F 11 /r", form = "MOVUPS xmm2/m128, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movups_xmmm128_xmm" },
  { opcode = "VEX.128.0F 10 /r", form = "VMOVUPS xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovups_xmm_xmmm128" },
  { opcode = "VEX.256.0F 10 /r", form = "VMOVUPS ymm1, ymm2/m256", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovups_ymm_ymmm256" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
  { op_en = "MR", operand_1 = "ModRM:r/m (w)", operand_2 = "ModRM:reg (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["xmm2_or_m128"]
writes = ["xmm1"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
DEST := SRC;
No alignment requirement;
"""

mode_semantics = """
Unaligned packed single-precision move. No alignment requirement for memory access.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movups"
jit_lowering = "arm64_move_from_x86_mov-ups"
fallback = "zig_movups_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVUPS: unaligned single-precision move
// ARM64: LD1 { v0.4s }, [x0]  or  ST1 { v0.4s }, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVUPS does not require alignment; ARM64 LD1/ST1 handles unaligned addresses."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovups"
jit_lowering = "arm64_documented_alias_from_x86_vmovups"
fallback = "zig_vmovups_fallback"


