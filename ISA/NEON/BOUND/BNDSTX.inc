// BOUND/BNDSTX.inc
// ARM64/NEON mirror generated from ISA/x86/BOUND/BNDSTX.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BOUND/BNDSTX.inc"
x86_handler = "x86_bndstx"
neon_lowering = "arm64_bndstx"
lowering_kind = "arm64_documented_contract"

name = "BNDSTX"
aliases = []
category = "bounds_check"
feature = "MPX"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "NP 0F 1B /r", form = "BNDSTX mib, bnd", op_en = "MR", feature = "MPX", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  MR = ["SIB.base (r): Address of pointer SIB.index(r)", "ModRM:reg (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Store the bounds in bnd and the pointer value in the index register of mib to a bound table entry (BTE) with address translation using the base of mib.
"""

handler = "x86_bndstx"
jit_lowering = "arm64_bndstx"
fallback = "zig_bndstx"

neon_register_model = "x86 MPX bound registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by BNDSTX."
neon_assembly = "// ARM64: STR/STP sequence for bound table entry write via address translation"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
