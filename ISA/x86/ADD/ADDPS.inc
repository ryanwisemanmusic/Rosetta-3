// ADDPS.inc

name = "ADDPS"
category = "simd_float_add"
feature = "SSE"
element_type = "f32"
legacy_width = 128
lanes_128 = 4

encodings = [
  { opcode = "0F 58 /r", form = "ADDPS xmm1, xmm2/m128", op_en = "A", feature = "SSE" },
  { opcode = "VEX.128.0F.WIG 58 /r", form = "VADDPS xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX" },
  { opcode = "VEX.256.0F.WIG 58 /r", form = "VADDPS ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX" }
]

mxcsr_used = true
simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]

semantic_legacy = """
for lane in 0..4:
    DEST.f32[lane] = DEST.f32[lane] + SRC.f32[lane];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
for lane in 0..4:
    DEST.f32[lane] = SRC1.f32[lane] + SRC2.f32[lane];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for lane in 0..8:
    DEST.f32[lane] = SRC1.f32[lane] + SRC2.f32[lane];
DEST[MAXVL-1:256] = 0;
"""

handler = "x86_addps"
jit_lowering = "arm64_neon_fadd_ps"