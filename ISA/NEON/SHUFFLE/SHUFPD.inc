// SHUFFLE/SHUFPD.inc
// ARM64/NEON mirror generated from ISA/x86/SHUFFLE/SHUFPD.inc.

semantic = """
SHUFPD: preserve the operation and form-specific semantic blocks.
Category: shuffle.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHUFFLE/SHUFPD.inc"
x86_handler = "x86_shufpd"
neon_lowering = "arm64_shufpd"
lowering_kind = "arm64_documented_contract"

name = "SHUFPD"
aliases = ["VSHUFPD"]
category = "shuffle"
feature = "SSE2"
element_type = "f64"
element_size = 64

encodings = [
  { opcode = "66 0F C6 /r ib", form = "SHUFPD xmm1, xmm2/m128, imm8", op_en = "A", feature = "SSE2", vector_length = 128, encoding = "legacy" },
  { opcode = "VEX.128.66.0F.WIG C6 /r ib", form = "VSHUFPD xmm1, xmm2, xmm3/m128, imm8", op_en = "B", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F.WIG C6 /r ib", form = "VSHUFPD ymm1, ymm2, ymm3/m256, imm8", op_en = "B", feature = "AVX", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F.W1 C6 /r ib", form = "VSHUFPD xmm1{k1}{z}, xmm2, xmm3/m128/m64bcst, imm8", op_en = "C", feature = "AVX512F", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F.W1 C6 /r ib", form = "VSHUFPD ymm1{k1}{z}, ymm2, ymm3/m256/m64bcst, imm8", op_en = "C", feature = "AVX512F", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F.W1 C6 /r ib", form = "VSHUFPD zmm1{k1}{z}, zmm2, zmm3/m512/m64bcst, imm8", op_en = "C", feature = "AVX512F", vector_length = 512, encoding = "evex" }
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
Selects double precision floating-point values from input pairs using imm8 bit controls, interleaving results from SRC1 and SRC2 into DEST. EVEX versions support writemask k1 and broadcast.
"""

handler = "x86_shufpd"
jit_lowering = "arm64_shufpd"
fallback = "zig_shufpd"

neon_register_model = """
x86 XMM/YMM/ZMM mapped to ARM64 V registers. SHUFPD is a SIMD shuffle operation.
"""

neon_flag_model = """
No x86 flags modified by SHUFPD.
"""

neon_assembly = """
// NEON lowering: ARM64 TBL or vector extract + zip instructions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
