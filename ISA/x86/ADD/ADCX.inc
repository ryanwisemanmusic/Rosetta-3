// ADCX.inc

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