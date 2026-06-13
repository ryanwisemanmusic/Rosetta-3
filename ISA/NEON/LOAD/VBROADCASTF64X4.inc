// LOAD/VBROADCASTF64X4.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/VBROADCASTF64X4.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

semantic = """
VBROADCASTF64X4: Broadcast 256 bits of 4 double-precision floating-point data to all 64-bit lanes.
Category: simd_broadcast_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTF64X4.inc"
x86_handler = "x86_vbroadcastf64x4"
neon_lowering = "arm64_neon_dup_d"
lowering_kind = "arm64_documented_contract"

name = "VBROADCASTF64X4"
aliases = []
category = "simd_broadcast_float"
feature = "AVX512F"
element_type = "f64"
element_size = 64

encodings = [
  { opcode = "EVEX.512.66.0F38.W1 1B /r", form = "VBROADCASTF64X4 zmm1{k1}{z}, m256", op_en = "D", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m256" }
]

operand_encoding = {
  D = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = ["Type E6 class exception conditions"]

semantic_evex = """
(KL, VL) = (8, 512);
FOR j := 0 TO 7:
    i := j * 64;
    n := (j modulo 4) * 64;
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

handler = "x86_vbroadcastf64x4"
jit_lowering = "arm64_neon_dup_d"
fallback = "zig_lane_broadcast_64_quad"

neon_register_model = """
x86 zmm 64-bit broadcast lanes mapped into ARM64 NEON vector.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTF64X4.
"""

neon_assembly = """
// VBROADCASTF64X4: ARM64 lowering via load + broadcast
ld1 {v0.4d}, [mem]
// replicate across zmm lanes
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "EVEX.L'L<10b causes #UD for VBROADCASTF64X4.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
