// X87_FPU/FCOMI.inc
source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FCOMI.inc"
x86_handler = "x86_fcomi"
neon_lowering = "arm64_fcomi"
lowering_kind = "arm64_documented_contract"

name = "FCOMI"
aliases = []
category = "x87_fpu"
feature = "P6"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "DB F0+i", form = "FCOMI ST, ST(i)", op_en = "MI", feature = "P6", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  MI = ["ModRM:reg (r)"]
}

flags_written = ["ZF", "PF", "CF"]
simd_fp_exceptions = []

semantic_general = """
Performs unordered comparison of ST(0) and ST(i), sets ZF, PF, CF in EFLAGS. OF, SF, AF cleared to 0. Raises #IA on NaN.
"""

handler = "x86_fcomi"
jit_lowering = "arm64_fcomi"
fallback = "zig_fcomi"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes mapped to ARM64 NZCV via EFLAGS ZF/PF/CF."
neon_assembly = "// ARM64: FCMP dST0, dSTi; MRS xFLAGS, NZCV; BLR rosette_pack_fcomi_flags"
neon_notes = ["The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
