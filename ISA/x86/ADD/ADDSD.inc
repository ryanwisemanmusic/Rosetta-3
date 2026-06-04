// ADDSD.inc

name = "ADDSD"
category = "simd_scalar_float_add"
feature = "SSE2"
element_type = "f64"

encodings = [
  { opcode = "F2 0F 58 /r", form = "ADDSD xmm1, xmm2/m64", op_en = "A", feature = "SSE2" },
  { opcode = "VEX.LIG.F2.0F.WIG 58 /r", form = "VADDSD xmm1, xmm2, xmm3/m64", op_en = "B", feature = "AVX" },
  { opcode = "EVEX.LLIG.F2.0F.W1 58 /r", form = "VADDSD xmm1{k1}{z}, xmm2, xmm3/m64", op_en = "C", feature = "AVX512F" }
]

element_size = 64
active_lane = 0
lane_type = "scalar_double_precision"

mxcsr_used = true

simd_fp_exceptions = [
  "overflow",
  "underflow",
  "invalid",
  "precision",
  "denormal"
]

flags_written = []

semantic_legacy = """
DEST.f64[0] = DEST.f64[0] + SRC.f64[0];
DEST[MAXVL-1:64] unchanged;
"""

semantic_vex = """
DEST.f64[0] = SRC1.f64[0] + SRC2.f64[0];
DEST[127:64] = SRC1[127:64];
DEST[MAXVL-1:128] = 0;
"""

semantic_evex = """
if writemask_enabled:
    DEST.f64[0] = SRC1.f64[0] + SRC2.f64[0];
else if zero_masking:
    DEST.f64[0] = 0;

DEST[127:64] = SRC1[127:64];
DEST[MAXVL-1:128] = 0;
"""

handler = "x86_addsd"
jit_lowering = "arm64_scalar_fadd_d"
fallback = "zig_scalar_double"
