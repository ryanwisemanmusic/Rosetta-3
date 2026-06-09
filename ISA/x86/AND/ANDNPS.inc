// AND/ANDNPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/AND/ANDNPS.inc.
// Source contract: ANDNPS/VANDNPS — Bitwise Logical AND NOT of Packed Single Precision Floating-Point Values.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
ANDNPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_bitwise_logic.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "AND/ANDNPS.inc"
x86_handler = "x86_andnps"
neon_lowering = "arm64_neon_bitwise_andnot_ps"
lowering_kind = "neon_vector"

name = "ANDNPS"
aliases = ["VANDNPS"]
category = "simd_bitwise_logic"
feature = "SSE_AVX_AVX512DQ"
element_type = "f32_bits"
element_size = 32

encodings = [
  { opcode = "NP 0F 55 /r", form = "ANDNPS xmm1, xmm2/m128", op_en = "A", feature = "SSE", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.0F 55 /r", form = "VANDNPS xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.0F 55 /r", form = "VANDNPS ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.0F.W0 55 /r", form = "VANDNPS xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 128, encoding = "evex", broadcast = "m32bcst" },
  { opcode = "EVEX.256.0F.W0 55 /r", form = "VANDNPS ymm1{k1}{z}, ymm2, ymm3/m256/m32bcst", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 256, encoding = "evex", broadcast = "m32bcst" },
  { opcode = "EVEX.512.0F.W0 55 /r", form = "VANDNPS zmm1{k1}{z}, ymm2, ymm3/m512/m32bcst", op_en = "C", feature = "AVX512DQ", vector_length = 512, encoding = "evex", broadcast = "m32bcst" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

lanes = { xmm = 4, ymm = 8, zmm = 16 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "Non-EVEX encoded instruction uses Type 4 class exception conditions",
  "EVEX encoded instruction uses Type E4 class exception conditions"
]

semantic_legacy_128 = """
DEST[31:0]   = ~(DEST[31:0])   & SRC[31:0];
DEST[63:32]  = ~(DEST[63:32])  & SRC[63:32];
DEST[95:64]  = ~(DEST[95:64])  & SRC[95:64];
DEST[127:96] = ~(DEST[127:96]) & SRC[127:96];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST[31:0]   = ~(SRC1[31:0])   & SRC2[31:0];
DEST[63:32]  = ~(SRC1[63:32])  & SRC2[63:32];
DEST[95:64]  = ~(SRC1[95:64])  & SRC2[95:64];
DEST[127:96] = ~(SRC1[127:96]) & SRC2[127:96];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for lane in 0..7:
    i = lane * 32;
    DEST[i+31:i] = ~(SRC1[i+31:i]) & SRC2[i+31:i];
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (4,128), (8,256), or (16,512);
for j in 0..KL-1:
    i = j * 32;
    if k1[j] == 1 or no_writemask:
        if EVEX.b == 1 and SRC2_is_memory:
            DEST[i+31:i] = ~(SRC1[i+31:i]) & SRC2[31:0];
        else:
            DEST[i+31:i] = ~(SRC1[i+31:i]) & SRC2[i+31:i];
    else if zeroing_masking:
        DEST[i+31:i] = 0;
    else:
        DEST[i+31:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_andnps"
jit_lowering = "arm64_neon_bitwise_andnot_ps"
fallback = "zig_lane_loop_bitwise_andnot_32"

neon_register_model = """
x86 xmm/ymm/zmm bit lanes are mapped into ARM64 vector temporaries. Since ANDNPS is bitwise despite floating-point lane naming, no MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by ANDNPS/VANDNPS.
"""

neon_assembly = """
bic vD.16b, vN.16b, vM.16b
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
