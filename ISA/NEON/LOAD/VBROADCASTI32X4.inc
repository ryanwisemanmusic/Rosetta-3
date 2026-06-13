// LOAD/VBROADCASTI32X4.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VBROADCASTI32X4.inc.
// Source contract: VBROADCASTI32X4 — Broadcast 128 bits of 4 dword integer data to all lanes.

semantic = """
VBROADCASTI32X4: preserve the operation and form-specific semantic blocks.
Category: simd_broadcast_integer.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTI32X4.inc"
x86_handler = "x86_vbroadcasti32x4"
neon_lowering = "arm64_neon_dup_element_quad"
lowering_kind = "neon_vector"

name = "VBROADCASTI32X4"
aliases = []
category = "simd_broadcast_integer"
feature = "AVX512F"
element_type = "i32"
element_size = 32

encodings = [
  { opcode = "EVEX.256.66.0F38.W0 5A /r", form = "VBROADCASTI32X4 ymm1{k1}{z}, m128", op_en = "D", feature = "AVX512VL+AVX512F", vector_length = 256, encoding = "evex", broadcast = "m128" },
  { opcode = "EVEX.512.66.0F38.W0 5A /r", form = "VBROADCASTI32X4 zmm1{k1}{z}, m128", op_en = "D", feature = "AVX512F", vector_length = 512, encoding = "evex", broadcast = "m128" }
]

operand_encoding = {
  D = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { ymm = 8, zmm = 16 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "EVEX-encoded instructions use Type E6 class exception conditions",
  "If EVEX.vvvv != 1111B, #UD",
  "If EVEX.L'L = 0, #UD",
  "Register source encoding is reserved and will #UD"
]

semantic_evex = """
(KL, VL) = (8,256), (16,512);
FOR j := 0 TO KL-1
    i := j * 32;
    n := (j modulo 4) * 32;
    IF k1[j] OR *no writemask*
        THEN DEST[i+31:i] := SRC[n+31:n]
        ELSE
            IF *merging-masking*
                THEN *DEST[i+31:i] remains unchanged*
                ELSE DEST[i+31:i] := 0
            FI
    FI;
ENDFOR;
DEST[MAXVL-1:VL] := 0;
"""

handler = "x86_vbroadcasti32x4"
jit_lowering = "arm64_neon_dup_element_quad"
fallback = "zig_lane_loop_broadcast_t32x4"

neon_register_model = """
x86 ymm/zmm dword lanes are mapped into ARM64 vector temporaries. Since VBROADCASTI32X4 is integer, no MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTI32X4.
"""

neon_assembly = """
ldr qTMP, [xSRC]
; replicate 4-dword pattern across 256/512 bits
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
