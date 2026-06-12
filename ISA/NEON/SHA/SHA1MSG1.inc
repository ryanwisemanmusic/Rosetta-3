// SHA/SHA1MSG1.inc
// ARM64/NEON mirror generated from ISA/x86/SHA/SHA1MSG1.inc.

semantic = """
SHA1MSG1: preserve the operation and form-specific semantic blocks.
Category: sha_hash.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHA/SHA1MSG1.inc"
x86_handler = "x86_sha1msg1"
neon_lowering = "arm64_sha1msg1"
lowering_kind = "arm64_documented_contract"

name = "SHA1MSG1"
aliases = []
category = "sha_hash"
feature = "SHA"
element_type = "u32"
element_size = 128

encodings = [
  { opcode = "NP 0F 38 C9 /r", form = "SHA1MSG1 xmm1, xmm2/m128", op_en = "RM", feature = "SHA", vector_length = 0, encoding = "legacy" }
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
W0 := SRC1[127:96];
W1 := SRC1[95:64];
W2 := SRC1[63:32];
W3 := SRC1[31:0];
W4 := SRC2[127:96];
W5 := SRC2[95:64];
DEST[127:96] := W2 XOR W0;
DEST[95:64] := W3 XOR W1;
DEST[63:32] := W4 XOR W2;
DEST[31:0] := W5 XOR W3;
"""

handler = "x86_sha1msg1"
jit_lowering = "arm64_sha1msg1"
fallback = "zig_sha1msg1"

neon_register_model = """
x86 XMM mapped to ARM64 V寄存器. SHA1MSG1 operates on 128-bit SIMD registers.
"""

neon_flag_model = """
No x86 flags modified by SHA1MSG1.
"""

neon_assembly = """
// NEON lowering: eor vD.4s, vN.4s, vM.4s; shl ...
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
