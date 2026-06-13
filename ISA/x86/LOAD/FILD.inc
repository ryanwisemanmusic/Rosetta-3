// LOAD/FILD.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/FILD.inc"
x86_handler = "x86_fild"
neon_lowering = "arm64_fild"
lowering_kind = "arm64_documented_contract"

name = "FILD"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "DF /0", form = "FILD m16int", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DB /0", form = "FILD m32int", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DF /5", form = "FILD m64int", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Converts signed-integer source operand into double extended-precision floating-point format and pushes it onto the FPU register stack. TOP := TOP - 1; ST(0) := ConvertToDoubleExtendedPrecisionFP(SRC). Source can be word, doubleword, or quadword integer. Loaded without rounding errors. Sign preserved.
"""

handler = "x86_fild"
jit_lowering = "arm64_fild"
fallback = "zig_fild"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C1 set on stack overflow."
neon_assembly = "// ARM64: BL rosette_fild"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
