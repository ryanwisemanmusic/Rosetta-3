// ASCII/AAM.inc
// ARM64/NEON translation mirror generated from ISA/x86/ASCII/AAM.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
encodings = [
  { opcode = "see preserved_source_contract", form = "AAM documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_aam" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ASCII/AAM.inc"
x86_handler = "x86_ascii_aam"
neon_lowering = "fallback"
lowering_kind = "fallback"


name = "AAM"
category = "ascii_adjust"
opcode = [0xD4, "imm8"]
default_encoding = [0xD4, 0x0A]
op_en = "ZO"
operands = ["imm8"]
valid_modes = ["real16", "protected16", "protected32", "compat"]
invalid_modes = ["long64"]

reads = ["AL", "imm8"]
writes = ["AH", "AL", "SF", "ZF", "PF"]
flags_written = ["SF", "ZF", "PF"]
flags_undefined = ["OF", "AF", "CF"]

implicit_operands = ["AX", "AL", "AH"]

exceptions = [
  { mode = "any", condition = "imm8 == 0", exception = "#DE" },
  { mode = "any", condition = "lock_prefix", exception = "#UD" },
  { mode = "long64", condition = "always", exception = "#UD" }
]

semantic = """
if (imm8 == 0) raise(#DE);
tempAL = AL;
AH = tempAL / imm8;
AL = tempAL % imm8;
SF = sign8(AL);
ZF = (AL == 0);
PF = parity(AL);
"""

handler = "x86_ascii_aam"
jit_lowering = "fallback"
test_priority = "low_legacy"

neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback.
"""

neon_flag_model = """
Flags are delegated to the x86 fallback interpreter for legacy or unsupported lowering.
"""

neon_assembly = """
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
