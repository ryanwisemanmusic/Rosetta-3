// CLEAR/CLC.inc
// ARM64/NEON mirror generated from ISA/x86/CLEAR/CLC.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/CLC.inc"
x86_handler = "x86_clc"
neon_lowering = "arm64_clc"
lowering_kind = "arm64_documented_contract"

name = "CLC"
aliases = []
category = "flag_control"
feature = "8086"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F8", form = "CLC", op_en = "ZO", feature = "8086", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = ["CF"]
simd_fp_exceptions = []

semantic_general = """
Clears the CF flag in EFLAGS. Operation is the same in all modes.
"""

handler = "x86_clc"
jit_lowering = "arm64_clc"
fallback = "zig_clc"

neon_register_model = "x86 EFLAGS.CF flag mapped to ARM64 system register."
neon_flag_model = "CF cleared via ARM64 MSR."
neon_assembly = "// ARM64: MSR nzcv, xTMP (clear C bit)"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
