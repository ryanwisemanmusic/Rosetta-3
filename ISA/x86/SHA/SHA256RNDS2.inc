// SHA/SHA256RNDS2.inc
// ARM64/NEON translation mirror generated from ISA/x86/SHA/SHA256RNDS2.inc.
// Source contract: SHA256RNDS2 — Perform Two Rounds of SHA256 Operation.

semantic = """
SHA256RNDS2: preserve the operation and form-specific semantic blocks.
Category: sha_hash.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHA/SHA256RNDS2.inc"
x86_handler = "x86_sha256rnds2"
neon_lowering = "arm64_sha256rnds2"
lowering_kind = "arm64_documented_contract"

name = "SHA256RNDS2"
aliases = []
category = "sha_hash"
feature = "SHA"
element_type = "u32"
element_size = 128

encodings = [
  { opcode = "NP 0F 38 CB /r", form = "SHA256RNDS2 xmm1, xmm2/m128, XMM0", op_en = "RMI", feature = "SHA", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  RMI = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "Implicit XMM0 (r)"]
}

lanes = { xmm = 1, ymm = 0 }
flags_written = []
simd_fp_exceptions = ["None"]
other_exceptions = [
  "See Table 2-21, Type 4 Class Exception Conditions"
]

semantic_general = """
A0 := SRC2[127:96]; B0 := SRC2[95:64]; C0 := SRC1[127:96]; D0 := SRC1[95:64];
E0 := SRC2[63:32]; F0 := SRC2[31:0]; G0 := SRC1[63:32]; H0 := SRC1[31:0];
WK0 := XMM0[31:0]; WK1 := XMM0[63:32];
// Two rounds of SHA256 computation
DEST[127:96] := A2; DEST[95:64] := B2; DEST[63:32] := E2; DEST[31:0] := F2;
"""

handler = "x86_sha256rnds2"
jit_lowering = "arm64_sha256rnds2"
fallback = "zig_sha256rnds2"

neon_register_model = """
x86 XMM mapped to ARM64 V寄存器. SHA256RNDS2 operates on 128-bit SIMD registers with implicit XMM0 operand.
"""

neon_flag_model = """
No x86 flags modified by SHA256RNDS2.
"""

neon_assembly = """
// NEON lowering: NEON SHA256 instructions (SHA256H/SHA256H2)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
