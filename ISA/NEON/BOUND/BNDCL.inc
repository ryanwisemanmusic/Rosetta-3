// BOUND/BNDCL.inc
// ARM64/NEON mirror generated from ISA/x86/BOUND/BNDCL.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BOUND/BNDCL.inc"
x86_handler = "x86_bndcl"
neon_lowering = "arm64_bndcl"
lowering_kind = "arm64_documented_contract"

name = "BNDCL"
aliases = []
category = "bounds_check"
feature = "MPX"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "F3 0F 1A /r", form = "BNDCL bnd, r/m32", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "not 64-bit" },
  { opcode = "F3 0F 1A /r", form = "BNDCL bnd, r/m64", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "64-bit" }
]

operand_encoding = {
  RM = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Compare the address in the second operand with the lower bound in bnd. If the address is lower than the lower bound, set BNDSTATUS to 01H and signal a #BR exception.
"""

handler = "x86_bndcl"
jit_lowering = "arm64_bndcl"
fallback = "zig_bndcl"

neon_register_model = "x86 MPX bound registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by BNDCL; raises exception via ARM64 SVC or trap."
neon_assembly = "// ARM64: CMP xADDR, xLB; B.LO; SVC #BR_VECTOR"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
