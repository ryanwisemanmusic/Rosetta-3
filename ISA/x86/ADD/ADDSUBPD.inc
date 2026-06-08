// ADDSUBPD.inc

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
ADDSUBPD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_add_sub.
"""

name = "ADDSUBPD"
category = "simd_float_add_sub"
feature = "SSE3"
element_type = "f64"

encodings = [
  { opcode = "66 0F D0 /r", form = "ADDSUBPD xmm1, xmm2/m128", op_en = "RM", feature = "SSE3" },
  { opcode = "VEX.128.66.0F.WIG D0 /r", form = "VADDSUBPD xmm1, xmm2, xmm3/m128", op_en = "RVM", feature = "AVX" },
  { opcode = "VEX.256.66.0F.WIG D0 /r", form = "VADDSUBPD ymm1, ymm2, ymm3/m256", op_en = "RVM", feature = "AVX" }
]

lane_pattern = "even_lanes_subtract_odd_lanes_add"
lanes_128 = 2
lanes_256 = 4

semantic_legacy_128 = """
DEST.f64[0] = DEST.f64[0] - SRC.f64[0];
DEST.f64[1] = DEST.f64[1] + SRC.f64[1];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST.f64[0] = SRC1.f64[0] - SRC2.f64[0];
DEST.f64[1] = SRC1.f64[1] + SRC2.f64[1];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST.f64[0] = SRC1.f64[0] - SRC2.f64[0];
DEST.f64[1] = SRC1.f64[1] + SRC2.f64[1];
DEST.f64[2] = SRC1.f64[2] - SRC2.f64[2];
DEST.f64[3] = SRC1.f64[3] + SRC2.f64[3];
"""

mxcsr_used = true
flags_written = []
simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]

memory_alignment = "m128 legacy source must be 16-byte aligned"

handler = "x86_addsubpd"
jit_lowering = "arm64_neon_fadd_fsub_by_lane_pattern"
fallback = "zig_lane_loop"