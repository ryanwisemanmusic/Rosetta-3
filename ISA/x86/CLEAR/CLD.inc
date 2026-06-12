// CLEAR/CLD.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/CLD.inc"
x86_handler = "x86_cld"
neon_lowering = "arm64_cld"
lowering_kind = "arm64_documented_contract"

name = "CLD"
aliases = []
category = "flag_control"
feature = "8086"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "FC", form = "CLD", op_en = "ZO", feature = "8086", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = ["DF"]
simd_fp_exceptions = []

semantic_general = """
Clears the DF flag in EFLAGS. When DF is 0, string operations increment index registers.
"""

handler = "x86_cld"
jit_lowering = "arm64_cld"
fallback = "zig_cld"

neon_register_model = "x86 EFLAGS.DF flag mapped to ARM64 system register."
neon_flag_model = "DF cleared via ARM64 MSR."
neon_assembly = "// ARM64: MSR or equivalent flag clear"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
