// CONVERT/CBW.inc
// ARM64/NEON translation mirror generated from ISA/x86/CONVERT/CBW.inc.
// Source contract: CBW — Convert Byte to Word.

semantic = """
AX := SignExtend(AL)
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CONVERT/CBW.inc"
x86_handler = "x86_cbw"
neon_lowering = "arm64_cbw"
lowering_kind = "arm64_scalar"

name = "CBW"
aliases = []
category = "data_conversion"
feature = "x86_gpr"
element_type = "u8_u16"
element_size = 8

encodings = [
  { opcode = "98", form = "CBW", op_en = "ZO", feature = "x86_gpr", vector_length = 0, encoding = "legacy" }
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
AX := SignExtend(AL);
"""

handler = "x86_cbw"
jit_lowering = "arm64_cbw"
fallback = "zig_cbw"

neon_register_model = """
x86 GPR mapped to ARM64 xN. CBW is a scalar sign-extension operation.
"""

neon_flag_model = """
No x86 flags modified by CBW.
"""

neon_assembly = """
// NEON lowering: sxtb wDEST, wSRC (16-bit result)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
