// VMOVSLDUP.inc
// Generated documented alias from ISA/x86/MOV/MOVSLDUP.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

source_isa = "x86"
name = "VMOVSLDUP"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVSLDUP"

encodings = [
  { opcode = "see MOV/MOVSLDUP.inc", form = "VMOVSLDUP documented alias of MOVSLDUP", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovsldup" },
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
VMOVSLDUP is documented as an alias or width-specialized form of MOVSLDUP.
Execute the matching MOVSLDUP source-contract form exactly.
"""

source_contract = """
// MOVSLDUP.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVSLDUP/MOVSLDUP.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVSLDUP.inc"
x86_handler = "x86_movsldup"
neon_lowering = "arm64_move_from_x86_mov-sldup"
lowering_kind = "arm64_simd_dup"

name = "MOVSLDUP"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVSLDUP"

encodings = [
  { opcode = "F3 0F 12 /r", form = "MOVSLDUP xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movsldup_xmm_xmmm128" },
  { opcode = "VEX.256.F3.0F 12 /r", form = "VMOVSLDUP ymm1, ymm2/m256", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovsldup_ymm_ymmm256" },
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
// MOVSLDUP: even-indexed single-precision values duplicated
DEST[31:0] := SRC[31:0];
DEST[63:32] := SRC[31:0];
DEST[95:64] := SRC[95:64];
DEST[127:96] := SRC[95:64];
"""

mode_semantics = """
Replicates each even (low) single-precision element into the adjacent odd slot.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movsldup"
jit_lowering = "arm64_move_from_x86_mov-sldup"
fallback = "zig_movsldup_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVSLDUP: single-precision shuffle duplicate low
// ARM64: ZIP1 v0.4s, v1.4s, v1.4s  or  DUP + MOV pattern
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVSLDUP duplicates even-indexed single-precision elements; ARM64 ZIP or TBL."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovsldup"
jit_lowering = "arm64_documented_alias_from_x86_vmovsldup"
fallback = "zig_vmovsldup_fallback"
