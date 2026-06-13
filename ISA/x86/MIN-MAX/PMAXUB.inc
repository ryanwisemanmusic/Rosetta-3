// MIN-MAX/PMAXUB.inc
// ARM64/NEON translation mirror generated from ISA/x86/MIN-MAX/PMAXUB.inc.
// Source contract: PMAXUB/VPMAXUB — Maximum of Packed Unsigned Byte Integers.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
PMAXUB: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_integer_max.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MIN-MAX/PMAXUB.inc"
x86_handler = "x86_pmaxub"
neon_lowering = "arm64_neon_umax_b"
lowering_kind = "neon_vector"

name = "PMAXUB"
aliases = ["VPMAXUB"]
category = "simd_integer_max"
feature = "SSE_SSE2_AVX_AVX512BW"
element_type = "u8"
element_size = 8

encodings = [
  { opcode = "NP 0F DA /r", form = "PMAXUB mm1, mm2/m64", op_en = "A", feature = "SSE", vector_length = 64, encoding = "legacy_mmx" },
  { opcode = "66 0F DA /r", form = "PMAXUB xmm1, xmm2/m128", op_en = "A", feature = "SSE2", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F DA /r", form = "VPMAXUB xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F DA /r", form = "VPMAXUB ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F DA /r", form = "VPMAXUB xmm1{k1}{z}, xmm2, xmm3/m128", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F DA /r", form = "VPMAXUB ymm1{k1}{z}, ymm2, ymm3/m256", op_en = "C", feature = "AVX512VL+AVX512BW", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F DA /r", form = "VPMAXUB zmm1{k1}{z}, zmm2, zmm3/m512", op_en = "C", feature = "AVX512BW", vector_length = 512, encoding = "evex" }
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

semantic_legacy_64 = """
DEST[7:0]   = MAX(DEST[7:0],   SRC[7:0]);
DEST[15:8]  = MAX(DEST[15:8],  SRC[15:8]);
DEST[23:16] = MAX(DEST[23:16], SRC[23:16]);
DEST[31:24] = MAX(DEST[31:24], SRC[31:24]);
DEST[39:32] = MAX(DEST[39:32], SRC[39:32]);
DEST[47:40] = MAX(DEST[47:40], SRC[47:40]);
DEST[55:48] = MAX(DEST[55:48], SRC[55:48]);
DEST[63:56] = MAX(DEST[63:56], SRC[63:56]);
"""

semantic_legacy_128 = """
DEST[7:0]    = MAX(DEST[7:0],    SRC[7:0]);
DEST[15:8]   = MAX(DEST[15:8],   SRC[15:8]);
DEST[23:16]  = MAX(DEST[23:16],  SRC[23:16]);
DEST[31:24]  = MAX(DEST[31:24],  SRC[31:24]);
DEST[39:32]  = MAX(DEST[39:32],  SRC[39:32]);
DEST[47:40]  = MAX(DEST[47:40],  SRC[47:40]);
DEST[55:48]  = MAX(DEST[55:48],  SRC[55:48]);
DEST[63:56]  = MAX(DEST[63:56],  SRC[63:56]);
DEST[71:64]  = MAX(DEST[71:64],  SRC[71:64]);
DEST[79:72]  = MAX(DEST[79:72],  SRC[79:72]);
DEST[87:80]  = MAX(DEST[87:80],  SRC[87:80]);
DEST[95:88]  = MAX(DEST[95:88],  SRC[95:88]);
DEST[103:96] = MAX(DEST[103:96], SRC[103:96]);
DEST[111:104] = MAX(DEST[111:104], SRC[111:104]);
DEST[119:112] = MAX(DEST[119:112], SRC[119:112]);
DEST[127:120] = MAX(DEST[127:120], SRC[127:120]);
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST[7:0]    = MAX(SRC1[7:0],    SRC2[7:0]);
DEST[15:8]   = MAX(SRC1[15:8],   SRC2[15:8]);
DEST[23:16]  = MAX(SRC1[23:16],  SRC2[23:16]);
DEST[31:24]  = MAX(SRC1[31:24],  SRC2[31:24]);
DEST[39:32]  = MAX(SRC1[39:32],  SRC2[39:32]);
DEST[47:40]  = MAX(SRC1[47:40],  SRC2[47:40]);
DEST[55:48]  = MAX(SRC1[55:48],  SRC2[55:48]);
DEST[63:56]  = MAX(SRC1[63:56],  SRC2[63:56]);
DEST[71:64]  = MAX(SRC1[71:64],  SRC2[71:64]);
DEST[79:72]  = MAX(SRC1[79:72],  SRC2[79:72]);
DEST[87:80]  = MAX(SRC1[87:80],  SRC2[87:80]);
DEST[95:88]  = MAX(SRC1[95:88],  SRC2[95:88]);
DEST[103:96] = MAX(SRC1[103:96], SRC2[103:96]);
DEST[111:104] = MAX(SRC1[111:104], SRC2[111:104]);
DEST[119:112] = MAX(SRC1[119:112], SRC2[119:112]);
DEST[127:120] = MAX(SRC1[127:120], SRC2[127:120]);
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST[7:0]    = MAX(SRC1[7:0],    SRC2[7:0]);
DEST[15:8]   = MAX(SRC1[15:8],   SRC2[15:8]);
DEST[23:16]  = MAX(SRC1[23:16],  SRC2[23:16]);
DEST[31:24]  = MAX(SRC1[31:24],  SRC2[31:24]);
DEST[39:32]  = MAX(SRC1[39:32],  SRC2[39:32]);
DEST[47:40]  = MAX(SRC1[47:40],  SRC2[47:40]);
DEST[55:48]  = MAX(SRC1[55:48],  SRC2[55:48]);
DEST[63:56]  = MAX(SRC1[63:56],  SRC2[63:56]);
DEST[71:64]  = MAX(SRC1[71:64],  SRC2[71:64]);
DEST[79:72]  = MAX(SRC1[79:72],  SRC2[79:72]);
DEST[87:80]  = MAX(SRC1[87:80],  SRC2[87:80]);
DEST[95:88]  = MAX(SRC1[95:88],  SRC2[95:88]);
DEST[103:96] = MAX(SRC1[103:96], SRC2[103:96]);
DEST[111:104] = MAX(SRC1[111:104], SRC2[111:104]);
DEST[119:112] = MAX(SRC1[119:112], SRC2[119:112]);
DEST[127:120] = MAX(SRC1[127:120], SRC2[127:120]);
DEST[135:128] = MAX(SRC1[135:128], SRC2[135:128]);
DEST[143:136] = MAX(SRC1[143:136], SRC2[143:136]);
DEST[151:144] = MAX(SRC1[151:144], SRC2[151:144]);
DEST[159:152] = MAX(SRC1[159:152], SRC2[159:152]);
DEST[167:160] = MAX(SRC1[167:160], SRC2[167:160]);
DEST[175:168] = MAX(SRC1[175:168], SRC2[175:168]);
DEST[183:176] = MAX(SRC1[183:176], SRC2[183:176]);
DEST[191:184] = MAX(SRC1[191:184], SRC2[191:184]);
DEST[199:192] = MAX(SRC1[199:192], SRC2[199:192]);
DEST[207:200] = MAX(SRC1[207:200], SRC2[207:200]);
DEST[215:208] = MAX(SRC1[215:208], SRC2[215:208]);
DEST[223:216] = MAX(SRC1[223:216], SRC2[223:216]);
DEST[231:224] = MAX(SRC1[231:224], SRC2[231:224]);
DEST[239:232] = MAX(SRC1[239:232], SRC2[239:232]);
DEST[247:240] = MAX(SRC1[247:240], SRC2[247:240]);
DEST[255:248] = MAX(SRC1[255:248], SRC2[255:248]);
DEST[MAXVL-1:256] = 0;
"""

semantic_evex = """
(KL, VL) = (16,128), (32,256), or (64,512);
for j in 0..KL-1:
    i = j * 8;
    if k1[j] == 1 or no_writemask:
        DEST[i+7:i] = MAX(SRC1[i+7:i], SRC2[i+7:i]);
    else if zeroing_masking:
        DEST[i+7:i] = 0;
    else:
        DEST[i+7:i] unchanged;
DEST[MAXVL-1:VL] = 0;
"""

handler = "x86_pmaxub"
jit_lowering = "arm64_neon_umax_b"
fallback = "zig_lane_max_u8"

neon_register_model = """
x86 xmm/ymm/zmm byte lanes are mapped into ARM64 vector temporaries.
"""

neon_flag_model = """
No x86 flags are modified.
"""

neon_assembly = """
umax vD.16b, vN.16b, vM.16b
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
