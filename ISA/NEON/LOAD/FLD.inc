// LOAD/FLD.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/FLD.inc.
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/FLD.inc"
x86_handler = "x86_fld"
neon_lowering = "arm64_fld"
lowering_kind = "arm64_documented_contract"

name = "FLD"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "D9 /0", form = "FLD m32fp", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DD /0", form = "FLD m64fp", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DB /5", form = "FLD m80fp", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "D9 C0+i", form = "FLD ST(i)", op_en = "MI", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"],
  MI = ["ModRM:reg (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Pushes source operand onto FPU register stack. TOP := TOP - 1; ST(0) := SRC. Source can be single (m32fp), double (m64fp), or double extended-precision (m80fp) float, or register ST(i). Single/double operands converted to double extended-precision format. Pushing ST(0) duplicates stack top.
"""

handler = "x86_fld"
jit_lowering = "arm64_fld"
fallback = "zig_fld"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C1 set on stack overflow."
neon_assembly = "// ARM64: BL rosette_fld"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
