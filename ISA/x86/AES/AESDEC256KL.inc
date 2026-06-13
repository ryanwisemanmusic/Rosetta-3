// AES/AESDEC256KL.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "AES/AESDEC256KL.inc"
x86_handler = "x86_aesdec256kl"
neon_lowering = "arm64_aesdec256kl"
lowering_kind = "arm64_documented_contract"

name = "AESDEC256KL"
aliases = []
category = "crypto_aes"
feature = "AESKLE"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F3 0F 38 DF !(11):rrr:bbb", form = "AESDEC256KL xmm, m512", op_en = "A", feature = "AESKLE", vector_length = 128, encoding = "legacy" }
]

operand_encoding = {
  A = ["ModRM:reg (r, w)", "ModRM:r/m (r)"]
}

flags_written = ["ZF"]
simd_fp_exceptions = []

semantic_general = """
Performs 14 rounds of AES decryption using a 256-bit key indicated by a handle from m512. Stores result in xmm if operation succeeds.
"""

handler = "x86_aesdec256kl"
jit_lowering = "arm64_aesdec256kl"
fallback = "zig_aesdec256kl"

neon_register_model = "AES state and round keys mapped to ARM64 Neon registers."
neon_flag_model = "No x86 flags modified; key locker instructions set ZF via ARM64 condition flags."
neon_assembly = "// ARM64: BLR rosette_aes_key_locker_decrypt_256"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
