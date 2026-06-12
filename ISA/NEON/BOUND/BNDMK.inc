// BOUND/BNDMK.inc
// ARM64/NEON mirror generated from ISA/x86/BOUND/BNDMK.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BOUND/BNDMK.inc"
x86_handler = "x86_bndmk"
neon_lowering = "arm64_bndmk"
lowering_kind = "arm64_documented_contract"

name = "BNDMK"
aliases = []
category = "bounds_check"
feature = "MPX"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F3 0F 1B /r", form = "BNDMK bnd, m32", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "not 64-bit" },
  { opcode = "F3 0F 1B /r", form = "BNDMK bnd, m64", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "64-bit" }
]

operand_encoding = {
  RM = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Make bounds from the second operand and store the lower and upper bounds in the bound register bnd. Lower bound is the base register value; upper bound is 1's complement of the effective address.
"""

handler = "x86_bndmk"
jit_lowering = "arm64_bndmk"
fallback = "zig_bndmk"

neon_register_model = "x86 MPX bound registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by BNDMK."
neon_assembly = "// ARM64: MOV xLB, xBASE; MVN xUB, xADDR"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
