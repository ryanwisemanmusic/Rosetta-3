// SUB/SUBPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/SUB/SUBPD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SUB/SUBPD.inc"
x86_handler = "x86_subpd"
neon_lowering = "arm64_neon_fsub_pd"
lowering_kind = "neon_vector"


name = "SUBPD"
category = "simd_float_subtract"
feature = "SSE2"
element_type = "f64"
legacy_width = 128
lanes_128 = 2
lanes_256 = 4
lanes_512 = 8
mxcsr_used = true

encodings = [
  { opcode = "66 0F 5C /r", form = "SUBPD xmm1, xmm2/m128", op_en = "A", feature = "SSE2", mode = "V/V", handler = "x86_subpd_xmm_xmmm128" },
  { opcode = "VEX.128.66.0F.WIG 5C /r", form = "VSUBPD xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", mode = "V/V", handler = "x86_vsubpd_xmm_xmm_xmmm128" },
  { opcode = "VEX.256.66.0F.WIG 5C /r", form = "VSUBPD ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX", mode = "V/V", handler = "x86_vsubpd_ymm_ymm_ymmm256" },
  { opcode = "EVEX.128.66.0F.W1 5C /r", form = "VSUBPD xmm1 {k1}{z}, xmm2, xmm3/m128/m64bcst", op_en = "C", feature = "AVX512VL AVX512F", tuple = "Full", handler = "x86_vsubpd_evex128" },
  { opcode = "EVEX.256.66.0F.W1 5C /r", form = "VSUBPD ymm1 {k1}{z}, ymm2, ymm3/m256/m64bcst", op_en = "C", feature = "AVX512VL AVX512F", tuple = "Full", handler = "x86_vsubpd_evex256" },
  { opcode = "EVEX.512.66.0F.W1 5C /r", form = "VSUBPD zmm1 {k1}{z}, zmm2, zmm3/m512/m64bcst{er}", op_en = "C", feature = "AVX512F", tuple = "Full", handler = "x86_vsubpd_evex512" }
]

operand_encodings = [
  { op_en = "A", tuple = "N/A", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "B", tuple = "N/A", operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" },
  { op_en = "C", tuple = "Full", operand1 = "ModRM:reg (w)", operand2 = "EVEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" }
]

semantic_legacy = """
for lane in 0..2:
    DEST.f64[lane] = DEST.f64[lane] - SRC.f64[lane];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
for lane in 0..2:
    DEST.f64[lane] = SRC1.f64[lane] - SRC2.f64[lane];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for lane in 0..4:
    DEST.f64[lane] = SRC1.f64[lane] - SRC2.f64[lane];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
for each active f64 lane selected by k1 or no writemask:
    DEST.f64[lane] = SRC1.f64[lane] - SRC2.f64[lane_or_broadcast];
else merge old destination or zero according to masking mode;
DEST[MAXVL-1:VL] = 0;
"""

simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]
other_exceptions = ["VEX Type 2 class exceptions", "EVEX Type E2 class exceptions"]

handler = "x86_subpd"
jit_lowering = "arm64_neon_fsub_pd"


neon_register_model = """
x86 xmm/ymm lanes are mapped onto ARM64 v registers; lane width and MAXVL zero/merge rules are preserved by the lowering.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fsub vD.2d, vN.2d, vM.2d
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
