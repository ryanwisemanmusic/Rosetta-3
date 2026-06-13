// LOAD/VBROADCASTI32x2.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VBROADCASTI32x2.inc.
// Source contract: VBROADCASTI32x2 — Broadcast two dword integer elements to all lanes.

semantic = """
VBROADCASTI32x2: preserve the operation and form-specific semantic blocks.
Category: simd_broadcast_integer.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTI32x2.inc"
x86_handler = "x86_vbroadcasti32x2"
neon_lowering = "arm64_neon_dup_element_pair"
lowering_kind = "neon_vector"

name = "VBROADCASTI32x2"
aliases = []
category = "simd_broadcast_integer"
feature = "AVX512DQ"
element_type = "i32"
element_size = 32

encodings = [
  { opcode = "EVEX.128.66.0F38.W0 59 /r", form = "VBROADCASTI32x2 xmm1{k1}{z}, xmm2/m64", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 128, encoding = "evex", broadcast = "m64" },
  { opcode = "EVEX.256.66.0F38.W0 59 /r", form = "VBROADCASTI32x2 ymm1{k1}{z}, xmm2/m64", op_en = "C", feature = "AVX512VL+AVX512DQ", vector_length = 256, encoding = "evex", broadcast = "m64" },
  { opcode = "EVEX.512.66.0F38.W0 59 /r", form = "VBROADCASTI32x2 zmm1{k1}{z}, xmm2/m64", op_en = "C", feature = "AVX512DQ", vector_length = 512, encoding = "evex", broadcast = "m64" }
]

operand_encoding = {
  C = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { xmm = 4, ymm = 8, zmm = 16 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "EVEX-encoded instructions use Type E6 class exception conditions",
  "If EVEX.vvvv != 1111B, #UD",
  "Register source encodings for VBROADCASTI32x2 are reserved and will #UD"
]

semantic_evex = """
(KL, VL) = (4,128), (8,256), (16,512);
FOR j := 0 TO KL-1
    i := j * 32;
    n := (j mod 2) * 32;
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

handler = "x86_vbroadcasti32x2"
jit_lowering = "arm64_neon_dup_element_pair"
fallback = "zig_lane_loop_broadcast_t32x2"

neon_register_model = """
x86 xmm/ymm/zmm dword lanes are mapped into ARM64 vector temporaries. Since VBROADCASTI32x2 is integer, no MXCSR floating-point exception state is generated.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTI32x2.
"""

neon_assembly = """
ldr dTMP, [xSRC]
dup vD.4s, vTMP.d[0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
