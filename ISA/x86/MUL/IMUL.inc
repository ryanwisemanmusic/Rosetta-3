// IMUL.inc
// Signed integer multiply instruction family.
// Covers one-operand, two-operand, and three-operand IMUL forms.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
IMUL: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: integer_multiply.
"""

name = "IMUL"
category = "integer_multiply"
feature = "BASE"
element_type = "signed_integer"
operation_class = "signed_multiply"
lock_prefix = "invalid"

// IMUL has three semantic forms:
//   1. One-operand: implicit accumulator multiply, full-width product.
//   2. Two-operand: DEST = truncate(DEST * SRC).
//   3. Three-operand: DEST = truncate(SRC1 * SRC2).

encodings = [
  // One-operand IMUL: implicit AL/AX/EAX/RAX source and AX/DX:AX/EDX:EAX/RDX:RAX destination.
  { opcode = "F6 /5", form = "IMUL r/m8", op_en = "M", operands = 1, mode64 = "valid", compat = "valid", implicit_src = "AL", implicit_dest = "AX", handler = "x86_imul_rm8" },
  { opcode = "F7 /5", form = "IMUL r/m16", op_en = "M", operands = 1, mode64 = "valid", compat = "valid", implicit_src = "AX", implicit_dest = "DX:AX", handler = "x86_imul_rm16" },
  { opcode = "F7 /5", form = "IMUL r/m32", op_en = "M", operands = 1, mode64 = "valid", compat = "valid", implicit_src = "EAX", implicit_dest = "EDX:EAX", handler = "x86_imul_rm32" },
  { opcode = "REX.W + F7 /5", form = "IMUL r/m64", op_en = "M", operands = 1, mode64 = "valid", compat = "n.e.", implicit_src = "RAX", implicit_dest = "RDX:RAX", handler = "x86_imul_rm64" },

  // Two-operand IMUL: destination register is multiplied by r/m source and truncated back into destination.
  { opcode = "0F AF /r", form = "IMUL r16, r/m16", op_en = "RM", operands = 2, mode64 = "valid", compat = "valid", handler = "x86_imul_r16_rm16" },
  { opcode = "0F AF /r", form = "IMUL r32, r/m32", op_en = "RM", operands = 2, mode64 = "valid", compat = "valid", handler = "x86_imul_r32_rm32" },
  { opcode = "REX.W + 0F AF /r", form = "IMUL r64, r/m64", op_en = "RM", operands = 2, mode64 = "valid", compat = "n.e.", handler = "x86_imul_r64_rm64" },

  // Three-operand IMUL with sign-extended imm8.
  { opcode = "6B /r ib", form = "IMUL r16, r/m16, imm8", op_en = "RMI", operands = 3, immediate = "imm8_sign_extended", mode64 = "valid", compat = "valid", handler = "x86_imul_r16_rm16_imm8" },
  { opcode = "6B /r ib", form = "IMUL r32, r/m32, imm8", op_en = "RMI", operands = 3, immediate = "imm8_sign_extended", mode64 = "valid", compat = "valid", handler = "x86_imul_r32_rm32_imm8" },
  { opcode = "REX.W + 6B /r ib", form = "IMUL r64, r/m64, imm8", op_en = "RMI", operands = 3, immediate = "imm8_sign_extended_to_64", mode64 = "valid", compat = "n.e.", handler = "x86_imul_r64_rm64_imm8" },

  // Three-operand IMUL with operand-size immediate.
  { opcode = "69 /r iw", form = "IMUL r16, r/m16, imm16", op_en = "RMI", operands = 3, immediate = "imm16", mode64 = "valid", compat = "valid", handler = "x86_imul_r16_rm16_imm16" },
  { opcode = "69 /r id", form = "IMUL r32, r/m32, imm32", op_en = "RMI", operands = 3, immediate = "imm32", mode64 = "valid", compat = "valid", handler = "x86_imul_r32_rm32_imm32" },
  { opcode = "REX.W + 69 /r id", form = "IMUL r64, r/m64, imm32", op_en = "RMI", operands = 3, immediate = "imm32_sign_extended_to_64", mode64 = "valid", compat = "n.e.", handler = "x86_imul_r64_rm64_imm32" }
]

operand_encodings = [
  { op_en = "M", operand1 = "ModRM:r/m (r, w)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "RM", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "RMI", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "imm8/16/32", operand4 = "N/A" }
]

notes = [
  "In 64-bit mode, a REX prefix prevents encoding AH, BH, CH, and DH as r/m8 byte registers.",
  "Default operation size in 64-bit mode is 32 bits unless REX.W promotes the operation to 64 bits.",
  "Immediate operands are sign-extended to the destination operand size.",
  "Two- and three-operand forms truncate the intermediate double-width product into the destination register.",
  "The low half of a multiply result is identical for signed and unsigned inputs, but IMUL flags follow signed overflow/truncation rules."
]

semantic_one_operand = """
TMP_XP = signed_multiply(implicit_accumulator, SRC, width = OperandSize * 2);

if OperandSize == 8:
    AX = TMP_XP[15:0];
    CF = OF = (sign_extend(TMP_XP[7:0]) != TMP_XP);
elif OperandSize == 16:
    DX:AX = TMP_XP[31:0];
    CF = OF = (sign_extend(TMP_XP[15:0]) != TMP_XP);
elif OperandSize == 32:
    EDX:EAX = TMP_XP[63:0];
    CF = OF = (sign_extend(TMP_XP[31:0]) != TMP_XP);
else: // OperandSize == 64
    RDX:RAX = TMP_XP[127:0];
    CF = OF = (sign_extend(TMP_XP[63:0]) != TMP_XP);
"""

semantic_two_operand = """
TMP_XP = signed_multiply(DEST, SRC, width = OperandSize * 2);
DEST = truncate_to_operand_size(TMP_XP);
CF = OF = (sign_extend(DEST) != TMP_XP);
"""

semantic_three_operand = """
SRC2 = sign_extend(immediate, OperandSize);
TMP_XP = signed_multiply(SRC1, SRC2, width = OperandSize * 2);
DEST = truncate_to_operand_size(TMP_XP);
CF = OF = (sign_extend(DEST) != TMP_XP);
"""

flags = {
  affected = ["CF", "OF"],
  undefined = ["SF", "ZF", "AF", "PF"],
  rule = "CF and OF are set when the signed product does not fit in the destination size; otherwise cleared."
}

exceptions = {
  protected = ["#GP(0) for segment-limit/null-segment memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"],
  real = ["#GP for segment-limit memory access", "#SS for stack segment limit", "#UD if LOCK prefix is used"],
  v8086 = ["#GP(0) for segment-limit memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"],
  compatibility = ["same as protected mode"],
  mode64 = ["#SS(0) for non-canonical SS memory address", "#GP(0) for non-canonical memory address", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"]
}

handler = "x86_imul"
jit_lowering = "arm64_signed_multiply"
