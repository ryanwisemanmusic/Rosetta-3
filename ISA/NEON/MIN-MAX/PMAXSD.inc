// MIN-MAX/PMAXSD.inc
// ARM64/NEON mirror generated from ISA/x86/MIN-MAX/PMAXSD.inc.
// Source contract: PMAXSD/VPMAXSD — Maximum of Packed Signed Dwords.

semantic = """
PMAXSD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_integer_max.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MIN-MAX/PMAXSD.inc"
x86_handler = "x86_pmaxsd"
neon_lowering = "arm64_neon_smax_s"
lowering_kind = "neon_vector"

name = "PMAXSD"
aliases = ["VPMAXSD"]
category = "simd_integer_max"
feature = "SSE4_1_AVX_AVX512F"
element_type = "i32"
element_size = 32

encodings = [
  { opcode = "66 0F 38 3D /r", form = "PMAXSD xmm1, xmm2/m128", op_en = "A", feature = "SSE4.1", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F38.W0 3D /r", form = "VPMAXSD xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F38.W0 3D /r", form = "VPMAXSD ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX2", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F38.W0 3D /r", form = "VPMAXSD xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 128, encoding = "evex", broadcast = "m32bcst" },
  { opcode = "EVEX.256.66.0F38.W0 3D /r", form = "VPMAXSD ymm1{k1}{z}, ymm2, ymm3/m256/m32bcst", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 256, encoding = "evex", broadcast = "m32bcst" },
  { opcode = "EVEX.512.66.0F38.W0 3D /r", form = "VPMAXSD zmm1{k1}{z}, zmm2, zmm3/m512/m32bcst", op_en = "D", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m32bcst" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"],
  D = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

lanes = { xmm = 4, ymm = 8, zmm = 16 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "Non-EVEX encoded instruction uses Type 4 class exception conditions",
  "EVEX encoded instruction uses Type E4 class exception conditions"
]

semantic_legacy_128 = """
for j in 0..3:
    i = j * 32;
    DEST[i+31:i] = (DEST[i+31:i] > SRC[i+31:i]) ? DEST[i+31:i] : SRC[i+31:i];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
for j in 0..3:
    i = j * 32;
    DEST[i+31:i] = (SRC1[i+31:i] > SRC2[i+31:i]) ? SRC1[i+31:i] : SRC2[i+31:i];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for j in 0..7:
    i = j * 32;
    DEST[i+31:i] = (SRC1[i+31:i] > SRC2[i+31:i]) ? SRC1[i+31:i] : SRC2[i+31:i];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (4,128), (8,256), or (16,512);
for j in 0..KL-1:
    i = j * 32;
    if k1[j] == 1 or no_writemask:
        if EVEX.b == 1 and SRC2_is_memory:
            DEST[i+31:i] = (SRC1[i+31:i] > SRC2[31:0]) ? SRC1[i+31:i] : SRC2[31:0];
        else:
            DEST[i+31:i] = (SRC1[i+31:i] > SRC2[i+31:i]) ? SRC1[i+31:i] : SRC2[i+31:i];
    else if zeroing_masking:
        DEST[i+31:i] = 0;
    else:
        DEST[i+31:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_pmaxsd"
jit_lowering = "arm64_neon_smax_s"
fallback = "zig_lane_max_i32"

neon_register_model = """
x86 xmm/ymm/zmm signed dword lanes are mapped into ARM64 vector temporaries. No MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by PMAXSD/VPMAXSD.
"""

neon_assembly = """
smax vD.4s, vN.4s, vM.4s
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
