// ADD/ADDSS.inc
// ARM64/NEON translation mirror generated from ISA/x86/ADD/ADDSS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ADD/ADDSS.inc"
x86_handler = "x86_addss"
neon_lowering = "arm64_scalar_fadd_s"
lowering_kind = "neon_scalar"


name = "ADDSS"
category = "simd_scalar_float_add"
feature = "SSE"
element_type = "f32"
active_lane = 0

encodings = [
  { opcode = "F3 0F 58 /r", form = "ADDSS xmm1, xmm2/m32", op_en = "A", feature = "SSE" },
  { opcode = "VEX.LIG.F3.0F.WIG 58 /r", form = "VADDSS xmm1, xmm2, xmm3/m32", op_en = "B", feature = "AVX" }
]

semantic_legacy = """
DEST.f32[0] = DEST.f32[0] + SRC.f32[0];
DEST[127:32] unchanged;
"""

semantic_vex = """
DEST.f32[0] = SRC1.f32[0] + SRC2.f32[0];
DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

mxcsr_used = true
simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]

handler = "x86_addss"
jit_lowering = "arm64_scalar_fadd_s"

neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fadd sD, sN, sM
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
