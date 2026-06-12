// CLEAR/CLUI.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/CLUI.inc"
x86_handler = "x86_clui"
neon_lowering = "arm64_clui"
lowering_kind = "arm64_documented_contract"

name = "CLUI"
aliases = []
category = "flag_control"
feature = "UINTR"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F3 0F 01 EE", form = "CLUI", op_en = "ZO", feature = "UINTR", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Clears the user interrupt flag (UIF). User interrupts are blocked when UIF is cleared.
"""

handler = "x86_clui"
jit_lowering = "arm64_clui"
fallback = "zig_clui"

neon_register_model = "x86 UIF mapped to ARM64 system register."
neon_flag_model = "UIF cleared via ARM64 MSR."
neon_assembly = "// ARM64: MSR or system register write"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
