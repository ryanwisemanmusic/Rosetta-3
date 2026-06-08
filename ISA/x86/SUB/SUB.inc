// SUB.inc
// Integer subtract instruction family.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

name = "SUB"
category = "integer_subtract"
feature = "BASE"
element_type = "integer"
operation_class = "subtract"
lock_prefix = "valid_if_destination_is_memory"

encodings = [
  { opcode = "2C ib", form = "SUB AL, imm8", op_en = "I", mode64 = "valid", compat = "valid", handler = "x86_sub_al_imm8" },
  { opcode = "2D iw", form = "SUB AX, imm16", op_en = "I", mode64 = "valid", compat = "valid", handler = "x86_sub_ax_imm16" },
  { opcode = "2D id", form = "SUB EAX, imm32", op_en = "I", mode64 = "valid", compat = "valid", handler = "x86_sub_eax_imm32" },
  { opcode = "REX.W + 2D id", form = "SUB RAX, imm32", op_en = "I", mode64 = "valid", compat = "n.e.", sign_ext = "imm32_to_64", handler = "x86_sub_rax_imm32" },
  { opcode = "80 /5 ib", form = "SUB r/m8, imm8", op_en = "MI", mode64 = "valid", compat = "valid", handler = "x86_sub_rm8_imm8" },
  { opcode = "REX + 80 /5 ib", form = "SUB r/m8, imm8", op_en = "MI", mode64 = "valid", compat = "n.e.", handler = "x86_sub_rm8_imm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "81 /5 iw", form = "SUB r/m16, imm16", op_en = "MI", mode64 = "valid", compat = "valid", handler = "x86_sub_rm16_imm16" },
  { opcode = "81 /5 id", form = "SUB r/m32, imm32", op_en = "MI", mode64 = "valid", compat = "valid", handler = "x86_sub_rm32_imm32" },
  { opcode = "REX.W + 81 /5 id", form = "SUB r/m64, imm32", op_en = "MI", mode64 = "valid", compat = "n.e.", sign_ext = "imm32_to_64", handler = "x86_sub_rm64_imm32" },
  { opcode = "83 /5 ib", form = "SUB r/m16, imm8", op_en = "MI", mode64 = "valid", compat = "valid", sign_ext = "imm8_to_16", handler = "x86_sub_rm16_imm8" },
  { opcode = "83 /5 ib", form = "SUB r/m32, imm8", op_en = "MI", mode64 = "valid", compat = "valid", sign_ext = "imm8_to_32", handler = "x86_sub_rm32_imm8" },
  { opcode = "REX.W + 83 /5 ib", form = "SUB r/m64, imm8", op_en = "MI", mode64 = "valid", compat = "n.e.", sign_ext = "imm8_to_64", handler = "x86_sub_rm64_imm8" },
  { opcode = "28 /r", form = "SUB r/m8, r8", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_sub_rm8_r8" },
  { opcode = "REX + 28 /r", form = "SUB r/m8, r8", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_sub_rm8_r8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "29 /r", form = "SUB r/m16, r16", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_sub_rm16_r16" },
  { opcode = "29 /r", form = "SUB r/m32, r32", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_sub_rm32_r32" },
  { opcode = "REX.W + 29 /r", form = "SUB r/m64, r64", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_sub_rm64_r64" },
  { opcode = "2A /r", form = "SUB r8, r/m8", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_sub_r8_rm8" },
  { opcode = "REX + 2A /r", form = "SUB r8, r/m8", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_sub_r8_rm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "2B /r", form = "SUB r16, r/m16", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_sub_r16_rm16" },
  { opcode = "2B /r", form = "SUB r32, r/m32", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_sub_r32_rm32" },
  { opcode = "REX.W + 2B /r", form = "SUB r64, r/m64", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_sub_r64_rm64" }
]

operand_encodings = [
  { op_en = "I", operand1 = "AL/AX/EAX/RAX", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "MI", operand1 = "ModRM:r/m (r, w)", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "MR", operand1 = "ModRM:r/m (r, w)", operand2 = "ModRM:reg (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "RM", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" }
]

semantic = """
DEST = DEST - SRC;
"""

flags = {
  affected = ["OF", "SF", "ZF", "AF", "PF", "CF"],
  rule = "All arithmetic status flags are set according to the subtraction result. OF reports signed overflow; CF reports unsigned borrow."
}

notes = [
  "Immediate operands are sign-extended to the destination width when required by the encoding.",
  "Two memory operands cannot be used in one SUB instruction.",
  "Default operation size in 64-bit mode is 32 bits unless REX.W promotes the operation to 64 bits.",
  "LOCK is valid only when the destination operand is memory."
]

exceptions = {
  protected = ["#GP(0) for non-writable destination segment or segment-limit/null-segment memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used and destination is not memory"],
  real = ["#GP for segment-limit memory access", "#SS for stack segment limit", "#UD if LOCK prefix is used and destination is not memory"],
  v8086 = ["#GP(0) for segment-limit memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used and destination is not memory"],
  compatibility = ["same as protected mode"],
  mode64 = ["#SS(0) for non-canonical SS memory address", "#GP(0) for non-canonical memory address", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used and destination is not memory"]
}

handler = "x86_sub"
jit_lowering = "arm64_sub"
