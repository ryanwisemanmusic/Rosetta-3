// BOUND/BNDMOV.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BOUND/BNDMOV.inc"
x86_handler = "x86_bndmov"
neon_lowering = "arm64_bndmov"
lowering_kind = "arm64_documented_contract"

name = "BNDMOV"
aliases = []
category = "bounds_check"
feature = "MPX"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "66 0F 1A /r", form = "BNDMOV bnd1, bnd2/m64", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "not 64-bit" },
  { opcode = "66 0F 1A /r", form = "BNDMOV bnd1, bnd2/m128", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "64-bit" },
  { opcode = "66 0F 1B /r", form = "BNDMOV bnd1/m64, bnd2", op_en = "MR", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "not 64-bit" },
  { opcode = "66 0F 1B /r", form = "BNDMOV bnd1/m128, bnd2", op_en = "MR", feature = "MPX", vector_length = 0, encoding = "legacy", mode = "64-bit" }
]

operand_encoding = {
  RM = ["ModRM:reg (w)", "ModRM:r/m (r)"],
  MR = ["ModRM:r/m (w)", "ModRM:reg (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Move a pair of lower and upper bound values from the source operand to the destination. Each operation is a 128-bit move.
"""

handler = "x86_bndmov"
jit_lowering = "arm64_bndmov"
fallback = "zig_bndmov"

neon_register_model = "x86 MPX bound registers mapped to ARM64 X register pairs."
neon_flag_model = "No x86 flags modified by BNDMOV."
neon_assembly = "// ARM64: LDP/STP or MOV for 128-bit bound register transfer"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
