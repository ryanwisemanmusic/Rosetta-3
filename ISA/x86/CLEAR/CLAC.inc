// CLEAR/CLAC.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/CLAC.inc"
x86_handler = "x86_clac"
neon_lowering = "arm64_clac"
lowering_kind = "arm64_documented_contract"

name = "CLAC"
aliases = []
category = "flag_control"
feature = "SMAP"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "NP 0F 01 CA", form = "CLAC", op_en = "ZO", feature = "SMAP", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = ["AC"]
simd_fp_exceptions = []

semantic_general = """
Clears the AC flag in EFLAGS, disabling alignment checking of user-mode data accesses.
"""

handler = "x86_clac"
jit_lowering = "arm64_clac"
fallback = "zig_clac"

neon_register_model = "x86 EFLAGS.AC flag mapped to ARM64 system register."
neon_flag_model = "AC flag cleared via ARM64 MSR."
neon_assembly = "// ARM64: MSR DAIF or MRS xTMP, nzcv; BIC"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
