// SUBSS.inc
// Subtract scalar single precision floating-point value.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
SUBSS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_subtract_scalar.
"""

name = "SUBSS"
category = "simd_float_subtract_scalar"
feature = "SSE"
element_type = "f32"
scalar_width = 32
mxcsr_used = true

encodings = [
  { opcode = "F3 0F 5C /r", form = "SUBSS xmm1, xmm2/m32", op_en = "A", feature = "SSE", mode = "V/V", handler = "x86_subss_xmm_xmmm32" },
  { opcode = "VEX.LIG.F3.0F.WIG 5C /r", form = "VSUBSS xmm1, xmm2, xmm3/m32", op_en = "B", feature = "AVX", mode = "V/V", handler = "x86_vsubss_xmm_xmm_xmmm32" },
  { opcode = "EVEX.LLIG.F3.0F.W0 5C /r", form = "VSUBSS xmm1 {k1}{z}, xmm2, xmm3/m32{er}", op_en = "C", feature = "AVX512F", tuple = "Tuple1 Scalar", handler = "x86_vsubss_evex" }
]

operand_encodings = [
  { op_en = "A", tuple = "N/A", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "B", tuple = "N/A", operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" },
  { op_en = "C", tuple = "Tuple1 Scalar", operand1 = "ModRM:reg (w)", operand2 = "EVEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" }
]

semantic_legacy = """
DEST[31:0] = DEST[31:0] - SRC[31:0];
DEST[MAXVL-1:32] unchanged;
"""

semantic_vex_128 = """
DEST[31:0] = SRC1[31:0] - SRC2[31:0];
DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

semantic_evex = """
if k1[0] or no writemask:
    DEST[31:0] = SRC1[31:0] - SRC2[31:0];
else merge old low element or zero according to masking mode;
DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

notes = [
  "Only the low single precision element is subtracted.",
  "Legacy SSE keeps upper bits above bit 31 unmodified.",
  "VEX/EVEX copies bits 127:32 from SRC1 and zeroes bits above 128.",
  "Software should encode VSUBSS with VEX.L=0; VEX.L=1 may be unpredictable across processors."
]

simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]
other_exceptions = ["VEX Type 3 class exceptions", "EVEX Type E3 class exceptions"]

handler = "x86_subss"
jit_lowering = "arm64_neon_fsub_ss"
