// CACHE/CLDEMOTE.inc
// ARM64/NEON translation mirror generated from ISA/x86/CACHE/CLDEMOTE.inc.
// Source contract: CLDEMOTE — Cache Line Demote.

semantic = """
CLDEMOTE: preserve the operation and form-specific semantic blocks.
Category: cache_control.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CACHE/CLDEMOTE.inc"
x86_handler = "x86_cldemote"
neon_lowering = "arm64_cldemote"
lowering_kind = "arm64_documented_contract"

name = "CLDEMOTE"
aliases = []
category = "cache_control"
feature = "CLDEMOTE"
element_type = "cache_line"
element_size = 8

encodings = [
  { opcode = "NP 0F 1C /0", form = "CLDEMOTE m8", op_en = "A", feature = "CLDEMOTE", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  A = ["ModRM:r/m (w)"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "#UD if LOCK prefix"
]

semantic_general = """
Cache_Line_Demote(m8);
"""

handler = "x86_cldemote"
jit_lowering = "arm64_cldemote"
fallback = "zig_cldemote"

neon_register_model = """
CLDEMOTE is a cache hint with no ARM64 equivalent. Stubbed as documented contract; no register modification.
"""

neon_flag_model = """
No x86 flags modified by CLDEMOTE.
"""

neon_assembly = """
// NEON lowering: nop (cache demotion not available on ARM64; stubbed)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
