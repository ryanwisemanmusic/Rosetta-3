// AES/AESDEC.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "AES/AESDEC.inc"
x86_handler = "x86_aesdec"
neon_lowering = "arm64_aesdec"
lowering_kind = "arm64_documented_contract"

name = "AESDEC"
aliases = []
category = "crypto_aes"
feature = "AES"
element_type = "integer"
element_size = 128

encodings = [
  { opcode = "66 0F 38 DE /r", form = "AESDEC xmm1, xmm2/m128", op_en = "A", feature = "AES", vector_length = 128, encoding = "legacy" },
  { opcode = "VEX.128.66.0F38.WIG DE /r", form = "VAESDEC xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AES AVX", vector_length = 128, encoding = "vex" },
  { opcode = "VEX.256.66.0F38.WIG DE /r", form = "VAESDEC ymm1, ymm2, ymm3/m256", op_en = "B", feature = "VAES", vector_length = 256, encoding = "vex" },
  { opcode = "EVEX.128.66.0F38.WIG DE /r", form = "VAESDEC xmm1, xmm2, xmm3/m128", op_en = "C", feature = "VAES AVX512VL", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F38.WIG DE /r", form = "VAESDEC ymm1, ymm2, ymm3/m256", op_en = "C", feature = "VAES AVX512VL", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F38.WIG DE /r", form = "VAESDEC zmm1, zmm2, zmm3/m512", op_en = "C", feature = "VAES AVX512F", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (r, w)", "ModRM:r/m (r)"],
  B = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"],
  C = ["ModRM:reg (w)", "EVEX.vvvv (r)", "ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Performs one round of AES decryption using the Equivalent Inverse Cipher (InvShiftRows, InvSubBytes, InvMixColumns) followed by XOR with round key.
"""

handler = "x86_aesdec"
jit_lowering = "arm64_aesdec"
fallback = "zig_aesdec"

neon_register_model = "AES state and round keys mapped to ARM64 Neon registers."
neon_flag_model = "No x86 flags modified; key locker instructions set ZF via ARM64 condition flags."
neon_assembly = "// ARM64: AESD vD.16b, vN.16b; BSL vD.16b, vK.16b, vD.16b"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
