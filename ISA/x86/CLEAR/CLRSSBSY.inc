// CLEAR/CLRSSBSY.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/CLRSSBSY.inc"
x86_handler = "x86_clrssbsy"
neon_lowering = "arm64_clrssbsy"
lowering_kind = "arm64_documented_contract"

name = "CLRSSBSY"
aliases = []
category = "shadow_stack"
feature = "CET_SS"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F3 0F AE /6", form = "CLRSSBSY m64", op_en = "M", feature = "CET_SS", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r, w)"]
}

flags_written = ["CF", "ZF", "PF", "AF", "OF", "SF"]
simd_fp_exceptions = []

semantic_general = """
Clears the busy flag in a supervisor shadow stack token referenced by m64. SSP is set to 0 after marking shadow stack as not busy.
"""

handler = "x86_clrssbsy"
jit_lowering = "arm64_clrssbsy"
fallback = "zig_clrssbsy"

neon_register_model = "x86 shadow stack and control registers mapped to ARM64 system registers."
neon_flag_model = "CF set if invalid token detected; ZF, PF, AF, OF, SF cleared."
neon_assembly = "// ARM64: CET shadow stack operations via SMC or system register interface"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
