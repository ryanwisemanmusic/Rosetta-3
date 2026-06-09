// CMP/CMPPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/CMP/CMPPD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
CMPPD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_compare.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CMP/CMPPD.inc"
x86_handler = "x86_cmppd"
neon_lowering = "arm64_documented_contract_cmppd"
lowering_kind = "neon_vector"


name = "CMPPD"
aliases = ["VCMPPD"]
category = "simd_float_compare"
feature = "SSE2_AVX_AVX512F"
element_type = "f64"
element_size = 64

encodings = [
  { opcode = "66 0F C2 /r ib", form = "CMPPD xmm1, xmm2/m128, imm8", op_en = "A", feature = "SSE2", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F.WIG C2 /r ib", form = "VCMPPD xmm1, xmm2, xmm3/m128, imm8", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F.WIG C2 /r ib", form = "VCMPPD ymm1, ymm2, ymm3/m256, imm8", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F.W1 C2 /r ib", form = "VCMPPD xmm1{k1}{z}, xmm2, xmm3/m128/m64bcst, sae, imm8", op_en = "C", feature = "AVX512F", vector_length = 128, encoding = "evex", broadcast = "m64bcst" },
  { opcode = "EVEX.256.66.0F.W1 C2 /r ib", form = "VCMPPD ymm1{k1}{z}, ymm2, ymm3/m256/m64bcst, sae, imm8", op_en = "C", feature = "AVX512F", vector_length = 256, encoding = "evex", broadcast = "m64bcst" },
  { opcode = "EVEX.512.66.0F.W1 C2 /r ib", form = "VCMPPD zmm1{k1}{z}, zmm2, zmm3/m512/m64bcst, sae, imm8", op_en = "C", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m64bcst" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "imm8 (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)", "imm8 (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)", "imm8 (r)"]
}

lanes = { xmm = 2, ymm = 4, zmm = 8 }
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
    "EQ" = "CMPEQPD",
    "LT" = "CMPLTPD",
    "LE" = "CMPLEPD",
    "UNORD" = "CMPUNORDPD",
    "NEQ" = "CMPNEQPD",
    "NLT" = "CMPNLTPD",
    "NLE" = "CMPNLEPD",
    "ORD" = "CMPORDPD"
  }
}

semantic_legacy_128 = """
DEST.f64[0] = compare_with_predicate(DEST.f64[0], SRC.f64[0], imm8) ? all_ones : all_zeros;
DEST.f64[1] = compare_with_predicate(DEST.f64[1], SRC.f64[1], imm8) ? all_ones : all_zeros;
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST.f64[0] = compare_with_predicate(SRC1.f64[0], SRC2.f64[0], imm8) ? all_ones : all_zeros;
DEST.f64[1] = compare_with_predicate(SRC1.f64[1], SRC2.f64[1], imm8) ? all_ones : all_zeros;
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST.f64[0] = compare_with_predicate(SRC1.f64[0], SRC2.f64[0], imm8) ? all_ones : all_zeros;
DEST.f64[1] = compare_with_predicate(SRC1.f64[1], SRC2.f64[1], imm8) ? all_ones : all_zeros;
DEST.f64[2] = compare_with_predicate(SRC1.f64[2], SRC2.f64[2], imm8) ? all_ones : all_zeros;
DEST.f64[3] = compare_with_predicate(SRC1.f64[3], SRC2.f64[3], imm8) ? all_ones : all_zeros;
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (2,128), (4,256), or (8,512);
for j in 0..KL-1:
    i = j * 64;
    if k1[j] == 1 or no_writemask:
        if EVEX.b == 1 and SRC2_is_memory:
            DEST[i+63:i] = compare_with_predicate(SRC1[i+63:i], SRC2[63:0], imm8) ? all_ones : all_zeros;
        else:
            DEST[i+63:i] = compare_with_predicate(SRC1[i+63:i], SRC2[i+63:i], imm8) ? all_ones : all_zeros;
    else if zeroing_masking:
        DEST[i+63:i] = 0;
    else:
        DEST[i+63:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_cmppd"
jit_lowering = "arm64_documented_contract_cmppd"
fallback = "zig_lane_loop_fcmp_pd"

neon_register_model = """
x86 xmm/ymm/zmm lanes are mapped onto ARM64 v registers; each lane yields a bitmask (all-1s/all-0s) per element.
"""

neon_flag_model = """
No x86 flags are modified; MXCSR invalid/denormal exception status is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
// ARM64 NEON provides FCMLT, FCMGT, FCMEQ for scalar comparisons.
// For each predicate in imm8, the lowering selects the appropriate ARM64
// comparison instruction(s) and produces an all-1s/all-0s mask per f64 lane.
// Example for EQ predicate:
//     fcmeq vD.2d, vN.2d, vM.2d
//     bl rosette_apply_mxcsr_float_exceptions
// For LT/LE predicates the operands are swapped or negated to map to
// ARM64 FCMLT/FCMLE (which is fcmlt with swapped operands).
// For UNORD/ORD, ARM64 FACGE + inverse logic may be used.
// For signalling predicates (NEQ, NLT, NLE), the ARM64 lowering must
// raise #XM on SNaN inputs as the x86 contract requires.
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
