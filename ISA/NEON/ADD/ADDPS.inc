// ADD/ADDPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/ADD/ADDPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
ADDPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_add.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ADD/ADDPS.inc"
x86_handler = "x86_addps"
neon_lowering = "arm64_neon_fadd_ps"
lowering_kind = "neon_vector"


name = "ADDPS"
category = "simd_float_add"
feature = "SSE"
element_type = "f32"
legacy_width = 128
lanes_128 = 4

encodings = [
  { opcode = "0F 58 /r", form = "ADDPS xmm1, xmm2/m128", op_en = "A", feature = "SSE" },
  { opcode = "VEX.128.0F.WIG 58 /r", form = "VADDPS xmm1, xmm2, xmm3/m128", op_en = "B", feature = "AVX" },
  { opcode = "VEX.256.0F.WIG 58 /r", form = "VADDPS ymm1, ymm2, ymm3/m256", op_en = "B", feature = "AVX" }
]

mxcsr_used = true
simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]

semantic_legacy = """
for lane in 0..4:
    DEST.f32[lane] = DEST.f32[lane] + SRC.f32[lane];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
for lane in 0..4:
    DEST.f32[lane] = SRC1.f32[lane] + SRC2.f32[lane];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
for lane in 0..8:
    DEST.f32[lane] = SRC1.f32[lane] + SRC2.f32[lane];
DEST[MAXVL-1:256] = 0;
"""

handler = "x86_addps"
jit_lowering = "arm64_neon_fadd_ps"

neon_register_model = """
x86 xmm/ymm lanes are mapped onto ARM64 v registers; lane width and MAXVL zero/merge rules are preserved by the lowering.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fadd vD.4s, vN.4s, vM.4s
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
