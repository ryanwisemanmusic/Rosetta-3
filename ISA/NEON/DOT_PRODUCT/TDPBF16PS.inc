// DOT_PRODUCT/TDPBF16PS.inc
// ARM64/NEON mirror generated from ISA/x86/DOT_PRODUCT/TDPBF16PS.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "DOT_PRODUCT/TDPBF16PS.inc"
x86_handler = "x86_tdpbf16ps"
neon_lowering = "arm64_tdpbf16ps"
lowering_kind = "arm64_documented_contract"

name = "TDPBF16PS"
aliases = []
category = "dot_product"
feature = "AMX-BF16"
element_type = "bf16"
element_size = 16

encodings = [
  { opcode = "VEX.128.F3.0F38.W0 5C 11:rrr:bbb", form = "TDPBF16PS tmm1, tmm2, tmm3", op_en = "A", feature = "AMX-BF16", vector_length = 0, encoding = "vex" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "VEX.vvvv (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Matrix multiply BF16 elements from tmm2 and tmm3, accumulating packed single precision results in tmm1.
"""

handler = "x86_tdpbf16ps"
jit_lowering = "arm64_tdpbf16ps"
fallback = "zig_tdpbf16ps"

neon_register_model = "x86 AMX tile registers mapped to ARM64 matrix or SME registers."
neon_flag_model = "No x86 flags modified by TDPBF16PS."
neon_assembly = "// ARM64: SME matrix multiply or SVE dot product"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
