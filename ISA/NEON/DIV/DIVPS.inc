// DIV/DIVPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/DIV/DIVPS.inc.

operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
DIVPS: preserve the operation and form-specific semantic blocks.
Category: simd_float_div.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "DIV/DIVPS.inc"
x86_handler = "x86_divps"
neon_lowering = "arm64_neon_fdiv_ps"
lowering_kind = "neon_vector"

name = "DIVPS"
category = "simd_float_div"
feature = "SSE"
element_type = "f32"

encodings = [
  { opcode = "NP 0F 5E /r", form = "DIVPS xmm1, xmm2/m128", op_en = "A", feature = "SSE" },
  { opcode = "VEX.128.0F.WIG 5E /r", form = "VDIVPS xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX" },
  { opcode = "VEX.256.0F.WIG 5E /r", form = "VDIVPS ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX" },
  { opcode = "EVEX.128.0F.W0 5E /r", form = "VDIVPS xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "C", feature = "AVX512F" },
  { opcode = "EVEX.256.0F.W0 5E /r", form = "VDIVPS ymm1{k1}{z}, ymm2, xmm3/m256/m32bcst", op_en = "C", feature = "AVX512F" },
  { opcode = "EVEX.512.0F.W0 5E /r", form = "VDIVPS zmm1{k1}{z}, zmm2, xmm3/m512/m32bcst", op_en = "C", feature = "AVX512F" }
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
  "divide_by_zero",
  "precision",
  "denormal"
]

flags_written = []

semantic_legacy_128 = """
DEST.f32[0] = DEST.f32[0] / SRC.f32[0];
DEST.f32[1] = DEST.f32[1] / SRC.f32[1];
DEST.f32[2] = DEST.f32[2] / SRC.f32[2];
DEST.f32[3] = DEST.f32[3] / SRC.f32[3];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST.f32[0] = SRC1.f32[0] / SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] / SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] / SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] / SRC2.f32[3];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST.f32[0] = SRC1.f32[0] / SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] / SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] / SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] / SRC2.f32[3];
DEST.f32[4] = SRC1.f32[4] / SRC2.f32[4];
DEST.f32[5] = SRC1.f32[5] / SRC2.f32[5];
DEST.f32[6] = SRC1.f32[6] / SRC2.f32[6];
DEST.f32[7] = SRC1.f32[7] / SRC2.f32[7];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
for lane in VL:
    if writemask_enabled:
        DEST[lane] = SRC1[lane] / SRC2[lane];
    else if zero_masking:
        DEST[lane] = 0;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_divps"
jit_lowering = "arm64_neon_fdiv_ps"
fallback = "zig_lane_loop"

neon_register_model = """
x86 xmm/ymm lanes are mapped onto ARM64 v registers; lane width and MAXVL zero/merge rules are preserved by the lowering.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fdiv vD.4s, vN.4s, vM.4s
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
