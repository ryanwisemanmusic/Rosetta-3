// SHIFT/SHLD.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHIFT/SHLD.inc"
x86_handler = "x86_shld"
neon_lowering = "arm64_shld"
lowering_kind = "arm64_documented_contract"

name = "SHLD"
aliases = []
category = "shift"
feature = "386"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "0F A4 /r ib", form = "SHLD r/m16, r16, imm8", op_en = "MRI", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "0F A5 /r", form = "SHLD r/m16, r16, CL", op_en = "MRC", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "0F A4 /r ib", form = "SHLD r/m32, r32, imm8", op_en = "MRI", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F A4 /r ib", form = "SHLD r/m64, r64, imm8", op_en = "MRI", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "0F A5 /r", form = "SHLD r/m32, r32, CL", op_en = "MRC", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F A5 /r", form = "SHLD r/m64, r64, CL", op_en = "MRC", feature = "386", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  MRI = ["ModRM:r/m (w)", "ModRM:reg (r)", "imm8"],
  MRC = ["ModRM:r/m (w)", "ModRM:reg (r)", "CL"]
}

flags_written = ["CF", "OF", "SF", "ZF", "PF", "AF"]
simd_fp_exceptions = []

semantic_general = """
Shifts destination operand to the left by count bits while shifting bits from source operand in from the right. Used for multi-precision shifts.
"""

handler = "x86_shld"
jit_lowering = "arm64_shld"
fallback = "zig_shld"

neon_register_model = "x86 GP registers mapped to ARM64 X registers."
neon_flag_model = "CF, OF, SF, ZF, PF, AF set per x86 shift semantics via ARM64 shifts + flag synthesis."
neon_assembly = "// ARM64: multiple LSL + ORR or loop"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
