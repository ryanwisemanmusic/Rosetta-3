// ADD.inc

name = "ADD"
category = "integer_arithmetic"
operation = "dest = dest + src"

encodings = [
  { opcode = "04 ib", form = "ADD AL, imm8", op_en = "I" },
  { opcode = "05 iw", form = "ADD AX, imm16", op_en = "I" },
  { opcode = "05 id", form = "ADD EAX, imm32", op_en = "I" },
  { opcode = "80 /0 ib", form = "ADD r/m8, imm8", op_en = "MI" },
  { opcode = "81 /0 iw", form = "ADD r/m16, imm16", op_en = "MI" },
  { opcode = "81 /0 id", form = "ADD r/m32, imm32", op_en = "MI" },
  { opcode = "83 /0 ib", form = "ADD r/m16|r/m32, imm8", op_en = "MI", imm = "sign_extend" },
  { opcode = "00 /r", form = "ADD r/m8, r8", op_en = "MR" },
  { opcode = "01 /r", form = "ADD r/m16|r/m32, r16|r32", op_en = "MR" },
  { opcode = "02 /r", form = "ADD r8, r/m8", op_en = "RM" },
  { opcode = "03 /r", form = "ADD r16|r32, r/m16|r/m32", op_en = "RM" }
]

reads = ["DEST", "SRC"]
writes = ["DEST"]
flags_written = ["OF", "SF", "ZF", "AF", "CF", "PF"]

lock_allowed = "only_if_dest_is_memory"

semantic = """
result = DEST + SRC;
DEST = truncate(result, operand_size);
update_add_flags(DEST_old, SRC, result, operand_size);
"""

handler = "x86_add"
jit_lowering = "arm64_add_with_x86_flags"