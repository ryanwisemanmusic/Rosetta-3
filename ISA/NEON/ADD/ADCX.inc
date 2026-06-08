// ADD/ADCX.inc
// ARM64/NEON translation mirror generated from ISA/x86/ADD/ADCX.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ADD/ADCX.inc"
x86_handler = "x86_adcx"
neon_lowering = "fallback_or_arm64_adcs_preserve_other_flags"
lowering_kind = "arm64_scalar"


name = "ADCX"
category = "adx_carry_chain"
feature = "ADX"
operation = "dest = dest + src + CF"

encodings = [
  { opcode = "66 0F 38 F6 /r", form = "ADCX r32, r/m32", op_en = "RM" },
  { opcode = "66 REX.W 0F 38 F6 /r", form = "ADCX r64, r/m64", op_en = "RM" }
]

reads = ["DEST", "SRC", "CF"]
writes = ["DEST", "CF"]
flags_written = ["CF"]
flags_unchanged = ["OF", "SF", "ZF", "AF", "PF"]

semantic = """
carry = CF ? 1 : 0;
wide = DEST + SRC + carry;
DEST = truncate(wide, operand_size);
CF = carry_out_unsigned(wide, operand_size);
"""

exceptions = [
  { condition = "LOCK prefix used", exception = "#UD" },
  { condition = "CPUID ADX unavailable", exception = "#UD" }
]

handler = "x86_adcx"
jit_lowering = "fallback_or_arm64_adcs_preserve_other_flags"

neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback.
"""

neon_flag_model = """
ARM64 NZCV is repacked into x86 OF/SF/ZF/AF/CF/PF according to the source table flag contract.
"""

neon_assembly = """
msr nzcv, x86_carry_to_nzcv(CF)
adcs xD, xN, xM
bl rosette_preserve_non_cf_status_flags
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
