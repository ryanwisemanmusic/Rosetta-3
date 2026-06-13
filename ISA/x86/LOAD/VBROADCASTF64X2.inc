// LOAD/VBROADCASTF64X2.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VBROADCASTF64X2.inc.
// Source contract: VBROADCASTF64X2 — Load with Broadcast 2 Double-Precision Floating-Point Data.

semantic = """
VBROADCASTF64X2: Broadcast 128 bits of 2 double-precision floating-point data to all 64-bit lanes.
Category: simd_broadcast_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTF64X2.inc"
x86_handler = "x86_vbroadcastf64x2"
neon_lowering = "arm64_neon_dup_d"
lowering_kind = "neon_vector"

name = "VBROADCASTF64X2"
aliases = []
category = "simd_broadcast_float"
feature = "AVX512DQ"
element_type = "f64"
element_size = 64

encodings = [
  { opcode = "EVEX.256.66.0F38.W1 1A /r", form = "VBROADCASTF64X2 ymm1{k1}{z}, m128", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 256, encoding = "evex", broadcast = "m128" },
  { opcode = "EVEX.512.66.0F38.W1 1A /r", form = "VBROADCASTF64X2 zmm1{k1}{z}, m128", op_en = "C", feature = "AVX512DQ", vector_length = 512, encoding = "evex", broadcast = "m128" }
]

operand_encoding = {
  C = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { ymm = 4, zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = ["Type E6 class exception conditions"]

semantic_evex = """
(KL, VL) = (4, 256), (8, 512);
FOR j := 0 TO KL-1:
    i := j * 64;
    n := (j modulo 2) * 64;
    IF k1[j] OR *no writemask*:
        THEN DEST[i+63:i] := SRC[n+63:n];
        ELSE:
            IF *merging-masking*:
                THEN *DEST[i+63:i] remains unchanged*;
                ELSE:
                    DEST[i+63:i] := 0;
            FI;
    FI;
ENDFOR;
DEST[MAXVL-1:VL] := 0;
"""

handler = "x86_vbroadcastf64x2"
jit_lowering = "arm64_neon_dup_d"
fallback = "zig_lane_broadcast_64_pair"

neon_register_model = """
x86 ymm/zmm 64-bit broadcast lanes mapped into ARM64 NEON vector.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTF64X2.
"""

neon_assembly = """
// VBROADCASTF64X2: ARM64 lowering via load + broadcast
ld1 {v0.2d}, [mem]
// replicate across ymm/zmm lanes
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "EVEX.L'L=0 causes #UD for VBROADCASTF64X2.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
