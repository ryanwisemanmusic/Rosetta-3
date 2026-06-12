// X87_FPU/FUCOMPP.inc
// ARM64/NEON mirror generated from ISA/x86/X87_FPU/FUCOMPP.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FUCOMPP.inc"
x86_handler = "x86_fucompp"
neon_lowering = "arm64_fucompp"
lowering_kind = "arm64_documented_contract"

name = "FUCOMPP"
aliases = []
category = "x87_fpu"
feature = "8087"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "DA E9", form = "FUCOMPP", op_en = "ZO", feature = "8087", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Performs unordered comparison of ST(0) and ST(1), sets C0, C2, C3 in FPU status word, then pops the register stack twice. QNaN does not raise #IA.
"""

handler = "x86_fucompp"
jit_lowering = "arm64_fucompp"
fallback = "zig_fucompp"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes C0/C2/C3 mapped to ARM64 FPSR condition flags."
neon_assembly = "// ARM64: FCMP dST0, dST1; MRS xTMP, FPSR; AND xFLAGS, xTMP, #0xC00; BLR rosette_pack_x87_compare_flags; BLR rosette_pop_x87_stack; BLR rosette_pop_x87_stack"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
