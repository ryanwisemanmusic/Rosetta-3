// AND/ANDPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/AND/ANDPD.inc.
// Source contract: ANDPD/VANDPD — Bitwise Logical AND of Packed Double Precision Floating-Point Values.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
ANDPD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_bitwise_logic.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "AND/ANDPD.inc"
x86_handler = "x86_andpd"
neon_lowering = "arm64_neon_bitwise_and_pd"
lowering_kind = "neon_vector"

name = "ANDPD"
aliases = ["VANDPD"]
category = "simd_bitwise_logic"
feature = "SSE2_AVX_AVX512DQ"
element_type = "f64_bits"
element_size = 64

encodings = [
  { opcode = "66 0F 54 /r", form = "ANDPD xmm1, xmm2/m128", op_en = "A", feature = "SSE2", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F 54 /r", form = "VANDPD xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F 54 /r", form = "VANDPD ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F.W1 54 /r", form = "VANDPD xmm1{k1}{z}, xmm2, xmm3/m128/m64bcst", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 128, encoding = "evex", broadcast = "m64bcst" },
  { opcode = "EVEX.256.66.0F.W1 54 /r", form = "VANDPD ymm1{k1}{z}, ymm2, ymm3/m256/m64bcst", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 256, encoding = "evex", broadcast = "m64bcst" },
  { opcode = "EVEX.512.66.0F.W1 54 /r", form = "VANDPD zmm1{k1}{z}, ymm2, ymm3/m512/m64bcst", op_en = "C", feature = "AVX512DQ", vector_length = 512, encoding = "evex", broadcast = "m64bcst" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

lanes = { xmm = 2, ymm = 4, zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "Non-EVEX encoded instruction uses Type 4 class exception conditions",
  "EVEX encoded instruction uses Type E4 class exception conditions"
]

semantic_legacy_128 = """
DEST[63:0]   = DEST[63:0]   & SRC[63:0];
DEST[127:64] = DEST[127:64] & SRC[127:64];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST[63:0]   = SRC1[63:0]   & SRC2[63:0];
DEST[127:64] = SRC1[127:64] & SRC2[127:64];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST[63:0]    = SRC1[63:0]    & SRC2[63:0];
DEST[127:64]  = SRC1[127:64]  & SRC2[127:64];
DEST[191:128] = SRC1[191:128] & SRC2[191:128];
DEST[255:192] = SRC1[255:192] & SRC2[255:192];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (2,128), (4,256), or (8,512);
for j in 0..KL-1:
    i = j * 64;
    if k1[j] == 1 or no_writemask:
        if EVEX.b == 1 and SRC2_is_memory:
            DEST[i+63:i] = SRC1[i+63:i] & SRC2[63:0];
        else:
            DEST[i+63:i] = SRC1[i+63:i] & SRC2[i+63:i];
    else if zeroing_masking:
        DEST[i+63:i] = 0;
    else:
        DEST[i+63:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_andpd"
jit_lowering = "arm64_neon_bitwise_and_pd"
fallback = "zig_lane_loop_bitwise_and_64"

neon_register_model = """
x86 xmm/ymm/zmm bit lanes are mapped into ARM64 vector temporaries. Since ANDPD is bitwise despite floating-point lane naming, no MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by ANDPD/VANDPD.
"""

neon_assembly = """
and vD.16b, vN.16b, vM.16b
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
