// CLEAR/CLI.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/CLI.inc"
x86_handler = "x86_cli"
neon_lowering = "arm64_cli"
lowering_kind = "arm64_documented_contract"

name = "CLI"
aliases = []
category = "flag_control"
feature = "8086"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "FA", form = "CLI", op_en = "ZO", feature = "8086", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = ["IF", "VIF"]
simd_fp_exceptions = []

semantic_general = """
Clears the IF flag (or VIF in VME/PVI mode), disabling maskable external interrupts.
"""

handler = "x86_cli"
jit_lowering = "arm64_cli"
fallback = "zig_cli"

neon_register_model = "x86 EFLAGS.IF flag mapped to ARM64 DAIF."
neon_flag_model = "Interrupt flag cleared via ARM64 MSR DAIFSet/DAIFClr."
neon_assembly = "// ARM64: MSR DAIFClr, #2 or equivalent"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
