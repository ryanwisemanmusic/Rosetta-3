// SHIFT/SHLX.inc
// ARM64/NEON mirror generated from ISA/x86/SHIFT/SHLX.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHIFT/SHLX.inc"
x86_handler = "x86_shlx"
neon_lowering = "arm64_shlx"
lowering_kind = "arm64_documented_contract"

name = "SHLX"
aliases = []
category = "shift"
feature = "BMI2"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "VEX.LZ.66.0F38.W0 F7 /r", form = "SHLX r32a, r/m32, r32b", op_en = "RMV", feature = "BMI2", vector_length = 0, encoding = "vex" },
  { opcode = "VEX.LZ.66.0F38.W1 F7 /r", form = "SHLX r64a, r/m64, r64b", op_en = "RMV", feature = "BMI2", vector_length = 0, encoding = "vex" }
]

operand_encoding = {
  RMV = ["ModRM:reg (w)", "ModRM:r/m (r)", "VEX.vvvv (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Shifts r/m32/64 logically left by count in r32/64b. Does not update flags. BMI2 instruction.
"""

handler = "x86_shlx"
jit_lowering = "arm64_shlx"
fallback = "zig_shlx"

neon_register_model = "x86 GP registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by SHLX."
neon_assembly = "// ARM64: LSL, shifted register"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
