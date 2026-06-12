// SHA/SHA1MSG2.inc
// ARM64/NEON translation mirror generated from ISA/x86/SHA/SHA1MSG2.inc.
// Source contract: SHA1MSG2 — Perform a Final Calculation for the Next Four SHA1 Message Dwords.

semantic = """
SHA1MSG2: preserve the operation and form-specific semantic blocks.
Category: sha_hash.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHA/SHA1MSG2.inc"
x86_handler = "x86_sha1msg2"
neon_lowering = "arm64_sha1msg2"
lowering_kind = "arm64_documented_contract"

name = "SHA1MSG2"
aliases = []
category = "sha_hash"
feature = "SHA"
element_type = "u32"
element_size = 128

encodings = [
  { opcode = "NP 0F 38 CA /r", form = "SHA1MSG2 xmm1, xmm2/m128", op_en = "RM", feature = "SHA", vector_length = 0, encoding = "legacy" }
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
W13 := SRC2[95:64];
W14 := SRC2[63:32];
W15 := SRC2[31:0];
W16 := (SRC1[127:96] XOR W13) ROL 1;
W17 := (SRC1[95:64] XOR W14) ROL 1;
W18 := (SRC1[63:32] XOR W15) ROL 1;
W19 := (SRC1[31:0] XOR W16) ROL 1;
DEST[127:96] := W16;
DEST[95:64] := W17;
DEST[63:32] := W18;
DEST[31:0] := W19;
"""

handler = "x86_sha1msg2"
jit_lowering = "arm64_sha1msg2"
fallback = "zig_sha1msg2"

neon_register_model = """
x86 XMM mapped to ARM64 V寄存器. SHA1MSG2 operates on 128-bit SIMD registers.
"""

neon_flag_model = """
No x86 flags modified by SHA1MSG2.
"""

neon_assembly = """
// NEON lowering: eor ...; shl ...
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
