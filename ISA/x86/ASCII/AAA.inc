// AAA.inc

name = "AAA"
category = "ascii_adjust"
opcode = [0x37]
op_en = "ZO"
operands = []
valid_modes = ["real16", "protected16", "protected32", "compat"]
invalid_modes = ["long64"]

reads = ["AL", "AH", "AF"]
writes = ["AL", "AH", "AF", "CF"]
flags_set_or_cleared = ["AF", "CF"]
flags_undefined = ["OF", "SF", "ZF", "PF"]
flags_unchanged = []

implicit_operands = ["AL", "AH", "AX"]

exceptions = [
  { mode = "any", condition = "lock_prefix", exception = "#UD" },
  { mode = "long64", condition = "always", exception = "#UD" }
]

semantic = """
if ((AL & 0x0F) > 9 || AF == 1) {
    AX = AX + 0x0106;
    AF = 1;
    CF = 1;
} else {
    AF = 0;
    CF = 0;
}
AL = AL & 0x0F;
"""

handler = "x86_ascii_aaa"
jit_lowering = "fallback"
test_priority = "low_legacy"