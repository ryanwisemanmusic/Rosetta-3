// BOUND/BNDCU.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BOUND/BNDCU.inc"
x86_handler = "x86_bndcu"
neon_lowering = "arm64_bndcu"
lowering_kind = "arm64_documented_contract"

name = "BNDCU"
aliases = []
category = "bounds_check"
feature = "MPX"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F2 0F 1A /r", form = "BNDCU bnd, r/m32", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "not 64-bit" },
  { opcode = "F2 0F 1A /r", form = "BNDCU bnd, r/m64", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "64-bit" }
]

operand_encoding = {
  RM = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Compare the address in the second operand with the 1's complement of the upper bound in bnd. If the address is higher than NOT(bnd.UB), set BNDSTATUS to 01H and signal a #BR exception.
"""

handler = "x86_bndcu"
jit_lowering = "arm64_bndcu"
fallback = "zig_bndcu"

neon_register_model = "x86 MPX bound registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by BNDCU; raises exception via ARM64 SVC or trap."
neon_assembly = "// ARM64: MVN xUB_C, xUB; CMP xADDR, xUB_C; B.HI; SVC #BR_VECTOR"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
