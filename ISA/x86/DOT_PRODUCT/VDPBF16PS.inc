// DOT_PRODUCT/VDPBF16PS.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "DOT_PRODUCT/VDPBF16PS.inc"
x86_handler = "x86_vdpbf16ps"
neon_lowering = "arm64_vdpbf16ps"
lowering_kind = "arm64_documented_contract"

name = "VDPBF16PS"
aliases = []
category = "dot_product"
feature = "AVX512_BF16"
element_type = "bf16"
element_size = 16

encodings = [
  { opcode = "EVEX.128.F3.0F38.W0 52 /r", form = "VDPBF16PS xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "A", feature = "AVX512_BF16", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.F3.0F38.W0 52 /r", form = "VDPBF16PS ymm1{k1}{z}, ymm2, ymm3/m256/m32bcst", op_en = "A", feature = "AVX512_BF16", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.F3.0F38.W0 52 /r", form = "VDPBF16PS zmm1{k1}{z}, zmm2, zmm3/m512/m32bcst", op_en = "A", feature = "AVX512_BF16", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Performs SIMD dot-product of BF16 pairs from src1 and src2/mem, accumulating packed single precision results with writemask k1.
"""

handler = "x86_vdpbf16ps"
jit_lowering = "arm64_vdpbf16ps"
fallback = "zig_vdpbf16ps"

neon_register_model = "x86 XMM/YMM/ZMM registers mapped to ARM64 V/Z registers."
neon_flag_model = "No x86 flags modified by VDPBF16PS."
neon_assembly = "// ARM64: SVE dot product or FMUL+FADD with BF16 conversion"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
