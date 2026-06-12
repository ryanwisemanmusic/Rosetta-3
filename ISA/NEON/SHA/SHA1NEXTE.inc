// SHA/SHA1NEXTE.inc
// ARM64/NEON mirror generated from ISA/x86/SHA/SHA1NEXTE.inc.

semantic = """
SHA1NEXTE: preserve the operation and form-specific semantic blocks.
Category: sha_hash.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHA/SHA1NEXTE.inc"
x86_handler = "x86_sha1nexte"
neon_lowering = "arm64_sha1nexte"
lowering_kind = "arm64_documented_contract"

name = "SHA1NEXTE"
aliases = []
category = "sha_hash"
feature = "SHA"
element_type = "u32"
element_size = 128

encodings = [
  { opcode = "NP 0F 38 C8 /r", form = "SHA1NEXTE xmm1, xmm2/m128", op_en = "RM", feature = "SHA", vector_length = 0, encoding = "legacy" }
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
TMP := (SRC1[127:96] ROL 30);
DEST[127:96] := SRC2[127:96] + TMP;
DEST[95:64] := SRC2[95:64];
DEST[63:32] := SRC2[63:32];
DEST[31:0] := SRC2[31:0];
"""

handler = "x86_sha1nexte"
jit_lowering = "arm64_sha1nexte"
fallback = "zig_sha1nexte"

neon_register_model = """
x86 XMM mapped to ARM64 V寄存器. SHA1NEXTE operates on 128-bit SIMD registers.
"""

neon_flag_model = """
No x86 flags modified by SHA1NEXTE.
"""

neon_assembly = """
// NEON lowering: shl ...; add ...
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
