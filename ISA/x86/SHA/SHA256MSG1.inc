// SHA/SHA256MSG1.inc
// ARM64/NEON translation mirror generated from ISA/x86/SHA/SHA256MSG1.inc.
// Source contract: SHA256MSG1 — Perform an Intermediate Calculation for the Next Four SHA256 Message Dwords.

semantic = """
SHA256MSG1: preserve the operation and form-specific semantic blocks.
Category: sha_hash.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHA/SHA256MSG1.inc"
x86_handler = "x86_sha256msg1"
neon_lowering = "arm64_sha256msg1"
lowering_kind = "arm64_documented_contract"

name = "SHA256MSG1"
aliases = []
category = "sha_hash"
feature = "SHA"
element_type = "u32"
element_size = 128

encodings = [
  { opcode = "NP 0F 38 CC /r", form = "SHA256MSG1 xmm1, xmm2/m128", op_en = "RM", feature = "SHA", vector_length = 0, encoding = "legacy" }
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
W4 := SRC2[31:0];
W3 := SRC1[127:96];
W2 := SRC1[95:64];
W1 := SRC1[63:32];
W0 := SRC1[31:0];
DEST[127:96] := W3 + sigma0(W4);
DEST[95:64] := W2 + sigma0(W3);
DEST[63:32] := W1 + sigma0(W2);
DEST[31:0] := W0 + sigma0(W1);
"""

handler = "x86_sha256msg1"
jit_lowering = "arm64_sha256msg1"
fallback = "zig_sha256msg1"

neon_register_model = """
x86 XMM mapped to ARM64 V寄存器. SHA256MSG1 operates on 128-bit SIMD registers.
"""

neon_flag_model = """
No x86 flags modified by SHA256MSG1.
"""

neon_assembly = """
// NEON lowering: NEON SHA256 instructions (SHA256SU0)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
