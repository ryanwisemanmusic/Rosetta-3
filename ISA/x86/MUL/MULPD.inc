// MULPD.inc

operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
MULPD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_mul.
"""

name = "MULPD"
category = "simd_float_mul"
feature = "SSE2"
element_type = "f64"

encodings = [
  { opcode = "66 0F 59 /r", form = "MULPD xmm1, xmm2/m128", op_en = "A", feature = "SSE2" },
  { opcode = "VEX.128.66.0F.WIG 59 /r", form = "VMULPD xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX" },
  { opcode = "VEX.256.66.0F.WIG 59 /r", form = "VMULPD ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX" },
  { opcode = "EVEX.128.66.0F.W1 59 /r", form = "VMULPD xmm1{k1}{z}, xmm2, xmm3/m128/m64bcst", op_en = "C", feature = "AVX512F" },
  { opcode = "EVEX.256.66.0F.W1 59 /r", form = "VMULPD ymm1{k1}{z}, ymm2, xmm3/m256/m64bcst", op_en = "C", feature = "AVX512F" },
  { opcode = "EVEX.512.66.0F.W1 59 /r", form = "VMULPD zmm1{k1}{z}, zmm2, xmm3/m512/m64bcst", op_en = "C", feature = "AVX512F" }
]

element_size = 64
lane_type = "double_precision_float"

lanes = {
  xmm = 2,
  ymm = 4,
  zmm = 8
}

mxcsr_used = true

simd_fp_exceptions = [
  "overflow",
  "underflow",
  "invalid",
  "precision",
  "denormal"
]

flags_written = []

semantic_legacy_128 = """
DEST.f64[0] = DEST.f64[0] * SRC.f64[0];
DEST.f64[1] = DEST.f64[1] * SRC.f64[1];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST.f64[0] = SRC1.f64[0] * SRC2.f64[0];
DEST.f64[1] = SRC1.f64[1] * SRC2.f64[1];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST.f64[0] = SRC1.f64[0] * SRC2.f64[0];
DEST.f64[1] = SRC1.f64[1] * SRC2.f64[1];
DEST.f64[2] = SRC1.f64[2] * SRC2.f64[2];
DEST.f64[3] = SRC1.f64[3] * SRC2.f64[3];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
for lane in VL:
    if writemask_enabled:
        DEST[lane] = SRC1[lane] * SRC2[lane];
    else if zero_masking:
        DEST[lane] = 0;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_mulpd"
jit_lowering = "arm64_neon_fmul_pd"
fallback = "zig_lane_loop"
