// ADDSUBPS.inc

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
ADDSUBPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_add_sub.
"""

name = "ADDSUBPS"
category = "simd_float_add_sub"
feature = "SSE3"
element_type = "f32"

encodings = [
  { opcode = "F2 0F D0 /r", form = "ADDSUBPS xmm1, xmm2/m128", op_en = "RM", feature = "SSE3" },
  { opcode = "VEX.128.F2.0F.WIG D0 /r", form = "VADDSUBPS xmm1, xmm2, xmm3/m128", op_en = "RVM", feature = "AVX" },
  { opcode = "VEX.256.F2.0F.WIG D0 /r", form = "VADDSUBPS ymm1, ymm2, xmm3/m256", op_en = "RVM", feature = "AVX" }
]

lane_pattern = "even_lanes_subtract_odd_lanes_add"
lanes_128 = 4
lanes_256 = 8

semantic_legacy_128 = """
DEST.f32[0] = DEST.f32[0] - SRC.f32[0];
DEST.f32[1] = DEST.f32[1] + SRC.f32[1];
DEST.f32[2] = DEST.f32[2] - SRC.f32[2];
DEST.f32[3] = DEST.f32[3] + SRC.f32[3];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST.f32[0] = SRC1.f32[0] - SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] + SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] - SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] + SRC2.f32[3];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST.f32[0] = SRC1.f32[0] - SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] + SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] - SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] + SRC2.f32[3];
DEST.f32[4] = SRC1.f32[4] - SRC2.f32[4];
DEST.f32[5] = SRC1.f32[5] + SRC2.f32[5];
DEST.f32[6] = SRC1.f32[6] - SRC2.f32[6];
DEST.f32[7] = SRC1.f32[7] + SRC2.f32[7];
"""

mxcsr_used = true
flags_written = []
simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]

memory_alignment = "m128 legacy source must be 16-byte aligned"

handler = "x86_addsubps"
jit_lowering = "arm64_neon_fadd_fsub_by_lane_pattern"
fallback = "zig_lane_loop"