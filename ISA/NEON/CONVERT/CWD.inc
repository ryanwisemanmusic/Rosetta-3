// NEON/CONVERT/CWD.inc
// ARM64/NEON mirror generated from ISA/x86/CONVERT/CWD.inc.

semantic = """
CWD: preserve the operation and form-specific semantic blocks.
Category: data_conversion.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CONVERT/CWD.inc"
x86_handler = "x86_cwd"
neon_lowering = "arm64_cwd"
lowering_kind = "arm64_scalar"

name = "CWD"
aliases = []
category = "data_conversion"
feature = "x86_gpr"
element_type = "u16_u32"
element_size = 16

encodings = [
  { opcode = "99", form = "CWD", op_en = "ZO", feature = "x86_gpr", vector_length = 0, encoding = "legacy" }
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
DX:AX := SignExtend(AX);
"""

handler = "x86_cwd"
jit_lowering = "arm64_cwd"
fallback = "zig_cwd"

neon_register_model = """
x86 GPR mapped to ARM64 xN. CWD is a scalar sign-extension producing a DX:AX pair.
"""

neon_flag_model = """
No x86 flags modified by CWD.
"""

neon_assembly = """
// NEON lowering: sxtw xDEST, wSRC (produces DX:AX pair)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
