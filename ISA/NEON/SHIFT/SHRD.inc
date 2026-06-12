// SHIFT/SHRD.inc
// ARM64/NEON mirror generated from ISA/x86/SHIFT/SHRD.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHIFT/SHRD.inc"
x86_handler = "x86_shrd"
neon_lowering = "arm64_shrd"
lowering_kind = "arm64_documented_contract"

name = "SHRD"
aliases = []
category = "shift"
feature = "386"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "0F AC /r ib", form = "SHRD r/m16, r16, imm8", op_en = "MRI", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "0F AD /r", form = "SHRD r/m16, r16, CL", op_en = "MRC", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "0F AC /r ib", form = "SHRD r/m32, r32, imm8", op_en = "MRI", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F AC /r ib", form = "SHRD r/m64, r64, imm8", op_en = "MRI", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "0F AD /r", form = "SHRD r/m32, r32, CL", op_en = "MRC", feature = "386", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F AD /r", form = "SHRD r/m64, r64, CL", op_en = "MRC", feature = "386", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  MRI = ["ModRM:r/m (w)", "ModRM:reg (r)", "imm8"],
  MRC = ["ModRM:r/m (w)", "ModRM:reg (r)", "CL"]
}

flags_written = ["CF", "OF", "SF", "ZF", "PF", "AF"]
simd_fp_exceptions = []

semantic_general = """
Shifts destination operand to the right by count bits while shifting bits from source operand in from the left. Used for multi-precision shifts.
"""

handler = "x86_shrd"
jit_lowering = "arm64_shrd"
fallback = "zig_shrd"

neon_register_model = "x86 GP registers mapped to ARM64 X registers."
neon_flag_model = "CF, OF, SF, ZF, PF, AF set per x86 shift semantics via ARM64 shifts + flag synthesis."
neon_assembly = "// ARM64: multiple LSR + ORR or loop"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
