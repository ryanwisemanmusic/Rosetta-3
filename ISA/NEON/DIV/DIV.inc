// DIV/DIV.inc
// ARM64/NEON translation mirror generated from ISA/x86/DIV/DIV.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "DIV/DIV.inc"
x86_handler = "x86_div"
neon_lowering = "arm64_unsigned_divide"
lowering_kind = "arm64_scalar"


name = "DIV"
category = "integer_divide"
feature = "BASE"
element_type = "unsigned_integer"
operation_class = "unsigned_divide"
lock_prefix = "invalid"


encodings = [
  { opcode = "F6 /6", form = "DIV r/m8", op_en = "M", mode64 = "valid", compat = "valid", dividend = "AX", divisor = "r/m8", quotient = "AL", remainder = "AH", handler = "x86_div_rm8" },
  { opcode = "REX + F6 /6", form = "DIV r/m8", op_en = "M", mode64 = "valid", compat = "n.e.", dividend = "AX", divisor = "r/m8", quotient = "AL", remainder = "AH", handler = "x86_div_rm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "F7 /6", form = "DIV r/m16", op_en = "M", mode64 = "valid", compat = "valid", dividend = "DX:AX", divisor = "r/m16", quotient = "AX", remainder = "DX", handler = "x86_div_rm16" },
  { opcode = "F7 /6", form = "DIV r/m32", op_en = "M", mode64 = "valid", compat = "valid", dividend = "EDX:EAX", divisor = "r/m32", quotient = "EAX", remainder = "EDX", handler = "x86_div_rm32" },
  { opcode = "REX.W + F7 /6", form = "DIV r/m64", op_en = "M", mode64 = "valid", compat = "n.e.", dividend = "RDX:RAX", divisor = "r/m64", quotient = "RAX", remainder = "RDX", handler = "x86_div_rm64" }
]

operand_encodings = [
  { op_en = "M", operand1 = "ModRM:r/m (r)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
]

result_map = [
  { operand_size = 8, operand_size_name = "Word / byte", dividend = "AX", divisor = "r/m8", quotient = "AL", remainder = "AH", maximum_quotient = 255 },
  { operand_size = 16, operand_size_name = "Doubleword / word", dividend = "DX:AX", divisor = "r/m16", quotient = "AX", remainder = "DX", maximum_quotient = 65535 },
  { operand_size = 32, operand_size_name = "Quadword / doubleword", dividend = "EDX:EAX", divisor = "r/m32", quotient = "EAX", remainder = "EDX", maximum_quotient = "2^32 - 1" },
  { operand_size = 64, operand_size_name = "Doublequadword / quadword", dividend = "RDX:RAX", divisor = "r/m64", quotient = "RAX", remainder = "RDX", maximum_quotient = "2^64 - 1" }
]

notes = [
  "In 64-bit mode, a REX prefix prevents encoding AH, BH, CH, and DH as r/m8 byte registers.",
  "Default operation size in 64-bit mode is 32 bits unless REX.W promotes the operation to 64 bits.",
  "DIV performs unsigned division using an implicit double-width dividend.",
  "64-bit DIV is only available in 64-bit mode through REX.W + F7 /6.",
  "Non-integral results are truncated toward zero.",
  "The remainder magnitude is always less than the divisor magnitude.",
  "Divide-by-zero or quotient overflow raises #DE instead of setting CF or OF."
]

semantic = """
if SRC == 0:
    raise #DE;

if OperandSize == 8:
    temp = unsigned_divide(AX, SRC);
    if temp > 0xFF:
        raise #DE;
    AL = temp;
    AH = AX % SRC;
elif OperandSize == 16:
    temp = unsigned_divide(DX:AX, SRC);
    if temp > 0xFFFF:
        raise #DE;
    AX = temp;
    DX = (DX:AX) % SRC;
elif OperandSize == 32:
    temp = unsigned_divide(EDX:EAX, SRC);
    if temp > 0xFFFFFFFF:
        raise #DE;
    EAX = temp;
    EDX = (EDX:EAX) % SRC;
else: // 64-bit mode and OperandSize == 64
    temp = unsigned_divide(RDX:RAX, SRC);
    if temp > 0xFFFFFFFFFFFFFFFF:
        raise #DE;
    RAX = temp;
    RDX = (RDX:RAX) % SRC;
"""

flags = {
  undefined = ["CF", "OF", "SF", "ZF", "AF", "PF"],
  rule = "All listed status flags are undefined after DIV. Divide errors are reported with #DE."
}

exceptions = {
  protected = ["#DE if divisor is zero", "#DE if quotient is too large for destination", "#GP(0) for segment-limit/null-segment memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"],
  real = ["#DE if divisor is zero", "#DE if quotient is too large for destination", "#GP for segment-limit/null-segment memory access", "#SS(0) for stack segment limit", "#UD if LOCK prefix is used"],
  v8086 = ["#DE if divisor is zero", "#DE if quotient is too large for destination", "#GP(0) for segment-limit memory access", "#SS for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"],
  compatibility = ["same as protected mode"],
  mode64 = ["#SS(0) for non-canonical SS memory address", "#GP(0) for non-canonical memory address", "#DE if divisor is zero", "#DE if quotient is too large for destination", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"]
}

handler = "x86_div"
jit_lowering = "arm64_unsigned_divide"


neon_register_model = """
x86 implicit dividend/quotient/remainder registers are staged in ARM64 temporaries before writeback.
"""

neon_flag_model = """
x86 DIV/IDIV undefined flags remain undefined; #DE is raised for zero divisors or quotient overflow.
"""

neon_assembly = """
cbz xDIVISOR, rosette_raise_de
udiv xQ, xDIVIDEND, xDIVISOR
msub xR, xQ, xDIVISOR, xDIVIDEND
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
