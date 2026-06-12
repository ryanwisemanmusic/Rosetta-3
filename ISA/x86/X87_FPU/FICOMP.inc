// X87_FPU/FICOMP.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FICOMP.inc"
x86_handler = "x86_ficomp"
neon_lowering = "arm64_ficomp"
lowering_kind = "arm64_documented_contract"

name = "FICOMP"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "DE /3", form = "FICOMP m16int", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DA /3", form = "FICOMP m32int", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Converts integer source to double extended-precision FP, compares with ST(0), sets C0, C2, C3 in FPU status word, then pops the register stack.
"""

handler = "x86_ficomp"
jit_lowering = "arm64_ficomp"
fallback = "zig_ficomp"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0/C2/C3 mapped to ARM64 FPSR condition flags."
neon_assembly = "// ARM64: SCVTF dTMP, wSRC; FCMP dST0, dTMP; MRS xTMP, FPSR; AND xFLAGS, xTMP, #0xC00; BLR rosette_pack_x87_compare_flags; BLR rosette_pop_x87_stack"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
