// CACHE/CLFLUSHOPT.inc
// ARM64/NEON mirror generated from ISA/x86/CACHE/CLFLUSHOPT.inc.

semantic = """
CLFLUSHOPT: preserve the operation and form-specific semantic blocks.
Category: cache_control.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CACHE/CLFLUSHOPT.inc"
x86_handler = "x86_clflushopt"
neon_lowering = "arm64_clflushopt"
lowering_kind = "arm64_documented_contract"

name = "CLFLUSHOPT"
aliases = []
category = "cache_control"
feature = "CLFLUSHOPT"
element_type = "cache_line"
element_size = 8

encodings = [
  { opcode = "NFx 66 0F AE /7", form = "CLFLUSHOPT m8", op_en = "M", feature = "CLFLUSHOPT", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (w)"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "#GP(0), #SS(0), #PF(fault-code), #UD if CPUID.(EAX=07H,ECX=0H):EBX.CLFLUSHOPT=0, #UD if LOCK prefix, #UD if F2H or F3H prefix"
]

semantic_general = """
Flush_Cache_Line_Optimized(SRC);
"""

handler = "x86_clflushopt"
jit_lowering = "arm64_clflushopt"
fallback = "zig_clflushopt"

neon_register_model = """
CLFLUSHOPT is a cache maintenance instruction. ARM64 DC CVAC / DC CIVAC provide equivalent functionality. Stubbed as documented contract.
"""

neon_flag_model = """
No x86 flags modified by CLFLUSHOPT.
"""

neon_assembly = """
// NEON lowering: dc cvac, xADDR; dsb sy
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
