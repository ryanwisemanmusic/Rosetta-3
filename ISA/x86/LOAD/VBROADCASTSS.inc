// LOAD/VBROADCASTSS.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VBROADCASTSS.inc.
// Source contract: VBROADCASTSS — Load with Broadcast Single-Precision Floating-Point Data.

semantic = """
VBROADCASTSS: Broadcast single-precision floating-point element to all elements.
Category: simd_broadcast_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTSS.inc"
x86_handler = "x86_vbroadcastss"
neon_lowering = "arm64_neon_dup_s"
lowering_kind = "neon_vector"

name = "VBROADCASTSS"
aliases = []
category = "simd_broadcast_float"
feature = "AVX_AVX2_AVX512F"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "VEX.128.66.0F38.W0 18 /r", form = "VBROADCASTSS xmm1, m32", op_en = "A", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F38.W0 18 /r", form = "VBROADCASTSS ymm1, m32", op_en = "A", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "VEX.128.66.0F38.W0 18 /r", form = "VBROADCASTSS xmm1, xmm2", op_en = "A", feature = "AVX2", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F38.W0 18 /r", form = "VBROADCASTSS ymm1, xmm2", op_en = "A", feature = "AVX2", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F38.W0 18 /r", form = "VBROADCASTSS xmm1{k1}{z}, xmm2/m32", op_en = "B", feature = "AVX512VL+AVX512F", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F38.W0 18 /r", form = "VBROADCASTSS ymm1{k1}{z}, xmm2/m32", op_en = "B", feature = "AVX512VL+AVX512F", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F38.W0 18 /r", form = "VBROADCASTSS zmm1{k1}{z}, xmm2/m32", op_en = "B", feature = "AVX512F", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { xmm = 4, ymm = 8, zmm = 16 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "VEX-encoded: Type 6 class exception conditions",
  "EVEX-encoded: Type E6 class exception conditions"
]

semantic_vex_128 = """
temp := SRC[31:0];
DEST[31:0] := temp;
DEST[63:32] := temp;
DEST[95:64] := temp;
DEST[127:96] := temp;
DEST[MAXVL-1:128] := 0;
"""

semantic_vex_256 = """
temp := SRC[31:0];
DEST[31:0] := temp;
DEST[63:32] := temp;
DEST[95:64] := temp;
DEST[127:96] := temp;
DEST[159:128] := temp;
DEST[191:160] := temp;
DEST[223:192] := temp;
DEST[255:224] := temp;
DEST[MAXVL-1:256] := 0;
"""

semantic_evex = """
(KL, VL) = (4, 128), (8, 256), (16, 512);
FOR j := 0 TO KL-1:
    i := j * 32;
    IF k1[j] OR *no writemask*:
        THEN DEST[i+31:i] := SRC[31:0];
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

handler = "x86_vbroadcastss"
jit_lowering = "arm64_neon_dup_s"
fallback = "zig_lane_broadcast_32"

neon_register_model = """
x86 xmm/ymm/zmm broadcast lanes mapped into ARM64 NEON DUP vector.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTSS.
"""

neon_assembly = """
dup vD.4s, vN.s[0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
