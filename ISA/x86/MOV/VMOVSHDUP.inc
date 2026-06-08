// VMOVSHDUP.inc
// Generated documented alias from ISA/x86/MOV/MOVSHDUP.inc.
// The source contract below preserves the base instruction table that documents this mnemonic.

source_isa = "x86"
name = "VMOVSHDUP"
family = "MOV"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_of = "MOVSHDUP"

encodings = [
  { opcode = "see MOV/MOVSHDUP.inc", form = "VMOVSHDUP documented alias of MOVSHDUP", op_en = "ALIAS", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_vmovshdup" },
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
VMOVSHDUP is documented as an alias or width-specialized form of MOVSHDUP.
Execute the matching MOVSHDUP source-contract form exactly.
"""

source_contract = """
// MOVSHDUP.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVSHDUP/MOVSHDUP.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVSHDUP.inc"
x86_handler = "x86_movshdup"
neon_lowering = "arm64_move_from_x86_mov-shdup"
lowering_kind = "arm64_simd_dup"

name = "MOVSHDUP"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVSHDUP"

encodings = [
  { opcode = "F3 0F 16 /r", form = "MOVSHDUP xmm1, xmm2/m128", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movshdup_xmm_xmmm128" },
  { opcode = "VEX.256.F3.0F 16 /r", form = "VMOVSHDUP ymm1, ymm2/m256", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_vmovshdup_ymm_ymmm256" },
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
// MOVSHDUP: odd-indexed single-precision values duplicated
DEST[31:0] := SRC[63:32];
DEST[63:32] := SRC[63:32];
DEST[95:64] := SRC[127:96];
DEST[127:96] := SRC[127:96];
"""

mode_semantics = """
Replicates each odd (high) single-precision element into the adjacent even slot.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movshdup"
jit_lowering = "arm64_move_from_x86_mov-shdup"
fallback = "zig_movshdup_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVSHDUP: single-precision shuffle duplicate high
// ARM64: ZIP1 v0.4s, v1.4s, v1.4s  or  MOV + DUP pattern
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVSHDUP duplicates odd-indexed single-precision elements; ARM64 ZIP or TBL."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
"""

handler = "x86_vmovshdup"
jit_lowering = "arm64_documented_alias_from_x86_vmovshdup"
fallback = "zig_vmovshdup_fallback"
