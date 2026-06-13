// LOAD/VBROADCASTF128.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VBROADCASTF128.inc.
// Source contract: VBROADCASTF128 — Load with Broadcast 128 Bits of Floating-Point Data.

semantic = """
VBROADCASTF128: Broadcast 128 bits of floating-point data to low and high 128-bits in ymm1.
Category: simd_broadcast_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VBROADCASTF128.inc"
x86_handler = "x86_vbroadcastf128"
neon_lowering = "arm64_neon_dup_q"
lowering_kind = "neon_vector"

name = "VBROADCASTF128"
aliases = []
category = "simd_broadcast_float"
feature = "AVX"
element_type = "f32_bits"
element_size = 128

encodings = [
  { opcode = "VEX.256.66.0F38.W0 1A /r", form = "VBROADCASTF128 ymm1, m128", op_en = "A", feature = "AVX", vector_length = 256, encoding = "vex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { ymm = 2 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = ["Type 6 class exception conditions"]

semantic_vex_256 = """
temp := SRC[127:0];
DEST[127:0] := temp;
DEST[255:128] := temp;
DEST[MAXVL-1:256] := 0;
"""

handler = "x86_vbroadcastf128"
jit_lowering = "arm64_neon_dup_q"
fallback = "zig_lane_broadcast_128"

neon_register_model = """
x86 ymm 128-bit halves mapped into ARM64 NEON vector.
"""

neon_flag_model = """
No x86 flags are modified by VBROADCASTF128.
"""

neon_assembly = """
// VBROADCASTF128: ARM64 lowering via load + pairwise DUP
ldr q0, [mem]
ins v1.d[0], v0.d[0]
ins v1.d[1], v0.d[1]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "VEX.L=0 causes #UD for VBROADCASTF128.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
