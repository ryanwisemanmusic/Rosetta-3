// DIV/DIVSS.inc
// ARM64/NEON translation mirror generated from ISA/x86/DIV/DIVSS.inc.

operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
DIVSS: preserve the operation and form-specific semantic blocks.
Category: simd_scalar_div.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "DIV/DIVSS.inc"
x86_handler = "x86_divss"
neon_lowering = "arm64_scalar_fdiv_s"
lowering_kind = "neon_scalar"

name = "DIVSS"
category = "simd_scalar_div"
feature = "SSE"
element_type = "f32"

encodings = [
  { opcode = "F3 0F 5E /r", form = "DIVSS xmm1, xmm2/m32", op_en = "A", feature = "SSE" },
  { opcode = "VEX.LIG.F3.0F.WIG 5E /r", form = "VDIVSS xmm1, xmm2, xmm3/m32", op_en = "B", feature = "AVX" },
  { opcode = "EVEX.LLIG.F3.0F.W0 5E /r", form = "VDIVSS xmm1{k1}{z}, xmm2, xmm3/m32{er}", op_en = "C", feature = "AVX512F" }
]

element_size = 32
lane_type = "scalar_single_precision_float"

mxcsr_used = true

simd_fp_exceptions = [
  "overflow",
  "underflow",
  "invalid",
  "divide_by_zero",
  "precision",
  "denormal"
]

flags_written = []

semantic_legacy_128 = """
DEST.f32[0] = DEST.f32[0] / SRC.f32[0];
DEST[MAXVL-1:32] unchanged;
"""

semantic_vex_128 = """
DEST.f32[0] = SRC1.f32[0] / SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1];
DEST.f32[2] = SRC1.f32[2];
DEST.f32[3] = SRC1.f32[3];
DEST[MAXVL-1:128] = 0;
"""

semantic_evex = """
if k1[0] or no writemask:
    DEST.f32[0] = SRC1.f32[0] / SRC2.f32[0];
else if zero_masking:
    DEST.f32[0] = 0;
DEST.f32[1] = SRC1.f32[1];
DEST.f32[2] = SRC1.f32[2];
DEST.f32[3] = SRC1.f32[3];
DEST[MAXVL-1:128] = 0;
"""

handler = "x86_divss"
jit_lowering = "arm64_scalar_fdiv_s"

neon_register_model = """
x86 scalar operand is placed in lane 0 of an ARM64 v register; upper lanes preserve the first source.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fdiv sD, sN, sM
bl rosette_merge_scalar_high_lanes
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
