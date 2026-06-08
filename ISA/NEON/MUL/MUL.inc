// MUL/MUL.inc
// ARM64/NEON translation mirror generated from ISA/x86/MUL/MUL.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MUL/MUL.inc"
x86_handler = "x86_mul"
neon_lowering = "arm64_unsigned_multiply"
lowering_kind = "arm64_scalar"


name = "MUL"
category = "integer_multiply"
feature = "BASE"
element_type = "unsigned_integer"
operation_class = "unsigned_multiply"
lock_prefix = "invalid"


encodings = [
  { opcode = "F6 /4", form = "MUL r/m8", op_en = "M", mode64 = "valid", compat = "valid", implicit_src = "AL", implicit_dest = "AX", handler = "x86_mul_rm8" },
  { opcode = "REX + F6 /4", form = "MUL r/m8", op_en = "M", mode64 = "valid", compat = "n.e.", implicit_src = "AL", implicit_dest = "AX", handler = "x86_mul_rm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "F7 /4", form = "MUL r/m16", op_en = "M", mode64 = "valid", compat = "valid", implicit_src = "AX", implicit_dest = "DX:AX", handler = "x86_mul_rm16" },
  { opcode = "F7 /4", form = "MUL r/m32", op_en = "M", mode64 = "valid", compat = "valid", implicit_src = "EAX", implicit_dest = "EDX:EAX", handler = "x86_mul_rm32" },
  { opcode = "REX.W + F7 /4", form = "MUL r/m64", op_en = "M", mode64 = "valid", compat = "n.e.", implicit_src = "RAX", implicit_dest = "RDX:RAX", handler = "x86_mul_rm64" }
]

operand_encodings = [
  { op_en = "M", operand1 = "ModRM:r/m (r)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
]

result_map = [
  { operand_size = 8, source1 = "AL", source2 = "r/m8", destination = "AX", high_half = "AH" },
  { operand_size = 16, source1 = "AX", source2 = "r/m16", destination = "DX:AX", high_half = "DX" },
  { operand_size = 32, source1 = "EAX", source2 = "r/m32", destination = "EDX:EAX", high_half = "EDX" },
  { operand_size = 64, source1 = "RAX", source2 = "r/m64", destination = "RDX:RAX", high_half = "RDX" }
]

notes = [
  "In 64-bit mode, a REX prefix prevents encoding AH, BH, CH, and DH as r/m8 byte registers.",
  "Default operation size in 64-bit mode is 32 bits unless REX.W promotes the operation to 64 bits.",
  "MUL stores the full double-width unsigned product in the implicit accumulator pair.",
  "CF and OF are cleared only when the high half of the product is zero."
]

semantic = """
if OperandSize == 8:
    AX = unsigned_multiply(AL, SRC, width = 16);
    CF = OF = (AH != 0);
elif OperandSize == 16:
    DX:AX = unsigned_multiply(AX, SRC, width = 32);
    CF = OF = (DX != 0);
elif OperandSize == 32:
    EDX:EAX = unsigned_multiply(EAX, SRC, width = 64);
    CF = OF = (EDX != 0);
else: // OperandSize == 64
    RDX:RAX = unsigned_multiply(RAX, SRC, width = 128);
    CF = OF = (RDX != 0);
"""

flags = {
  affected = ["CF", "OF"],
  undefined = ["SF", "ZF", "AF", "PF"],
  rule = "CF and OF are set if the upper half of the product is non-zero; otherwise cleared."
}

exceptions = {
  protected = ["#GP(0) for segment-limit/null-segment memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"],
  real = ["#GP for segment-limit memory access", "#SS for stack segment limit", "#UD if LOCK prefix is used"],
  v8086 = ["#GP(0) for segment-limit memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used"],
  compatibility = ["same as protected mode"],
  mode64 = ["#SS(0) for non-canonical SS memory address", "#GP(0) for non-canonical memory address", "#PF(fault-code)", "#AC(0)"]
}

handler = "x86_mul"
jit_lowering = "arm64_unsigned_multiply"


neon_register_model = """
x86 implicit accumulator/high-half register pairs are mapped to ARM64 low/high product temporaries before writeback.
"""

neon_flag_model = """
x86 CF/OF are derived from high-half/truncation rules; undefined flags remain unspecified.
"""

neon_assembly = """
umulh xHI, xN, xM
mul xLO, xN, xM
bl rosette_pack_x86_mul_flags
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
