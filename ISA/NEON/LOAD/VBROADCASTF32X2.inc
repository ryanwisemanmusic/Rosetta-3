// LOAD/VBROADCASTF32X2.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/VBROADCASTF32X2.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

semantic = """
VBROADCASTF32X2: Broadcast two single-precision floating-point elements to all 32-bit lanes.
Category: simd_broadcast_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTF32X2.inc"
x86_handler = "x86_vbroadcastf32x2"
neon_lowering = "arm64_neon_dup_s"
lowering_kind = "arm64_documented_contract"

name = "VBROADCASTF32X2"
aliases = []
category = "simd_broadcast_float"
feature = "AVX512DQ"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "EVEX.256.66.0F38.W0 19 /r", form = "VBROADCASTF32X2 ymm1{k1}{z}, xmm2/m64", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 256, encoding = "evex", broadcast = "m64bcst" },
  { opcode = "EVEX.512.66.0F38.W0 19 /r", form = "VBROADCASTF32X2 zmm1{k1}{z}, xmm2/m64", op_en = "C", feature = "AVX512DQ", vector_length = 512, encoding = "evex", broadcast = "m64bcst" }
]

operand_encoding = {
  C = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { ymm = 4, zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = ["Type E6 class exception conditions"]

semantic_evex = """
(KL, VL) = (8, 256), (16, 512);
FOR j := 0 TO KL-1:
    i := j * 32;
    n := (j mod 2) * 32;
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

handler = "x86_vbroadcastf32x2"
jit_lowering = "arm64_neon_dup_s"
fallback = "zig_lane_broadcast_32_pair"

neon_register_model = """
x86 ymm/zmm 32-bit broadcast lanes mapped into ARM64 NEON DUP vector.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTF32X2.
"""

neon_assembly = """
// VBROADCASTF32X2: ARM64 lowering via dup with two-element pattern
ld1 {v0.2s}, [mem]
dup v1.4s, v0.s[0]
dup v2.4s, v0.s[1]
// combine for ymm/zmm
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "EVEX.L'L=0 causes #UD for VBROADCASTF32X2.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
