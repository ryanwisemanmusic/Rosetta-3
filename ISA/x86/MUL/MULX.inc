// MULX.inc
// Unsigned multiply without affecting flags (BMI2).
// Multiplies r/m with EDX/RDX and stores low half in dest2, high half in dest1.

operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
MULX: preserve the operation and form-specific semantic blocks.
Category: integer_multiply_no_flags.
"""

name = "MULX"
category = "integer_multiply"
feature = "BMI2"
element_type = "unsigned_integer"
operation_class = "unsigned_multiply_no_flags"
lock_prefix = "invalid"

encodings = [
  { opcode = "VEX.LZ.F2.0F38.W0 F6 /r", form = "MULX r32a, r32b, r/m32", op_en = "RVM", mode64 = "valid", compat = "valid", implicit_src = "EDX", handler = "x86_mulx_r32_r32_rm32" },
  { opcode = "VEX.LZ.F2.0F38.W1 F6 /r", form = "MULX r64a, r64b, r/m64", op_en = "RVM", mode64 = "valid", compat = "n.e.", implicit_src = "RDX", handler = "x86_mulx_r64_r64_rm64" }
]

operand_encodings = [
  { op_en = "RVM", operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (w)", operand3 = "ModRM:r/m (r)", operand4 = "EDX/RDX implicit source" }
]

notes = [
  "MULX does not read or write arithmetic flags.",
  "VEX.L must be 0; otherwise #UD.",
  "In 64-bit mode, VEX.W=1 promotes to 64-bit operands.",
  "Not supported in real mode or virtual-8086 mode."
]

semantic = """
SRC1 = EDX (32-bit) or RDX (64-bit);
SRC2 = ModRM:r/m;
DEST2 = (SRC1 * SRC2)[low_half];
DEST1 = (SRC1 * SRC2)[high_half];
"""

flags = {
  affected = [],
  rule = "MULX does not modify any flags."
}

exceptions = {
  protected = ["#GP(0) for segment-limit/null-segment memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used or VEX.L != 0"],
  real = ["#UD (not supported in real mode)"],
  v8086 = ["#UD (not supported in virtual-8086 mode)"],
  compatibility = ["same as protected mode"],
  mode64 = ["#SS(0) for non-canonical SS memory address", "#GP(0) for non-canonical memory address", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used or VEX.L != 0"]
}

handler = "x86_mulx"
jit_lowering = "arm64_unsigned_multiply_no_flags"
