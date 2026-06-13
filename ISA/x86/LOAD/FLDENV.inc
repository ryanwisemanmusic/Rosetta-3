// LOAD/FLDENV.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/FLDENV.inc"
x86_handler = "x86_fldenv"
neon_lowering = "arm64_fldenv"
lowering_kind = "arm64_documented_contract"

name = "FLDENV"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "D9 /4", form = "FLDENV m14byte|m28byte", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Loads the complete x87 FPU operating environment from memory into FPU registers: control word, status word, tag word, instruction pointer, data pointer, and last opcode. Should be executed in the same operating mode as the corresponding FSTENV/FNSTENV instruction. If unmasked exception flags are loaded in the status word, the exception is generated upon the next waiting floating-point instruction.
"""

handler = "x86_fldenv"
jit_lowering = "arm64_fldenv"
fallback = "zig_fldenv"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0-C3 loaded from saved environment."
neon_assembly = "// ARM64: BL rosette_fldenv"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
