// NEON/CONVERT/CQO.inc
// ARM64/NEON mirror generated from ISA/x86/CONVERT/CQO.inc.

semantic = """
CQO: preserve the operation and form-specific semantic blocks.
Category: data_conversion.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CONVERT/CQO.inc"
x86_handler = "x86_cqo"
neon_lowering = "arm64_cqo"
lowering_kind = "arm64_scalar"

name = "CQO"
aliases = []
category = "data_conversion"
feature = "x86_gpr_64"
element_type = "u64_u128"
element_size = 64

encodings = [
  { opcode = "REX.W + 99", form = "CQO", op_en = "ZO", feature = "x86_gpr_64", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = ["N/A"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "#UD if LOCK prefix"
]

semantic_general = """
RDX:RAX := SignExtend(RAX);
"""

handler = "x86_cqo"
jit_lowering = "arm64_cqo"
fallback = "zig_cqo"

neon_register_model = """
x86 GPR mapped to ARM64 xN. CQO is a scalar sign-extension producing an RDX:RAX pair (64-bit mode only).
"""

neon_flag_model = """
No x86 flags modified by CQO.
"""

neon_assembly = """
// NEON lowering: sbfx pair (sign-extend 64-bit to 128-bit pair)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
