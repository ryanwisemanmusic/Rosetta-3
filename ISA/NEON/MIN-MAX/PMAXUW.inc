// MIN-MAX/PMAXUW.inc
// ARM64/NEON mirror generated from ISA/x86/MIN-MAX/PMAXUW.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
PMAXUW: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_integer_max.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MIN-MAX/PMAXUW.inc"
x86_handler = "x86_pmaxuw"
neon_lowering = "arm64_neon_umax_h"
lowering_kind = "arm64_documented_contract"

// MIN-MAX/PMAXUW.inc
// ARM64/NEON translation mirror generated from ISA/x86/MIN-MAX/PMAXUW.inc.
// Source contract: PMAXUW/VPMAXUW — Maximum of Packed Unsigned Word Integers.

name = "PMAXUW"
aliases = ["VPMAXUW"]
category = "simd_integer_max"
feature = "SSE4_1_AVX_AVX512BW"
element_type = "u16"
element_size = 16

encodings = [
  { opcode = "66 0F 38 3A /r", form = "PMAXUW xmm1, xmm2/m128", op_en = "A", feature = "SSE4_1", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F38 3A /r", form = "VPMAXUW xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F38 3A /r", form = "VPMAXUW ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F38 3A /r", form = "VPMAXUW xmm1{k1}{z}, xmm2, xmm3/m128", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F38 3A /r", form = "VPMAXUW ymm1{k1}{z}, ymm2, ymm3/m256", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F38 3A /r", form = "VPMAXUW zmm1{k1}{z}, zmm2, zmm3/m512", op_en = "C", feature = "AVX512BW", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

lanes = { xmm = 8, ymm = 16, zmm = 32 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "Non-EVEX encoded instruction uses Type 4 class exception conditions",
  "EVEX encoded instruction uses Type E4 class exception conditions"
]

semantic_legacy_128 = """
DEST[15:0]  = MAX(DEST[15:0],  SRC[15:0]);
DEST[31:16] = MAX(DEST[31:16], SRC[31:16]);
DEST[47:32] = MAX(DEST[47:32], SRC[47:32]);
DEST[63:48] = MAX(DEST[63:48], SRC[63:48]);
DEST[79:64] = MAX(DEST[79:64], SRC[79:64]);
DEST[95:80] = MAX(DEST[95:80], SRC[95:80]);
DEST[111:96] = MAX(DEST[111:96], SRC[111:96]);
DEST[127:112] = MAX(DEST[127:112], SRC[127:112]);
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST[15:0]  = MAX(SRC1[15:0],  SRC2[15:0]);
DEST[31:16] = MAX(SRC1[31:16], SRC2[31:16]);
DEST[47:32] = MAX(SRC1[47:32], SRC2[47:32]);
DEST[63:48] = MAX(SRC1[63:48], SRC2[63:48]);
DEST[79:64] = MAX(SRC1[79:64], SRC2[79:64]);
DEST[95:80] = MAX(SRC1[95:80], SRC2[95:80]);
DEST[111:96] = MAX(SRC1[111:96], SRC2[111:96]);
DEST[127:112] = MAX(SRC1[127:112], SRC2[127:112]);
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST[15:0]   = MAX(SRC1[15:0],   SRC2[15:0]);
DEST[31:16]  = MAX(SRC1[31:16],  SRC2[31:16]);
DEST[47:32]  = MAX(SRC1[47:32],  SRC2[47:32]);
DEST[63:48]  = MAX(SRC1[63:48],  SRC2[63:48]);
DEST[79:64]  = MAX(SRC1[79:64],  SRC2[79:64]);
DEST[95:80]  = MAX(SRC1[95:80],  SRC2[95:80]);
DEST[111:96] = MAX(SRC1[111:96], SRC2[111:96]);
DEST[127:112] = MAX(SRC1[127:112], SRC2[127:112]);
DEST[143:128] = MAX(SRC1[143:128], SRC2[143:128]);
DEST[159:144] = MAX(SRC1[159:144], SRC2[159:144]);
DEST[175:160] = MAX(SRC1[175:160], SRC2[175:160]);
DEST[191:176] = MAX(SRC1[191:176], SRC2[191:176]);
DEST[207:192] = MAX(SRC1[207:192], SRC2[207:192]);
DEST[223:208] = MAX(SRC1[223:208], SRC2[223:208]);
DEST[239:224] = MAX(SRC1[239:224], SRC2[239:224]);
DEST[255:240] = MAX(SRC1[255:240], SRC2[255:240]);
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (8,128), (16,256), or (32,512);
for j in 0..KL-1:
    i = j * 16;
    if k1[j] == 1 or no_writemask:
        DEST[i+15:i] = MAX(SRC1[i+15:i], SRC2[i+15:i]);
    else if zeroing_masking:
        DEST[i+15:i] = 0;
    else:
        DEST[i+15:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_pmaxuw"
jit_lowering = "arm64_neon_umax_h"
fallback = "zig_lane_max_u16"

neon_register_model = """
x86 xmm/ymm/zmm word lanes are mapped into ARM64 vector temporaries.
"""

neon_flag_model = """
No x86 flags are modified.
"""

neon_assembly = """
umax vD.8h, vN.8h, vM.8h
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
