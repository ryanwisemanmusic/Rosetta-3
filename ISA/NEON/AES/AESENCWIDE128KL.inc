// AES/AESENCWIDE128KL.inc
// ARM64/NEON mirror generated from ISA/x86/AES/AESENCWIDE128KL.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "AES/AESENCWIDE128KL.inc"
x86_handler = "x86_aesencwide128kl"
neon_lowering = "arm64_aesencwide128kl"
lowering_kind = "arm64_documented_contract"

name = "AESENCWIDE128KL"
aliases = []
category = "crypto_aes"
feature = "AESKLEWIDE_KL"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F3 0F 38 D8 !(11):000:bbb", form = "AESENCWIDE128KL m384, <XMM0-7>", op_en = "A", feature = "AESKLEWIDE_KL", vector_length = 128, encoding = "legacy" }
]

operand_encoding = {
  A = ["ModRM:r/m (r)", "Implicit XMM0-7 (r, w)"]
}

flags_written = ["ZF"]
simd_fp_exceptions = []

semantic_general = """
Performs 10 rounds of AES encryption on 8 blocks (XMM0-7) using a 128-bit key indicated by handle at m384.
"""

handler = "x86_aesencwide128kl"
jit_lowering = "arm64_aesencwide128kl"
fallback = "zig_aesencwide128kl"

neon_register_model = "AES state and round keys mapped to ARM64 Neon registers."
neon_flag_model = "No x86 flags modified; key locker instructions set ZF via ARM64 condition flags."
neon_assembly = "// ARM64: BLR rosette_aes_key_locker_encrypt_wide_128"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
