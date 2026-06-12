// DOT_PRODUCT/DPPS.inc
// ARM64/NEON mirror generated from ISA/x86/DOT_PRODUCT/DPPS.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "DOT_PRODUCT/DPPS.inc"
x86_handler = "x86_dpps"
neon_lowering = "arm64_dpps"
lowering_kind = "arm64_documented_contract"

name = "DPPS"
aliases = ["VDPPS"]
category = "dot_product"
feature = "SSE4_1"
element_type = "f32"
element_size = 32

encodings = [
  { opcode = "66 0F 3A 40 /r ib", form = "DPPS xmm1, xmm2/m128, imm8", op_en = "RMI", feature = "SSE4_1", vector_length = 128, encoding = "legacy" },
  { opcode = "VEX.128.66.0F3A.WIG 40 /r ib", form = "VDPPS xmm1, xmm2, xmm3/m128, imm8", op_en = "RVMI", feature = "AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F3A.WIG 40 /r ib", form = "VDPPS ymm1, ymm2, ymm3/m256, imm8", op_en = "RVMI", feature = "AVX", vector_length = 256, encoding = "vex" }
]

operand_encoding = {
  RMI = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "imm8"],
  RVMI = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)", "imm8"]
}

flags_written = []
simd_fp_exceptions = ["Overflow", "Underflow", "Invalid", "Precision", "Denormal"]

semantic_general = """
Conditionally multiplies packed single precision floats depending on imm8[7:4], sums the results, and conditionally broadcasts using imm8[3:0].
"""

handler = "x86_dpps"
jit_lowering = "arm64_dpps"
fallback = "zig_dpps"

neon_register_model = "x86 XMM/YMM registers mapped to ARM64 V registers."
neon_flag_model = "No x86 flags modified by DPPS."
neon_assembly = "// NEON lowering: FMUL + FADD with mask-based selection"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
