// X87_FPU/FICOM.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FICOM.inc"
x86_handler = "x86_ficom"
neon_lowering = "arm64_ficom"
lowering_kind = "arm64_documented_contract"

name = "FICOM"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "DE /2", form = "FICOM m16int", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" },
  { opcode = "DA /2", form = "FICOM m32int", op_en = "M", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M = ["ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Converts integer source to double extended-precision FP, compares with ST(0), sets C0, C2, C3 in FPU status word.
"""

handler = "x86_ficom"
jit_lowering = "arm64_ficom"
fallback = "zig_ficom"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0/C2/C3 mapped to ARM64 FPSR condition flags."
neon_assembly = "// ARM64: SCVTF dTMP, wSRC; FCMP dST0, dTMP; MRS xTMP, FPSR; AND xFLAGS, xTMP, #0xC00; BLR rosette_pack_x87_compare_flags"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
