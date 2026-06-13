// LOAD/FLDL2T.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/FLDL2T.inc.
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/FLDL2T.inc"
x86_handler = "x86_fldl2t"
neon_lowering = "arm64_fldl2t"
lowering_kind = "arm64_documented_contract"

name = "FLDL2T"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "D9 E9", form = "FLDL2T", op_en = "ZO", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Pushes log2(10) onto FPU register stack. TOP := TOP - 1; ST(0) := log2(10). The constant is rounded to double extended-precision floating-point format according to the RC field. No inexact-result exception is generated.
"""

handler = "x86_fldl2t"
jit_lowering = "arm64_fldl2t"
fallback = "zig_fldl2t"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C1 set on stack overflow."
neon_assembly = "// ARM64: BL rosette_fldl2t"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
