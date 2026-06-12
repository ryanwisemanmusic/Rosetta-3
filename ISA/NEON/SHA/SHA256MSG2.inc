// SHA/SHA256MSG2.inc
// ARM64/NEON mirror generated from ISA/x86/SHA/SHA256MSG2.inc.

semantic = """
SHA256MSG2: preserve the operation and form-specific semantic blocks.
Category: sha_hash.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHA/SHA256MSG2.inc"
x86_handler = "x86_sha256msg2"
neon_lowering = "arm64_sha256msg2"
lowering_kind = "arm64_documented_contract"

name = "SHA256MSG2"
aliases = []
category = "sha_hash"
feature = "SHA"
element_type = "u32"
element_size = 128

encodings = [
  { opcode = "NP 0F 38 CD /r", form = "SHA256MSG2 xmm1, xmm2/m128", op_en = "RM", feature = "SHA", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  RM = ["ModRM:reg (r,w)", "ModRM:r/m (r)"]
}

lanes = { xmm = 1, ymm = 0 }
flags_written = []
simd_fp_exceptions = ["None"]
other_exceptions = [
  "See Table 2-21, Type 4 Class Exception Conditions"
]

semantic_general = """
W14 := SRC2[95:64];
W15 := SRC2[127:96];
W16 := SRC1[31:0] + sigma1(W14);
W17 := SRC1[63:32] + sigma1(W15);
W18 := SRC1[95:64] + sigma1(W16);
W19 := SRC1[127:96] + sigma1(W17);
DEST[127:96] := W19;
DEST[95:64] := W18;
DEST[63:32] := W17;
DEST[31:0] := W16;
"""

handler = "x86_sha256msg2"
jit_lowering = "arm64_sha256msg2"
fallback = "zig_sha256msg2"

neon_register_model = """
x86 XMM mapped to ARM64 V寄存器. SHA256MSG2 operates on 128-bit SIMD registers.
"""

neon_flag_model = """
No x86 flags modified by SHA256MSG2.
"""

neon_assembly = """
// NEON lowering: NEON SHA256 instructions (SHA256SU1)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
