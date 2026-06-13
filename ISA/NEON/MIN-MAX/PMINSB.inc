// MIN-MAX/PMINSB.inc
// ARM64/NEON translation mirror generated from ISA/x86/MIN-MAX/PMINSB.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
PMINSB: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_integer_min.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MIN-MAX/PMINSB.inc"
x86_handler = "x86_pminsb"
neon_lowering = "arm64_neon_smin_b"
lowering_kind = "arm64_documented_contract"

// MIN-MAX/PMINSB.inc
// ARM64/NEON translation mirror generated from ISA/x86/MIN-MAX/PMINSB.inc.
// Source contract: PMINSB/VPMINSB — Minimum of Packed Signed Integers (Bytes).

name = "PMINSB"
aliases = ["VPMINSB"]
category = "simd_integer_min"
feature = "SSE4_1_AVX_AVX512BW"
element_type = "i8"
element_size = 8

encodings = [
  { opcode = "66 0F 38 3C /r", form = "PMINSB xmm1, xmm2/m128", op_en = "A", feature = "SSE4_1", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F38.WIG 3C /r", form = "VPMINSB xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F38.WIG 3C /r", form = "VPMINSB ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX2", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F38.WIG 3C /r", form = "VPMINSB xmm1{k1}{z}, xmm2, xmm3/m128", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F38.WIG 3C /r", form = "VPMINSB ymm1{k1}{z}, ymm2, ymm3/m256", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F38.WIG 3C /r", form = "VPMINSB zmm1{k1}{z}, zmm2, zmm3/m512", op_en = "C", feature = "AVX512BW", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

lanes = { xmm = 16, ymm = 32, zmm = 64 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "Non-EVEX encoded instruction uses Type 4 class exception conditions",
  "EVEX encoded instruction uses Type E4 class exception conditions"
]

semantic_legacy_128 = """
for each byte lane j in 0..15:
    IF DEST.s8[j] < SRC.s8[j]:
        DEST.s8[j] = DEST.s8[j];
    ELSE:
        DEST.s8[j] = SRC.s8[j];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
for each byte lane j in 0..15:
    IF SRC1.s8[j] < SRC2.s8[j]:
        DEST.s8[j] = SRC1.s8[j];
    ELSE:
        DEST.s8[j] = SRC2.s8[j];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for each byte lane j in 0..31:
    IF SRC1.s8[j] < SRC2.s8[j]:
        DEST.s8[j] = SRC1.s8[j];
    ELSE:
        DEST.s8[j] = SRC2.s8[j];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (16,128), (32,256), or (64,512);
for j in 0..KL-1:
    i = j * 8;
    if k1[j] == 1 or no_writemask:
        if SRC1.s8[j] < SRC2.s8[j]:
            DEST.s8[j] = SRC1.s8[j];
        else:
            DEST.s8[j] = SRC2.s8[j];
    else if zeroing_masking:
        DEST.s8[j] = 0;
    else:
        DEST.s8[j] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_pminsb"
jit_lowering = "arm64_neon_smin_b"
fallback = "zig_lane_min_i8"

neon_register_model = """
x86 xmm/ymm/zmm byte lanes are mapped into ARM64 vector temporaries.
"""

neon_flag_model = """
No x86 flags are modified by PMINSB/VPMINSB.
"""

neon_assembly = """
smin vD.16b, vN.16b, vM.16b
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
