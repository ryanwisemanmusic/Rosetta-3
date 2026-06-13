// NEON/CONVERT/CDQE.inc
// ARM64/NEON mirror generated from ISA/x86/CONVERT/CDQE.inc.

semantic = """
CDQE: preserve the operation and form-specific semantic blocks.
Category: data_conversion.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CONVERT/CDQE.inc"
x86_handler = "x86_cdqe"
neon_lowering = "arm64_cdqe"
lowering_kind = "arm64_scalar"

name = "CDQE"
aliases = []
category = "data_conversion"
feature = "x86_gpr_64"
element_type = "u32_u64"
element_size = 32

encodings = [
  { opcode = "REX.W + 98", form = "CDQE", op_en = "ZO", feature = "x86_gpr_64", vector_length = 0, encoding = "legacy" }
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
RAX := SignExtend(EAX);
"""

handler = "x86_cdqe"
jit_lowering = "arm64_cdqe"
fallback = "zig_cdqe"

neon_register_model = """
x86 GPR mapped to ARM64 xN. CDQE is a scalar sign-extension (64-bit mode only).
"""

neon_flag_model = """
No x86 flags modified by CDQE.
"""

neon_assembly = """
// NEON lowering: sxtx xDEST, wSRC (sign-extend dword to 64-bit)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
