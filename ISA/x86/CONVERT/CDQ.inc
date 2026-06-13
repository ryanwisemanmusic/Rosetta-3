// CONVERT/CDQ.inc
// ARM64/NEON translation mirror generated from ISA/x86/CONVERT/CDQ.inc.
// Source contract: CDQ — Convert Doubleword to Quadword.

semantic = """
EDX:EAX := SignExtend(EAX)
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CONVERT/CDQ.inc"
x86_handler = "x86_cdq"
neon_lowering = "arm64_cdq"
lowering_kind = "arm64_scalar"

name = "CDQ"
aliases = []
category = "data_conversion"
feature = "x86_gpr"
element_type = "u32_u64"
element_size = 32

encodings = [
  { opcode = "99", form = "CDQ", op_en = "ZO", feature = "x86_gpr", vector_length = 0, encoding = "legacy" }
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
EDX:EAX := SignExtend(EAX);
"""

handler = "x86_cdq"
jit_lowering = "arm64_cdq"
fallback = "zig_cdq"

neon_register_model = """
x86 GPR mapped to ARM64 xN. CDQ is a scalar sign-extension operation producing a register pair.
"""

neon_flag_model = """
No x86 flags modified by CDQ.
"""

neon_assembly = """
// NEON lowering: sxtw xDEST, wSRC; DEST_HI = DEST >> 63
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
