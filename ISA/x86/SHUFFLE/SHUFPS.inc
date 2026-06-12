// SHUFFLE/SHUFPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/SHUFFLE/SHUFPS.inc.
// Source contract: SHUFPS — Packed Interleave Shuffle of Quadruplets of Single Precision Floating-Point Values.

semantic = """
SHUFPS: preserve the operation and form-specific semantic blocks.
Category: shuffle.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHUFFLE/SHUFPS.inc"
x86_handler = "x86_shufps"
neon_lowering = "arm64_shufps"
lowering_kind = "arm64_documented_contract"

name = "SHUFPS"
aliases = ["VSHUFPS"]
category = "shuffle"
feature = "SSE"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "NP 0F C6 /r ib", form = "SHUFPS xmm1, xmm2/m128, imm8", op_en = "A", feature = "SSE", vector_length = 128, encoding = "legacy" },
  { opcode = "VEX.128.0F.WIG C6 /r ib", form = "VSHUFPS xmm1, xmm2, xmm3/m128, imm8", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.0F.WIG C6 /r ib", form = "VSHUFPS ymm1, ymm2, ymm3/m256, imm8", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.0F.W0 C6 /r ib", form = "VSHUFPS xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst, imm8", op_en = "C", feature = "AVX512F", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.0F.W0 C6 /r ib", form = "VSHUFPS ymm1{k1}{z}, ymm2, ymm3/m256/m32bcst, imm8", op_en = "C", feature = "AVX512F", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.0F.W0 C6 /r ib", form = "VSHUFPS zmm1{k1}{z}, zmm2, zmm3/m512/m32bcst, imm8", op_en = "C", feature = "AVX512F", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "imm8"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)", "imm8"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)", "imm8"]
}

lanes = { xmm = 1, ymm = 1, zmm = 1 }
flags_written = []
simd_fp_exceptions = ["None"]
other_exceptions = [
  "Non-EVEX: See Table 2-21, Type 4 Class Exception Conditions",
  "EVEX: See Table 2-50, Type E4NF Class Exception Conditions"
]

semantic_general = """
Selects single precision floating-point values from input quadruplets using imm8 two-bit controls, interleaving results from SRC1 and SRC2 into DEST. EVEX versions support writemask k1 and broadcast.
"""

handler = "x86_shufps"
jit_lowering = "arm64_shufps"
fallback = "zig_shufps"

neon_register_model = """
x86 XMM/YMM/ZMM mapped to ARM64 V registers. SHUFPS is a SIMD shuffle operation.
"""

neon_flag_model = """
No x86 flags modified by SHUFPS.
"""

neon_assembly = """
// NEON lowering: ARM64 TBL or vector extract + zip instructions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
