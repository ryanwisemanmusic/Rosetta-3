// ADOX.inc

name = "ADOX"
category = "adx_overflow_chain"
feature = "ADX"
operation = "dest = dest + src + OF"

encodings = [
  { opcode = "F3 0F 38 F6 /r", form = "ADOX r32, r/m32", op_en = "RM" },
  { opcode = "F3 REX.W 0F 38 F6 /r", form = "ADOX r64, r/m64", op_en = "RM" }
]

reads = ["DEST", "SRC", "OF"]
writes = ["DEST", "OF"]
flags_written = ["OF"]
flags_unchanged = ["CF", "SF", "ZF", "AF", "PF"]

semantic = """
carry = OF ? 1 : 0;
wide = DEST + SRC + carry;
DEST = truncate(wide, operand_size);
OF = carry_out_unsigned(wide, operand_size);
"""

exceptions = [
  { condition = "LOCK prefix used", exception = "#UD" },
  { condition = "CPUID ADX unavailable", exception = "#UD" }
]

handler = "x86_adox"
jit_lowering = "fallback"