// SHA/SHA1RNDS4.inc
// ARM64/NEON translation mirror generated from ISA/x86/SHA/SHA1RNDS4.inc.
// Source contract: SHA1RNDS4 — Perform Four Rounds of SHA1 Operation.

semantic = """
SHA1RNDS4: preserve the operation and form-specific semantic blocks.
Category: sha_hash.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHA/SHA1RNDS4.inc"
x86_handler = "x86_sha1rnds4"
neon_lowering = "arm64_sha1rnds4"
lowering_kind = "arm64_documented_contract"

name = "SHA1RNDS4"
aliases = []
category = "sha_hash"
feature = "SHA"
element_type = "u32"
element_size = 128

encodings = [
  { opcode = "NP 0F 3A CC /r ib", form = "SHA1RNDS4 xmm1, xmm2/m128, imm8", op_en = "RMI", feature = "SHA", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  RMI = ["ModRM:reg (r,w)", "ModRM:r/m (r)", "imm8"]
}

lanes = { xmm = 1, ymm = 0 }
flags_written = []
simd_fp_exceptions = ["None"]
other_exceptions = [
  "See Table 2-21, Type 4 Class Exception Conditions"
]

semantic_general = """
IF (imm8[1:0] = 0) THEN f() := f0(), K := K0;
ELSE IF (imm8[1:0] = 1) THEN f() := f1(), K := K1;
ELSE IF (imm8[1:0] = 2) THEN f() := f2(), K := K2;
ELSE IF (imm8[1:0] = 3) THEN f() := f3(), K := K3; FI;
A := SRC1[127:96]; B := SRC1[95:64]; C := SRC1[63:32]; D := SRC1[31:0];
W0E := SRC2[127:96]; W1 := SRC2[95:64]; W2 := SRC2[63:32]; W3 := SRC2[31:0];
// Four rounds of SHA1 computation with f() and K selected by imm8
DEST[127:96] := A_4; DEST[95:64] := B_4; DEST[63:32] := C_4; DEST[31:0] := D_4;
"""

handler = "x86_sha1rnds4"
jit_lowering = "arm64_sha1rnds4"
fallback = "zig_sha1rnds4"

neon_register_model = """
x86 XMM mapped to ARM64 V寄存器. SHA1RNDS4 operates on 128-bit SIMD registers with an immediate round selector.
"""

neon_flag_model = """
No x86 flags modified by SHA1RNDS4.
"""

neon_assembly = """
// NEON lowering: NEON SHA1 instructions (SHA1C/SHA1M/SHA1P/SHA1SU0) selected by imm8[1:0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
