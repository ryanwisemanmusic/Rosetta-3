// ADDSS.inc

name = "ADDSS"
category = "simd_scalar_float_add"
feature = "SSE"
element_type = "f32"
active_lane = 0

encodings = [
  { opcode = "F3 0F 58 /r", form = "ADDSS xmm1, xmm2/m32", op_en = "A", feature = "SSE" },
  { opcode = "VEX.LIG.F3.0F.WIG 58 /r", form = "VADDSS xmm1, xmm2, xmm3/m32", op_en = "B", feature = "AVX" }
]

semantic_legacy = """
DEST.f32[0] = DEST.f32[0] + SRC.f32[0];
DEST[127:32] unchanged;
"""

semantic_vex = """
DEST.f32[0] = SRC1.f32[0] + SRC2.f32[0];
DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

mxcsr_used = true
simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]

handler = "x86_addss"
jit_lowering = "arm64_scalar_fadd_s"