// LOAD/VBROADCASTI64X2.inc
// VBROADCASTI64X2 — Broadcast 128 bits of 2 qword integer data to all lanes.

source_isa = "x86"
target_isa = "x86"
x86_table = "LOAD/VBROADCASTI64X2.inc"
x86_handler = "x86_vbroadcasti64x2"
neon_lowering = "arm64_neon_dup_64_pair"
lowering_kind = "neon_vector"

name = "VBROADCASTI64X2"
aliases = []
category = "simd_broadcast_integer"
feature = "AVX512DQ"
element_type = "i64"
element_size = 64

encodings = [
  { opcode = "EVEX.256.66.0F38.W1 5A /r", form = "VBROADCASTI64X2 ymm1{k1}{z}, m128", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 256, encoding = "evex", broadcast = "m128" },
  { opcode = "EVEX.512.66.0F38.W1 5A /r", form = "VBROADCASTI64X2 zmm1{k1}{z}, m128", op_en = "C", feature = "AVX512DQ", vector_length = 512, encoding = "evex", broadcast = "m128" }
]

operand_encoding = {
  C = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { ymm = 4, zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "EVEX-encoded instructions use Type E6 class exception conditions",
  "If EVEX.vvvv != 1111B, #UD",
  "If EVEX.L'L = 0, #UD",
  "Register source encoding is reserved and will #UD"
]

semantic_evex = """
(KL, VL) = (4,256), (8,512);
FOR j := 0 TO KL-1
    i := j * 64;
    n := (j modulo 2) * 64;
    IF k1[j] OR *no writemask*
        THEN DEST[i+63:i] := SRC[n+63:n]
        ELSE
            IF *merging-masking*
                THEN *DEST[i+63:i] remains unchanged*
                ELSE DEST[i+63:i] := 0
            FI
    FI;
ENDFOR;
DEST[MAXVL-1:VL] := 0;
"""

handler = "x86_vbroadcasti64x2"
jit_lowering = "arm64_neon_dup_64_pair"
fallback = "zig_lane_loop_broadcast_t64x2"

neon_register_model = """
x86 ymm/zmm qword lanes are mapped into ARM64 vector temporaries. VBROADCASTI64X2 duplicates a 2-qword memory block across all lanes.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTI64X2.
"""

neon_assembly = """
ldr qTMP, [xSRC]
; replicate 2-qword pattern across 256/512 bits
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
