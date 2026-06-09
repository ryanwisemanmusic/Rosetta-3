// MUL/MULPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MUL/MULPD.inc.

operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
MULPD: preserve the operation and form-specific semantic blocks.
Category: simd_float_mul.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MUL/MULPD.inc"
x86_handler = "x86_mulpd"
neon_lowering = "arm64_neon_fmul_pd"
lowering_kind = "neon_vector"

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

neon_register_model = """
x86 xmm/ymm lanes are mapped onto ARM64 v registers; lane width and MAXVL zero/merge rules are preserved by the lowering.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fmul vD.2d, vN.2d, vM.2d
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
