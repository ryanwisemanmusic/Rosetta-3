// AES/AESKEYGENASSIST.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "AES/AESKEYGENASSIST.inc"
x86_handler = "x86_aeskeygenassist"
neon_lowering = "arm64_aeskeygenassist"
lowering_kind = "arm64_documented_contract"

name = "AESKEYGENASSIST"
aliases = []
category = "crypto_aes"
feature = "AES"
element_type = "integer"
element_size = 128

encodings = [
  { opcode = "66 0F 3A DF /r ib", form = "AESKEYGENASSIST xmm1, xmm2/m128, imm8", op_en = "RMI", feature = "AES", vector_length = 128, encoding = "legacy" },
  { opcode = "VEX.128.66.0F3A.WIG DF /r ib", form = "VAESKEYGENASSIST xmm1, xmm2/m128, imm8", op_en = "RMI", feature = "AES AVX", vector_length = 128, encoding = "vex" }
]

operand_encoding = {
  RMI = ["ModRM:reg (w)", "ModRM:r/m (r)", "imm8"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Assists in AES round key generation by performing SubWord, RotWord, and XOR with round constant (RCON) from immediate byte.
"""

handler = "x86_aeskeygenassist"
jit_lowering = "arm64_aeskeygenassist"
fallback = "zig_aeskeygenassist"

neon_register_model = "AES state and round keys mapped to ARM64 Neon registers."
neon_flag_model = "No x86 flags modified; key locker instructions set ZF via ARM64 condition flags."
neon_assembly = "// ARM64: BLR rosette_aes_keygen_assist"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
