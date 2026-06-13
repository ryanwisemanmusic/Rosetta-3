// LOAD/VBROADCASTF32X4.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VBROADCASTF32X4.inc.
// Source contract: VBROADCASTF32X4 — Load with Broadcast 4 Single-Precision Floating-Point Data.

semantic = """
VBROADCASTF32X4: Broadcast 128 bits of 4 single-precision floating-point data to all 32-bit lanes.
Category: simd_broadcast_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTF32X4.inc"
x86_handler = "x86_vbroadcastf32x4"
neon_lowering = "arm64_neon_dup_q"
lowering_kind = "neon_vector"

name = "VBROADCASTF32X4"
aliases = []
category = "simd_broadcast_float"
feature = "AVX512F"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "EVEX.256.66.0F38.W0 1A /r", form = "VBROADCASTF32X4 ymm1{k1}{z}, m128", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 256, encoding = "evex", broadcast = "m128" },
  { opcode = "EVEX.512.66.0F38.W0 1A /r", form = "VBROADCASTF32X4 zmm1{k1}{z}, m128", op_en = "D", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m128" }
]

operand_encoding = {
  D = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { ymm = 8, zmm = 16 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = ["Type E6 class exception conditions"]

semantic_evex = """
(KL, VL) = (8, 256), (16, 512);
FOR j := 0 TO KL-1:
    i := j * 32;
    n := (j modulo 4) * 32;
    IF k1[j] OR *no writemask*:
        THEN DEST[i+31:i] := SRC[n+31:n];
        ELSE:
            IF *merging-masking*:
                THEN *DEST[i+31:i] remains unchanged*;
                ELSE:
                    DEST[i+31:i] := 0;
            FI;
    FI;
ENDFOR;
DEST[MAXVL-1:VL] := 0;
"""

handler = "x86_vbroadcastf32x4"
jit_lowering = "arm64_neon_dup_q"
fallback = "zig_lane_broadcast_32_quad"

neon_register_model = """
x86 ymm/zmm 32-bit broadcast lanes mapped into ARM64 NEON vector.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTF32X4.
"""

neon_assembly = """
// VBROADCASTF32X4: ARM64 lowering via load + broadcast
ld1 {v0.4s}, [mem]
// replicate across ymm/zmm lanes
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "EVEX.L'L=0 causes #UD for VBROADCASTF32X4.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
