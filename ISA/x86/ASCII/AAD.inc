// AAD.inc

// Canonical table metadata for registry-wide .inc validation.
encodings = [
  { opcode = "see preserved_source_contract", form = "AAD documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_aad" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

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