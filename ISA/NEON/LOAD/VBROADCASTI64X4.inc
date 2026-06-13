// LOAD/VBROADCASTI64X4.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VBROADCASTI64X4.inc.
// Source contract: VBROADCASTI64X4 — Broadcast 256 bits of 4 qword integer data to all lanes.

semantic = """
VBROADCASTI64X4: preserve the operation and form-specific semantic blocks.
Category: simd_broadcast_integer.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTI64X4.inc"
x86_handler = "x86_vbroadcasti64x4"
neon_lowering = "arm64_neon_replicate_256"
lowering_kind = "neon_vector"

name = "VBROADCASTI64X4"
aliases = []
category = "simd_broadcast_integer"
feature = "AVX512F"
element_type = "i64"
element_size = 64

encodings = [
  { opcode = "EVEX.512.66.0F38.W1 5B /r", form = "VBROADCASTI64X4 zmm1{k1}{z}, m256", op_en = "D", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m256" }
]

operand_encoding = {
  D = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "EVEX-encoded instructions use Type E6 class exception conditions",
  "If EVEX.vvvv != 1111B, #UD",
  "If EVEX.L'L < 10b, #UD",
  "Register source encoding is reserved and will #UD"
]

semantic_evex = """
FOR j := 0 TO 7
    i := j * 64;
    n := (j modulo 4) * 64;
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

handler = "x86_vbroadcasti64x4"
jit_lowering = "arm64_neon_replicate_256"
fallback = "zig_lane_loop_broadcast_t64x4"

neon_register_model = """
x86 zmm qword lanes are mapped into ARM64 vector temporaries. Since VBROADCASTI64X4 is integer, no MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTI64X4.
"""

neon_assembly = """
ldr qTMP_lo, [xSRC]
ldr qTMP_hi, [xSRC+16]
; replicate 256-bit pattern across 512 bits
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
