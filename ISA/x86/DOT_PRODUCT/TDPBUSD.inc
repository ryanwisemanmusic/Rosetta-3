// DOT_PRODUCT/TDPBUSD.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "DOT_PRODUCT/TDPBUSD.inc"
x86_handler = "x86_tdpbusd"
neon_lowering = "arm64_tdpbusd"
lowering_kind = "arm64_documented_contract"

name = "TDPBUSD"
aliases = []
category = "dot_product"
feature = "AMX-INT8"
element_type = "u8"
element_size = 8

encodings = [
  { opcode = "VEX.128.66.0F38.W0 5E 11:rrr:bbb", form = "TDPBUSD tmm1, tmm2, tmm3", op_en = "A", feature = "AMX-INT8", vector_length = 0, encoding = "vex" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "VEX.vvvv (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Matrix multiply unsigned byte elements from tmm2 by signed byte elements from tmm3, accumulate dword results in tmm1.
"""

handler = "x86_tdpbusd"
jit_lowering = "arm64_tdpbusd"
fallback = "zig_tdpbusd"

neon_register_model = "x86 AMX tile registers mapped to ARM64 matrix or SME registers."
neon_flag_model = "No x86 flags modified by TDPBUSD."
neon_assembly = "// ARM64: SME matrix multiply or SVE dot product"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
