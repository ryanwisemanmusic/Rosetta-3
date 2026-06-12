// CLEAR/CLTS.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/CLTS.inc"
x86_handler = "x86_clts"
neon_lowering = "arm64_clts"
lowering_kind = "arm64_documented_contract"

name = "CLTS"
aliases = []
category = "system_control"
feature = "8086"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "0F 06", form = "CLTS", op_en = "ZO", feature = "8086", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Clears the TS flag in CR0. Privileged instruction (CPL 0 only). Used to synchronize FPU context saving in multitasking.
"""

handler = "x86_clts"
jit_lowering = "arm64_clts"
fallback = "zig_clts"

neon_register_model = "x86 CR0.TS mapped to ARM64 system control register."
neon_flag_model = "TS flag in CR0 cleared via ARM64 MSR."
neon_assembly = "// ARM64: MRS xTMP, reg; BIC; MSR reg, xTMP"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
