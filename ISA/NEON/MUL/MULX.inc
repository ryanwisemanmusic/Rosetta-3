// MUL/MULX.inc
// ARM64/NEON translation mirror generated from ISA/x86/MUL/MULX.inc.

operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
MULX: preserve the operation and form-specific semantic blocks.
Category: integer_multiply_no_flags.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MUL/MULX.inc"
x86_handler = "x86_mulx"
neon_lowering = "arm64_unsigned_multiply_no_flags"
lowering_kind = "arm64_scalar"

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

neon_register_model = """
x86 implicit EDX/RDX source and explicit register destinations are mapped through the Rosette register file.
"""

neon_flag_model = """
MULX does not affect any flags; no flag emulation required.
"""

neon_assembly = """
mul xLO, xN, xM
umulh xHI, xN, xM
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
