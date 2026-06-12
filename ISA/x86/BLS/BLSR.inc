// BLS/BLSR.inc
// ARM64/NEON translation mirror generated from ISA/x86/BLS/BLSR.inc.
// Source contract: BLSR — Reset Lowest Set Bit.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
BLSR: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: bit_manipulation.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BLS/BLSR.inc"
x86_handler = "x86_blsr"
neon_lowering = "arm64_blsr"
lowering_kind = "arm64_scalar"

name = "BLSR"
aliases = []
category = "bit_manipulation"
feature = "BMI1"
element_type = "u32_u64"
element_size = 32

encodings = [
  { opcode = "VEX.LZ.0F38.W0 F3 /1", form = "BLSR r32, r/m32", op_en = "VM", feature = "BMI1", vector_length = 0, encoding = "vex" },
  { opcode = "VEX.LZ.0F38.W1 F3 /1", form = "BLSR r64, r/m64", op_en = "VM", feature = "BMI1", vector_length = 0, encoding = "vex" }
]

operand_encoding = {
  VM = ["VEX.vvvv (w)", "ModRM:r/m (r)"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = ["SF", "ZF", "CF", "OF"]
simd_fp_exceptions = []
other_exceptions = [
  "See Table 2-29, \"Type 13 Class Exception Conditions.\""
]

semantic_general = """
temp := (SRC-1) bitwiseAND (SRC);
SF := temp[OperandSize -1];
ZF := (temp = 0);
IF SRC = 0
    CF := 1;
ELSE
    CF := 0;
FI
OF := 0;
AF undefined;
PF undefined;
DEST := temp;
"""

handler = "x86_blsr"
jit_lowering = "arm64_blsr"
fallback = "zig_blsr"

neon_register_model = """
x86 general-purpose register mapped to ARM64 xN. BLSR is a scalar bit-manipulation operation with no SIMD or MXCSR state.
"""

neon_flag_model = """
SF, ZF, CF flags are set by the BLSR lowering. OF is cleared. AF and PF are undefined.
"""

neon_assembly = """
// NEON lowering: sub xTMP, xSRC, #1; and xDEST, xTMP, xSRC
// Then set flags: cmp xSRC, #0; cset xCF, eq; ands xDEST, xDEST, xDEST
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64 lowering must not weaken the x86 register, flag, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
