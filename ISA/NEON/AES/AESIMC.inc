// AES/AESIMC.inc
// ARM64/NEON mirror generated from ISA/x86/AES/AESIMC.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "AES/AESIMC.inc"
x86_handler = "x86_aesimc"
neon_lowering = "arm64_aesimc"
lowering_kind = "arm64_documented_contract"

name = "AESIMC"
aliases = []
category = "crypto_aes"
feature = "AES"
element_type = "integer"
element_size = 128

encodings = [
  { opcode = "66 0F 38 DB /r", form = "AESIMC xmm1, xmm2/m128", op_en = "RM", feature = "AES", vector_length = 128, encoding = "legacy" },
  { opcode = "VEX.128.66.0F38.WIG DB /r", form = "VAESIMC xmm1, xmm2/m128", op_en = "RM", feature = "AES AVX", vector_length = 128, encoding = "vex" }
]

operand_encoding = {
  RM = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Performs the InvMixColumns transformation on a 128-bit round key. Used to prepare AES round keys for decryption via Equivalent Inverse Cipher.
"""

handler = "x86_aesimc"
jit_lowering = "arm64_aesimc"
fallback = "zig_aesimc"

neon_register_model = "AES state and round keys mapped to ARM64 Neon registers."
neon_flag_model = "No x86 flags modified; key locker instructions set ZF via ARM64 condition flags."
neon_assembly = "// ARM64: BLR rosette_aes_inv_mix_columns"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
