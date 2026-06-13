// LOAD/FLDCW.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/FLDCW.inc.
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/FLDCW.inc"
x86_handler = "x86_fldcw"
neon_lowering = "arm64_fldcw"
lowering_kind = "arm64_documented_contract"

name = "FLDCW"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "D9 /5", form = "FLDCW m2byte", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Loads the 16-bit source operand into the FPU control word. FPUControlWord := SRC. Used to establish or change the FPU's mode of operation. If exception flags are set in the status word and the new control word unmasks them, the exception will be generated upon the next waiting floating-point instruction.
"""

handler = "x86_fldcw"
jit_lowering = "arm64_fldcw"
fallback = "zig_fldcw"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0-C3 undefined after load."
neon_assembly = "// ARM64: BL rosette_fldcw"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
