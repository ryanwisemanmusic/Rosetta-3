// MIN-MAX/PMAXSW.inc
// ARM64/NEON mirror generated from ISA/x86/MIN-MAX/PMAXSW.inc.
// Source contract: PMAXSW/VPMAXSW — Maximum of Packed Signed Words.

semantic = """
PMAXSW: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_integer_max.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MIN-MAX/PMAXSW.inc"
x86_handler = "x86_pmaxsw"
neon_lowering = "arm64_neon_smax_h"
lowering_kind = "neon_vector"

name = "PMAXSW"
aliases = ["VPMAXSW"]
category = "simd_integer_max"
feature = "SSE_SSE2_AVX_AVX512BW"
element_type = "i16"
element_size = 16

encodings = [
  { opcode = "NP 0F EE /r", form = "PMAXSW mm1, mm2/m64", op_en = "A", feature = "SSE", vector_length = 64, encoding = "legacy_mmx" },
  { opcode = "66 0F EE /r", form = "PMAXSW xmm1, xmm2/m128", op_en = "A", feature = "SSE2", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F.WIG EE /r", form = "VPMAXSW xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F.WIG EE /r", form = "VPMAXSW ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX2", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F.WIG EE /r", form = "VPMAXSW xmm1{k1}{z}, xmm2, xmm3/m128", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F.WIG EE /r", form = "VPMAXSW ymm1{k1}{z}, ymm2, ymm3/m256", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F.WIG EE /r", form = "VPMAXSW zmm1{k1}{z}, zmm2, zmm3/m512", op_en = "C", feature = "AVX512BW", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

lanes = { mm = 4, xmm = 8, ymm = 16, zmm = 32 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "Non-EVEX encoded instruction uses Type 4 class exception conditions",
  "EVEX encoded instruction uses Type E4 class exception conditions"
]

semantic_legacy_64 = """
for j in 0..3:
    i = j * 16;
    DEST[i+15:i] = (DEST[i+15:i] > SRC[i+15:i]) ? DEST[i+15:i] : SRC[i+15:i];
DEST[MAXVL-1:64] unchanged;
"""

semantic_legacy_128 = """
for j in 0..7:
    i = j * 16;
    DEST[i+15:i] = (DEST[i+15:i] > SRC[i+15:i]) ? DEST[i+15:i] : SRC[i+15:i];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
for j in 0..7:
    i = j * 16;
    DEST[i+15:i] = (SRC1[i+15:i] > SRC2[i+15:i]) ? SRC1[i+15:i] : SRC2[i+15:i];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for j in 0..15:
    i = j * 16;
    DEST[i+15:i] = (SRC1[i+15:i] > SRC2[i+15:i]) ? SRC1[i+15:i] : SRC2[i+15:i];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (8,128), (16,256), or (32,512);
for j in 0..KL-1:
    i = j * 16;
    if k1[j] == 1 or no_writemask:
        DEST[i+15:i] = (SRC1[i+15:i] > SRC2[i+15:i]) ? SRC1[i+15:i] : SRC2[i+15:i];
    else if zeroing_masking:
        DEST[i+15:i] = 0;
    else:
        DEST[i+15:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_pmaxsw"
jit_lowering = "arm64_neon_smax_h"
fallback = "zig_lane_max_i16"

neon_register_model = """
x86 mm/xmm/ymm/zmm signed word lanes are mapped into ARM64 vector temporaries. No MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by PMAXSW/VPMAXSW.
"""

neon_assembly = """
smax vD.8h, vN.8h, vM.8h
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
