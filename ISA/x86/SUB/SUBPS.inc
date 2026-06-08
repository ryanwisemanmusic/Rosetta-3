// SUBPS.inc
// Subtract packed single precision floating-point values.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
SUBPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_subtract.
"""

name = "SUBPS"
category = "simd_float_subtract"
feature = "SSE"
element_type = "f32"
legacy_width = 128
lanes_128 = 4
lanes_256 = 8
lanes_512 = 16
mxcsr_used = true

encodings = [
  { opcode = "0F 5C /r", form = "SUBPS xmm1, xmm2/m128", op_en = "A", feature = "SSE", mode = "V/V", handler = "x86_subps_xmm_xmmm128" },
  { opcode = "VEX.128.0F.WIG 5C /r", form = "VSUBPS xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", mode = "V/V", handler = "x86_vsubps_xmm_xmm_xmmm128" },
  { opcode = "VEX.256.0F.WIG 5C /r", form = "VSUBPS ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX", mode = "V/V", handler = "x86_vsubps_ymm_ymm_ymmm256" },
  { opcode = "EVEX.128.0F.W0 5C /r", form = "VSUBPS xmm1 {k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "C", feature = "AVX512VL AVX512F", tuple = "Full", handler = "x86_vsubps_evex128" },
  { opcode = "EVEX.256.0F.W0 5C /r", form = "VSUBPS ymm1 {k1}{z}, ymm2, ymm3/m256/m32bcst", op_en = "C", feature = "AVX512VL AVX512F", tuple = "Full", handler = "x86_vsubps_evex256" },
  { opcode = "EVEX.512.0F.W0 5C /r", form = "VSUBPS zmm1 {k1}{z}, zmm2, zmm3/m512/m32bcst{er}", op_en = "C", feature = "AVX512F", tuple = "Full", handler = "x86_vsubps_evex512" }
]

operand_encodings = [
  { op_en = "A", tuple = "N/A", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "B", tuple = "N/A", operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" },
  { op_en = "C", tuple = "Full", operand1 = "ModRM:reg (w)", operand2 = "EVEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" }
]

semantic_legacy = """
for lane in 0..4:
    DEST.f32[lane] = DEST.f32[lane] - SRC.f32[lane];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
for lane in 0..4:
    DEST.f32[lane] = SRC1.f32[lane] - SRC2.f32[lane];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for lane in 0..8:
    DEST.f32[lane] = SRC1.f32[lane] - SRC2.f32[lane];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
for each active f32 lane selected by k1 or no writemask:
    DEST.f32[lane] = SRC1.f32[lane] - SRC2.f32[lane_or_broadcast];
else merge old destination or zero according to masking mode;
DEST[MAXVL-1:VL] = 0;
"""

simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]
other_exceptions = ["VEX Type 2 class exceptions", "EVEX Type E2 class exceptions"]

handler = "x86_subps"
jit_lowering = "arm64_neon_fsub_ps"
