// CMP/CMPSS.inc
// ARM64/NEON translation mirror generated from ISA/x86/CMP/CMPSS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
CMPSS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_scalar_float_compare.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CMP/CMPSS.inc"
x86_handler = "x86_cmpss"
neon_lowering = "arm64_documented_contract_cmpss"
lowering_kind = "neon_scalar"


name = "CMPSS"
aliases = ["VCMPSS"]
category = "simd_scalar_float_compare"
feature = "SSE_AVX_AVX512F"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "F3 0F C2 /r ib", form = "CMPSS xmm1, xmm2/m32, imm8", op_en = "A", feature = "SSE", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.LIG.F3.0F.WIG C2 /r ib", form = "VCMPSS xmm1, xmm2, xmm3/m32, imm8", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "EVEX.LLIG.F3.0F.W0 C2 /r ib", form = "VCMPSS xmm1{k1}{z}, xmm2, xmm3/m32, sae, imm8", op_en = "C", feature = "AVX512F", vector_length = 128, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "imm8 (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)", "imm8 (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)", "imm8 (r)"]
}

active_lane = 0
lane_type = "scalar_single_precision"

lanes = { xmm = 4, ymm = 8, zmm = 16 }
flags_written = []
mxcsr_used = true

simd_fp_exceptions = [
  "invalid",
  "denormal"
]

comparison_predicate = {
  imm8_range = "0..7",
  predicates = {
    0 = "EQ (equal)",
    1 = "LT (less-than)",
    2 = "LE (less-than-or-equal)",
    3 = "UNORD (unordered)",
    4 = "NEQ (not-equal)",
    5 = "NLT (not-less-than)",
    6 = "NLE (not-less-than-or-equal)",
    7 = "ORD (ordered)"
  },
  mnemonic_predicates = {
    "EQ" = "CMPEQSS",
    "LT" = "CMPLTSS",
    "LE" = "CMPLESS",
    "UNORD" = "CMPUNORDSS",
    "NEQ" = "CMPNEQSS",
    "NLT" = "CMPNLTSS",
    "NLE" = "CMPNLESS",
    "ORD" = "CMPORDSS"
  }
}

semantic_legacy = """
DEST.f32[0] = compare_with_predicate(DEST.f32[0], SRC.f32[0], imm8) ? all_ones : all_zeros;
DEST[127:32] unchanged;
"""

semantic_vex = """
DEST.f32[0] = compare_with_predicate(SRC1.f32[0], SRC2.f32[0], imm8) ? all_ones : all_zeros;
DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

semantic_evex = """
if k1[0] == 1 or no_writemask:
    DEST.f32[0] = compare_with_predicate(SRC1.f32[0], SRC2.f32[0], imm8) ? all_ones : all_zeros;
else if zeroing_masking:
    DEST.f32[0] = 0;

DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

handler = "x86_cmpss"
jit_lowering = "arm64_documented_contract_cmpss"
fallback = "zig_scalar_fcmp_s"

neon_register_model = """
x86 xmm/ymm/zmm lanes are mapped onto ARM64 v registers; only the low f32 lane is compared; upper lanes are preserved or zeroed per encoding.
"""

neon_flag_model = """
No x86 flags are modified; MXCSR invalid/denormal exception status is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
// ARM64 NEON provides FCMEQ, FCMLT, FCMGT for scalar single comparisons.
// Example for EQ predicate:
//     fcmeq sD, sN, sM
//     bl rosette_apply_mxcsr_float_exceptions
// For other predicates the lowering maps through ARM64 scalar f32 comparison
// instructions and converts the condition result to an all-1s/all-0s mask.
// For signalling predicates, #XM is raised on SNaN inputs.
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
