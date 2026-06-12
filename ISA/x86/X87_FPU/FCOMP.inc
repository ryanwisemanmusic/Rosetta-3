// X87_FPU/FCOMP.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FCOMP.inc"
x86_handler = "x86_fcomp"
neon_lowering = "arm64_fcomp"
lowering_kind = "arm64_documented_contract"

name = "FCOMP"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "D8 /3", form = "FCOMP m32fp", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DC /3", form = "FCOMP m64fp", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "D8 D8+i", form = "FCOMP ST(i)", op_en = "MI", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "D8 D9", form = "FCOMP", op_en = "ZO", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"],
  MI = ["ModRM:reg (r)"],
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Compares ST(0) with source operand, sets condition code flags C0, C2, C3 in FPU status word, then pops the register stack.
"""

handler = "x86_fcomp"
jit_lowering = "arm64_fcomp"
fallback = "zig_fcomp"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0/C2/C3 mapped to ARM64 FPSR condition flags."
neon_assembly = "// ARM64: FCMP dST, dSRC; MRS xTMP, FPSR; AND xFLAGS, xTMP, #0xC00; BLR rosette_pack_x87_compare_flags; BLR rosette_pop_x87_stack"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
