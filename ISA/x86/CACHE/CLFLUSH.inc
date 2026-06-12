// CACHE/CLFLUSH.inc
// ARM64/NEON translation mirror generated from ISA/x86/CACHE/CLFLUSH.inc.
// Source contract: CLFLUSH — Flush Cache Line.

semantic = """
CLFLUSH: preserve the operation and form-specific semantic blocks.
Category: cache_control.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CACHE/CLFLUSH.inc"
x86_handler = "x86_clflush"
neon_lowering = "arm64_clflush"
lowering_kind = "arm64_documented_contract"

name = "CLFLUSH"
aliases = []
category = "cache_control"
feature = "CLFSH"
element_type = "cache_line"
element_size = 8

encodings = [
  { opcode = "NP 0F AE /7", form = "CLFLUSH m8", op_en = "M", feature = "CLFSH", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (w)"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "#GP(0), #SS(0), #PF(fault-code), #UD if CPUID.01H:EDX.CLFSH=0, #UD if LOCK prefix"
]

semantic_general = """
Flush_Cache_Line(SRC);
"""

handler = "x86_clflush"
jit_lowering = "arm64_clflush"
fallback = "zig_clflush"

neon_register_model = """
CLFLUSH is a cache maintenance instruction. ARM64 DC CVAC / DC CIVAC provide equivalent functionality. Stubbed as documented contract.
"""

neon_flag_model = """
No x86 flags modified by CLFLUSH.
"""

neon_assembly = """
// NEON lowering: dc cvac, xADDR; dsb sy
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
