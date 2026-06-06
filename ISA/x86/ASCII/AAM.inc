// AAM.inc

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