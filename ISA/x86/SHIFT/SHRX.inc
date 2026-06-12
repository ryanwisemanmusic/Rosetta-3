// SHIFT/SHRX.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHIFT/SHRX.inc"
x86_handler = "x86_shrx"
neon_lowering = "arm64_shrx"
lowering_kind = "arm64_documented_contract"

name = "SHRX"
aliases = []
category = "shift"
feature = "BMI2"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "VEX.LZ.F2.0F38.W0 F7 /r", form = "SHRX r32a, r/m32, r32b", op_en = "RMV", feature = "BMI2", vector_length = 0, encoding = "vex" },
  { opcode = "VEX.LZ.F2.0F38.W1 F7 /r", form = "SHRX r64a, r/m64, r64b", op_en = "RMV", feature = "BMI2", vector_length = 0, encoding = "vex" }
]

operand_encoding = {
  RMV = ["ModRM:reg (w)", "ModRM:r/m (r)", "VEX.vvvv (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Shifts r/m32/64 logically right by count in r32/64b. Does not update flags. BMI2 instruction.
"""

handler = "x86_shrx"
jit_lowering = "arm64_shrx"
fallback = "zig_shrx"

neon_register_model = "x86 GP registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by SHRX."
neon_assembly = "// ARM64: LSR, shifted register"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
