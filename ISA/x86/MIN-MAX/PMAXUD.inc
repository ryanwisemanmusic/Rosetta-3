// MIN-MAX/PMAXUD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MIN-MAX/PMAXUD.inc.
// Source contract: PMAXUD/VPMAXUD — Maximum of Packed Unsigned Doubleword Integers.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
PMAXUD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_integer_max.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MIN-MAX/PMAXUD.inc"
x86_handler = "x86_pmaxud"
neon_lowering = "arm64_neon_umax_s"
lowering_kind = "neon_vector"

name = "PMAXUD"
aliases = ["VPMAXUD"]
category = "simd_integer_max"
feature = "SSE4_1_AVX_AVX512F"
element_type = "u32"
element_size = 32

encodings = [
  { opcode = "66 0F 38 3B /r", form = "PMAXUD xmm1, xmm2/m128", op_en = "A", feature = "SSE4_1", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F38.W0 3B /r", form = "VPMAXUD xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F38.W0 3B /r", form = "VPMAXUD ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F38.W0 3B /r", form = "VPMAXUD xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 128, encoding = "evex", broadcast = "m32bcst" },
  { opcode = "EVEX.256.66.0F38.W0 3B /r", form = "VPMAXUD ymm1{k1}{z}, ymm2, ymm3/m256/m32bcst", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 256, encoding = "evex", broadcast = "m32bcst" },
  { opcode = "EVEX.512.66.0F38.W0 3B /r", form = "VPMAXUD zmm1{k1}{z}, zmm2, zmm3/m512/m32bcst", op_en = "D", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m32bcst" }
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
DEST[31:0]  = MAX(DEST[31:0],  SRC[31:0]);
DEST[63:32] = MAX(DEST[63:32], SRC[63:32]);
DEST[95:64] = MAX(DEST[95:64], SRC[95:64]);
DEST[127:96] = MAX(DEST[127:96], SRC[127:96]);
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST[31:0]  = MAX(SRC1[31:0],  SRC2[31:0]);
DEST[63:32] = MAX(SRC1[63:32], SRC2[63:32]);
DEST[95:64] = MAX(SRC1[95:64], SRC2[95:64]);
DEST[127:96] = MAX(SRC1[127:96], SRC2[127:96]);
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST[31:0]   = MAX(SRC1[31:0],   SRC2[31:0]);
DEST[63:32]  = MAX(SRC1[63:32],  SRC2[63:32]);
DEST[95:64]  = MAX(SRC1[95:64],  SRC2[95:64]);
DEST[127:96] = MAX(SRC1[127:96], SRC2[127:96]);
DEST[159:128] = MAX(SRC1[159:128], SRC2[159:128]);
DEST[191:160] = MAX(SRC1[191:160], SRC2[191:160]);
DEST[223:192] = MAX(SRC1[223:192], SRC2[223:192]);
DEST[255:224] = MAX(SRC1[255:224], SRC2[255:224]);
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (4,128), (8,256), or (16,512);
for j in 0..KL-1:
    i = j * 32;
    if k1[j] == 1 or no_writemask:
        if EVEX.b == 1 and SRC2_is_memory:
            DEST[i+31:i] = MAX(SRC1[i+31:i], SRC2[31:0]);
        else:
            DEST[i+31:i] = MAX(SRC1[i+31:i], SRC2[i+31:i]);
    else if zeroing_masking:
        DEST[i+31:i] = 0;
    else:
        DEST[i+31:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_pmaxud"
jit_lowering = "arm64_neon_umax_s"
fallback = "zig_lane_max_u32"

neon_register_model = """
x86 xmm/ymm/zmm doubleword lanes are mapped into ARM64 vector temporaries.
"""

neon_flag_model = """
No x86 flags are modified.
"""

neon_assembly = """
umax vD.4s, vN.4s, vM.4s
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
