// BOUND/BNDLDX.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BOUND/BNDLDX.inc"
x86_handler = "x86_bndldx"
neon_lowering = "arm64_bndldx"
lowering_kind = "arm64_documented_contract"

name = "BNDLDX"
aliases = []
category = "bounds_check"
feature = "MPX"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "NP 0F 1A /r", form = "BNDLDX bnd, mib", op_en = "RM", feature = "MPX", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  RM = ["ModRM:reg (w)", "SIB.base (r): Address of pointer SIB.index(r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Load the bounds stored in a bound table entry (BTE) into bnd with address translation using the base of mib and conditional on the index of mib matching the pointer value in the BTE.
"""

handler = "x86_bndldx"
jit_lowering = "arm64_bndldx"
fallback = "zig_bndldx"

neon_register_model = "x86 MPX bound registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by BNDLDX."
neon_assembly = "// ARM64: LDR/STR sequence for bound table entry access via address translation"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
