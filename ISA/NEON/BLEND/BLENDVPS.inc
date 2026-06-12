// BLEND/BLENDVPS.inc
// ARM64/NEON mirror generated from ISA/x86/BLEND/BLENDVPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
BLENDVPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_variable_blend.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BLEND/BLENDVPS.inc"
x86_handler = "x86_blendvps"
neon_lowering = "arm64_neon_blendv_ps"
lowering_kind = "arm64_documented_contract"

// BLEND/BLENDVPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/BLEND/BLENDVPS.inc.
// Source contract: BLENDVPS/VBLENDVPS — Variable Blend Packed Single Precision Floating-Point Values.

name = "BLENDVPS"
aliases = ["VBLENDVPS"]
category = "simd_variable_blend"
feature = "SSE4_1_AVX"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "66 0F 38 14 /r", form = "BLENDVPS xmm1, xmm2/m128, <XMM0>", op_en = "RM0", feature = "SSE4_1", vector_length = 128, encoding = "legacy_sse" },
  { opcode = "VEX.128.66.0F3A.W0 4A /r /is4", form = "VBLENDVPS xmm1, xmm2, xmm3/m128, xmm4", op_en = "RVMR", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F3A.W0 4A /r /is4", form = "VBLENDVPS ymm1, ymm2, ymm3/m256, ymm4", op_en = "RVMR", feature = "AVX", vector_length = 256, encoding = "vex" }
]

operand_encoding = {
  RM0 = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "implicit XMM0"],
  RVMR = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)", "imm8[7:4]"]
}

lanes = { xmm = 4, ymm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "See Table 2-21, \"Type 4 Class Exception Conditions,\" additionally:",
  "#UD If VEX.W = 1."
]

semantic_legacy_128 = """
MASK := XMM0
IF (MASK[31] = 0) THEN DEST[31:0] := DEST[31:0]
    ELSE DEST[31:0] := SRC[31:0] FI
IF (MASK[63] = 0) THEN DEST[63:32] := DEST[63:32]
    ELSE DEST[63:32] := SRC[63:32] FI
IF (MASK[95] = 0) THEN DEST[95:64] := DEST[95:64]
    ELSE DEST[95:64] := SRC[95:64] FI
IF (MASK[127] = 0) THEN DEST[127:96] := DEST[127:96]
    ELSE DEST[127:96] := SRC[127:96] FI
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
MASK := SRC3
IF (MASK[31] = 0) THEN DEST[31:0] := SRC1[31:0]
    ELSE DEST[31:0] := SRC2[31:0] FI
IF (MASK[63] = 0) THEN DEST[63:32] := SRC1[63:32]
    ELSE DEST[63:32] := SRC2[63:32] FI
IF (MASK[95] = 0) THEN DEST[95:64] := SRC1[95:64]
    ELSE DEST[95:64] := SRC2[95:64] FI
IF (MASK[127] = 0) THEN DEST[127:96] := SRC1[127:96]
    ELSE DEST[127:96] := SRC2[127:96] FI
DEST[MAXVL-1:128] := 0;
"""

semantic_vex_256 = """
MASK := SRC3
IF (MASK[31] = 0) THEN DEST[31:0] := SRC1[31:0]
    ELSE DEST[31:0] := SRC2[31:0] FI
IF (MASK[63] = 0) THEN DEST[63:32] := SRC1[63:32]
    ELSE DEST[63:32] := SRC2[63:32] FI
IF (MASK[95] = 0) THEN DEST[95:64] := SRC1[95:64]
    ELSE DEST[95:64] := SRC2[95:64] FI
IF (MASK[127] = 0) THEN DEST[127:96] := SRC1[127:96]
    ELSE DEST[127:96] := SRC2[127:96] FI
IF (MASK[159] = 0) THEN DEST[159:128] := SRC1[159:128]
    ELSE DEST[159:128] := SRC2[159:128] FI
IF (MASK[191] = 0) THEN DEST[191:160] := SRC1[191:160]
    ELSE DEST[191:160] := SRC2[191:160] FI
IF (MASK[223] = 0) THEN DEST[223:192] := SRC1[223:192]
    ELSE DEST[223:192] := SRC2[223:192] FI
IF (MASK[255] = 0) THEN DEST[255:224] := SRC1[255:224]
    ELSE DEST[255:224] := SRC2[255:224] FI
DEST[MAXVL-1:256] := 0;
"""

handler = "x86_blendvps"
jit_lowering = "arm64_neon_blendv_ps"
fallback = "zig_lane_loop_blendv_32"

neon_register_model = """
x86 xmm/ymm bit lanes are mapped into ARM64 vector temporaries. BLENDVPS is a per-lane select using sign bits from the mask register. The mask is applied via bsl. No MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by BLENDVPS/VBLENDVPS.
"""

neon_assembly = """
// NEON lowering: bsl vD.16b, vMASK.16b, vN.16b, vM.16b
// The mask register sign bits select between first and second source operands.
// For legacy: XMM0 provides mask bits; for VEX: imm8[7:4] encodes mask register.
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "BLENDVPS uses implicit XMM0 in legacy SSE form; VBLENDVPS encodes mask in imm8[7:4].",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
