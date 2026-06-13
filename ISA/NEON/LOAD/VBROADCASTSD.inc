// LOAD/VBROADCASTSD.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/VBROADCASTSD.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

semantic = """
VBROADCASTSD: Broadcast double-precision floating-point element to all elements.
Category: simd_broadcast_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTSD.inc"
x86_handler = "x86_vbroadcastsd"
neon_lowering = "arm64_neon_dup_d"
lowering_kind = "arm64_documented_contract"

name = "VBROADCASTSD"
aliases = []
category = "simd_broadcast_float"
feature = "AVX_AVX2_AVX512F"
element_type = "f64"
element_size = 64

encodings = [
  { opcode = "VEX.256.66.0F38.W0 19 /r", form = "VBROADCASTSD ymm1, m64", op_en = "A", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "VEX.256.66.0F38.W0 19 /r", form = "VBROADCASTSD ymm1, xmm2", op_en = "A", feature = "AVX2", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.256.66.0F38.W1 19 /r", form = "VBROADCASTSD ymm1{k1}{z}, xmm2/m64", op_en = "B", feature = "AVX512VL+AVX512F", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F38.W1 19 /r", form = "VBROADCASTSD zmm1{k1}{z}, xmm2/m64", op_en = "B", feature = "AVX512F", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { ymm = 4, zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "VEX-encoded: Type 6 class exception conditions",
  "EVEX-encoded: Type E6 class exception conditions"
]

semantic_vex_256 = """
temp := SRC[63:0];
DEST[63:0] := temp;
DEST[127:64] := temp;
DEST[191:128] := temp;
DEST[255:192] := temp;
DEST[MAXVL-1:256] := 0;
"""

semantic_evex = """
(KL, VL) = (4, 256), (8, 512);
FOR j := 0 TO KL-1:
    i := j * 64;
    IF k1[j] OR *no writemask*:
        THEN DEST[i+63:i] := SRC[63:0];
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

handler = "x86_vbroadcastsd"
jit_lowering = "arm64_neon_dup_d"
fallback = "zig_lane_broadcast_64"

neon_register_model = """
x86 ymm/zmm broadcast lanes mapped into ARM64 NEON DUP vector.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTSD.
"""

neon_assembly = """
dup vD.2d, vN.d[0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
