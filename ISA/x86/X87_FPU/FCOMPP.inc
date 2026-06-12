// X87_FPU/FCOMPP.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FCOMPP.inc"
x86_handler = "x86_fcompp"
neon_lowering = "arm64_fcompp"
lowering_kind = "arm64_documented_contract"

name = "FCOMPP"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "DE D9", form = "FCOMPP", op_en = "ZO", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Compares ST(0) with ST(1), sets condition code flags C0, C2, C3 in FPU status word, then pops the register stack twice.
"""

handler = "x86_fcompp"
jit_lowering = "arm64_fcompp"
fallback = "zig_fcompp"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0/C2/C3 mapped to ARM64 FPSR condition flags."
neon_assembly = "// ARM64: FCMP dST0, dST1; MRS xTMP, FPSR; AND xFLAGS, xTMP, #0xC00; BLR rosette_pack_x87_compare_flags; BLR rosette_pop_x87_stack; BLR rosette_pop_x87_stack"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
