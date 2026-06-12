// X87_FPU/FUCOMI.inc
// ARM64/NEON mirror generated from ISA/x86/X87_FPU/FUCOMI.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "X87_FPU/FUCOMI.inc"
x86_handler = "x86_fucomi"
neon_lowering = "arm64_fucomi"
lowering_kind = "arm64_documented_contract"

name = "FUCOMI"
aliases = []
category = "x87_fpu"
feature = "P6"
element_type = "float"
element_size = 0

encodings = [
  { opcode = "DB E8+i", form = "FUCOMI ST, ST(i)", op_en = "MI", feature = "P6", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  MI = ["ModRM:reg (r)"]
}

flags_written = ["ZF", "PF", "CF"]
simd_fp_exceptions = []

semantic_general = """
Performs unordered comparison of ST(0) and ST(i), sets ZF, PF, CF in EFLAGS. QNaN does not raise #IA (only SNaN does). OF, SF, AF cleared to 0.
"""

handler = "x86_fucomi"
jit_lowering = "arm64_fucomi"
fallback = "zig_fucomi"

neon_register_model = "x87 FPU register stack mapped to ARM64 FP/SIMD register file."
neon_flag_model = "x87 condition codes mapped to ARM64 NZCV via EFLAGS ZF/PF/CF."
neon_assembly = "// ARM64: FCMP dST0, dSTi; MRS xFLAGS, NZCV; BLR rosette_pack_fcomi_flags"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
