// X87_FPU/FCOM.inc
// ARM64/NEON mirror generated from ISA/x86/X87_FPU/FCOM.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FCOM.inc"
x86_handler = "x86_fcom"
neon_lowering = "arm64_fcom"
lowering_kind = "arm64_documented_contract"

name = "FCOM"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "D8 /2", form = "FCOM m32fp", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DC /2", form = "FCOM m64fp", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "D8 D0+i", form = "FCOM ST(i)", op_en = "MI", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "D8 D1", form = "FCOM", op_en = "ZO", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"],
  MI = ["ModRM:reg (r)"],
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Compares ST(0) with source operand and sets condition code flags C0, C2, C3 in FPU status word. Results are signed-ignoring-zero (-0.0 = +0.0). Raises #IA on NaN or unsupported format.
"""

handler = "x86_fcom"
jit_lowering = "arm64_fcom"
fallback = "zig_fcom"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0/C2/C3 mapped to ARM64 FPSR condition flags."
neon_assembly = "// ARM64: FCMP dST, dSRC; MRS xTMP, FPSR; AND xFLAGS, xTMP, #0xC00; BLR rosette_pack_x87_compare_flags"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
