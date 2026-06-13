// MIN-MAX/PMINSQ.inc
// ARM64/NEON translation mirror generated from ISA/x86/MIN-MAX/PMINSQ.inc.
// Source contract: PMINSQ — Minimum of Packed Signed Integers (Qwords).

// Canonical table metadata for registry-wide .inc validation.
semantic = """
PMINSQ: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_integer_min.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MIN-MAX/PMINSQ.inc"
x86_handler = "x86_pminsq"
neon_lowering = "arm64_neon_smin_d"
lowering_kind = "neon_vector"

name = "PMINSQ"
aliases = []
category = "simd_integer_min"
feature = "AVX512F"
element_type = "i64"
element_size = 64

encodings = [
  { opcode = "EVEX.128.66.0F38.W1 39 /r", form = "VPMINSQ xmm1{k1}{z}, xmm2, xmm3/m128/m64bcst", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 128, encoding = "evex", broadcast = "m64bcst" },
  { opcode = "EVEX.256.66.0F38.W1 39 /r", form = "VPMINSQ ymm1{k1}{z}, ymm2, ymm3/m256/m64bcst", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 256, encoding = "evex", broadcast = "m64bcst" },
  { opcode = "EVEX.512.66.0F38.W1 39 /r", form = "VPMINSQ zmm1{k1}{z}, zmm2, zmm3/m512/m64bcst", op_en = "D", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m64bcst" }
]

operand_encoding = {
  D = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

lanes = { xmm = 2, ymm = 4, zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "EVEX encoded instruction uses Type E4 class exception conditions"
]

semantic_evex = """
(KL, VL) = (2,128), (4,256), or (8,512);
for j in 0..KL-1:
    i = j * 64;
    if k1[j] == 1 or no_writemask:
        if EVEX.b == 1 and SRC2_is_memory:
            if SRC1.s64[j] < SRC2.s64[0]:
                DEST.s64[j] = SRC1.s64[j];
            else:
                DEST.s64[j] = SRC2.s64[0];
        else:
            if SRC1.s64[j] < SRC2.s64[j]:
                DEST.s64[j] = SRC1.s64[j];
            else:
                DEST.s64[j] = SRC2.s64[j];
    else if zeroing_masking:
        DEST.s64[j] = 0;
    else:
        DEST.s64[j] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_pminsq"
jit_lowering = "arm64_neon_smin_d"
fallback = "zig_lane_min_i64"

neon_register_model = """
x86 xmm/ymm/zmm qword lanes are mapped into ARM64 vector temporaries.
"""

neon_flag_model = """
No x86 flags are modified by PMINSQ.
"""

neon_assembly = """
smin vD.2d, vN.2d, vM.2d
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
