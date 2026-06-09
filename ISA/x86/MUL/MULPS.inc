// MULPS.inc

operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
MULPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_mul.
"""

name = "MULPS"
category = "simd_float_mul"
feature = "SSE"
element_type = "f32"

encodings = [
  { opcode = "NP 0F 59 /r", form = "MULPS xmm1, xmm2/m128", op_en = "A", feature = "SSE" },
  { opcode = "VEX.128.0F.WIG 59 /r", form = "VMULPS xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX" },
  { opcode = "VEX.256.0F.WIG 59 /r", form = "VMULPS ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX" },
  { opcode = "EVEX.128.0F.W0 59 /r", form = "VMULPS xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "C", feature = "AVX512F" },
  { opcode = "EVEX.256.0F.W0 59 /r", form = "VMULPS ymm1{k1}{z}, ymm2, xmm3/m256/m32bcst", op_en = "C", feature = "AVX512F" },
  { opcode = "EVEX.512.0F.W0 59 /r", form = "VMULPS zmm1{k1}{z}, zmm2, xmm3/m512/m32bcst", op_en = "C", feature = "AVX512F" }
]

element_size = 32
lane_type = "single_precision_float"

lanes = {
  xmm = 4,
  ymm = 8,
  zmm = 16
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
DEST.f32[0] = DEST.f32[0] * SRC.f32[0];
DEST.f32[1] = DEST.f32[1] * SRC.f32[1];
DEST.f32[2] = DEST.f32[2] * SRC.f32[2];
DEST.f32[3] = DEST.f32[3] * SRC.f32[3];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST.f32[0] = SRC1.f32[0] * SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] * SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] * SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] * SRC2.f32[3];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST.f32[0] = SRC1.f32[0] * SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] * SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] * SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] * SRC2.f32[3];
DEST.f32[4] = SRC1.f32[4] * SRC2.f32[4];
DEST.f32[5] = SRC1.f32[5] * SRC2.f32[5];
DEST.f32[6] = SRC1.f32[6] * SRC2.f32[6];
DEST.f32[7] = SRC1.f32[7] * SRC2.f32[7];
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

handler = "x86_mulps"
jit_lowering = "arm64_neon_fmul_ps"
fallback = "zig_lane_loop"
