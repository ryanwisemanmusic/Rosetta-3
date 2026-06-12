// BLEND/BLENDPS.inc
// ARM64/NEON mirror generated from ISA/x86/BLEND/BLENDPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
BLENDPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_blend.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BLEND/BLENDPS.inc"
x86_handler = "x86_blendps"
neon_lowering = "arm64_neon_blend_ps"
lowering_kind = "arm64_documented_contract"

// BLEND/BLENDPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/BLEND/BLENDPS.inc.
// Source contract: BLENDPS/VBLENDPS — Blend Packed Single Precision Floating-Point Values.

name = "BLENDPS"
aliases = ["VBLENDPS"]
category = "simd_blend"
feature = "SSE4_1_AVX"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "66 0F 3A 0C /r ib", form = "BLENDPS xmm1, xmm2/m128, imm8", op_en = "RMI", feature = "SSE4_1", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F3A.WIG 0C /r ib", form = "VBLENDPS xmm1, xmm2, xmm3/m128, imm8", op_en = "RVMI", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F3A.WIG 0C /r ib", form = "VBLENDPS ymm1, ymm2, ymm3/m256, imm8", op_en = "RVMI", feature = "AVX", vector_length = 256, encoding = "vex" }
]

operand_encoding = {
  RMI = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "imm8"],
  RVMI = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)", "imm8"]
}

lanes = { xmm = 4, ymm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "See Table 2-21, \"Type 4 Class Exception Conditions.\""
]

semantic_legacy_128 = """
IF (IMM8[0] = 0) THEN DEST[31:0] := DEST[31:0]
    ELSE DEST[31:0] := SRC[31:0] FI
IF (IMM8[1] = 0) THEN DEST[63:32] := DEST[63:32]
    ELSE DEST[63:32] := SRC[63:32] FI
IF (IMM8[2] = 0) THEN DEST[95:64] := DEST[95:64]
    ELSE DEST[95:64] := SRC[95:64] FI
IF (IMM8[3] = 0) THEN DEST[127:96] := DEST[127:96]
    ELSE DEST[127:96] := SRC[127:96] FI
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
IF (IMM8[0] = 0) THEN DEST[31:0] := SRC1[31:0]
    ELSE DEST[31:0] := SRC2[31:0] FI
IF (IMM8[1] = 0) THEN DEST[63:32] := SRC1[63:32]
    ELSE DEST[63:32] := SRC2[63:32] FI
IF (IMM8[2] = 0) THEN DEST[95:64] := SRC1[95:64]
    ELSE DEST[95:64] := SRC2[95:64] FI
IF (IMM8[3] = 0) THEN DEST[127:96] := SRC1[127:96]
    ELSE DEST[127:96] := SRC2[127:96] FI
DEST[MAXVL-1:128] := 0;
"""

semantic_vex_256 = """
IF (IMM8[0] = 0) THEN DEST[31:0] := SRC1[31:0]
    ELSE DEST[31:0] := SRC2[31:0] FI
IF (IMM8[1] = 0) THEN DEST[63:32] := SRC1[63:32]
    ELSE DEST[63:32] := SRC2[63:32] FI
IF (IMM8[2] = 0) THEN DEST[95:64] := SRC1[95:64]
    ELSE DEST[95:64] := SRC2[95:64] FI
IF (IMM8[3] = 0) THEN DEST[127:96] := SRC1[127:96]
    ELSE DEST[127:96] := SRC2[127:96] FI
IF (IMM8[4] = 0) THEN DEST[159:128] := SRC1[159:128]
    ELSE DEST[159:128] := SRC2[159:128] FI
IF (IMM8[5] = 0) THEN DEST[191:160] := SRC1[191:160]
    ELSE DEST[191:160] := SRC2[191:160] FI
IF (IMM8[6] = 0) THEN DEST[223:192] := SRC1[223:192]
    ELSE DEST[223:192] := SRC2[223:192] FI
IF (IMM8[7] = 0) THEN DEST[255:224] := SRC1[255:224]
    ELSE DEST[255:224] := SRC2[255:224] FI
DEST[MAXVL-1:256] := 0;
"""

handler = "x86_blendps"
jit_lowering = "arm64_neon_blend_ps"
fallback = "zig_lane_loop_blend_32"

neon_register_model = """
x86 xmm/ymm bit lanes are mapped into ARM64 vector temporaries. BLENDPS is a per-lane select using immediate mask bits. No MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by BLENDPS/VBLENDPS.
"""

neon_assembly = """
// NEON lowering: bsl with mask generated from imm8
// For 128-bit: generate 32-bit lane mask from IMM8[3:0], apply bsl vD.16b, vN.16b, vM.16b
// For 256-bit: generate 32-bit lane mask from IMM8[7:0], apply bsl across both 128-bit halves
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
