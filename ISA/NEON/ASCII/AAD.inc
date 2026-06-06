// ASCII/AAD.inc
// ARM64/NEON translation mirror generated from ISA/x86/ASCII/AAD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ASCII/AAD.inc"
x86_handler = "x86_ascii_aad"
neon_lowering = "fallback"
lowering_kind = "fallback"


name = "AAD"
category = "ascii_adjust"
opcode = [0xD5, "imm8"]
default_encoding = [0xD5, 0x0A]
op_en = "ZO"
operands = ["imm8"]
valid_modes = ["real16", "protected16", "protected32", "compat"]
invalid_modes = ["long64"]

reads = ["AL", "AH", "imm8"]
writes = ["AL", "AH", "SF", "ZF", "PF"]
flags_written = ["SF", "ZF", "PF"]
flags_undefined = ["OF", "AF", "CF"]

implicit_operands = ["AX", "AL", "AH"]

exceptions = [
  { mode = "any", condition = "lock_prefix", exception = "#UD" },
  { mode = "long64", condition = "always", exception = "#UD" }
]

semantic = """
tempAL = AL;
tempAH = AH;
AL = (tempAL + (tempAH * imm8)) & 0xFF;
AH = 0;
SF = sign8(AL);
ZF = (AL == 0);
PF = parity(AL);
"""

handler = "x86_ascii_aad"
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
