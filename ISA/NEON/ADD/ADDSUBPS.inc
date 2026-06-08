// ADD/ADDSUBPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/ADD/ADDSUBPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
ADDSUBPS: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_add_sub.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ADD/ADDSUBPS.inc"
x86_handler = "x86_addsubps"
neon_lowering = "arm64_neon_fadd_fsub_by_lane_pattern"
lowering_kind = "neon_vector"


name = "ADDSUBPS"
category = "simd_float_add_sub"
feature = "SSE3"
element_type = "f32"

encodings = [
  { opcode = "F2 0F D0 /r", form = "ADDSUBPS xmm1, xmm2/m128", op_en = "RM", feature = "SSE3" },
  { opcode = "VEX.128.F2.0F.WIG D0 /r", form = "VADDSUBPS xmm1, xmm2, xmm3/m128", op_en = "RVM", feature = "AVX" },
  { opcode = "VEX.256.F2.0F.WIG D0 /r", form = "VADDSUBPS ymm1, ymm2, xmm3/m256", op_en = "RVM", feature = "AVX" }
]

lane_pattern = "even_lanes_subtract_odd_lanes_add"
lanes_128 = 4
lanes_256 = 8

semantic_legacy_128 = """
DEST.f32[0] = DEST.f32[0] - SRC.f32[0];
DEST.f32[1] = DEST.f32[1] + SRC.f32[1];
DEST.f32[2] = DEST.f32[2] - SRC.f32[2];
DEST.f32[3] = DEST.f32[3] + SRC.f32[3];
DEST[MAXVL-1:128] unchanged;
"""

semantic_vex_128 = """
DEST.f32[0] = SRC1.f32[0] - SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] + SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] - SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] + SRC2.f32[3];
DEST[MAXVL-1:128] = 0;
"""

semantic_vex_256 = """
DEST.f32[0] = SRC1.f32[0] - SRC2.f32[0];
DEST.f32[1] = SRC1.f32[1] + SRC2.f32[1];
DEST.f32[2] = SRC1.f32[2] - SRC2.f32[2];
DEST.f32[3] = SRC1.f32[3] + SRC2.f32[3];
DEST.f32[4] = SRC1.f32[4] - SRC2.f32[4];
DEST.f32[5] = SRC1.f32[5] + SRC2.f32[5];
DEST.f32[6] = SRC1.f32[6] - SRC2.f32[6];
DEST.f32[7] = SRC1.f32[7] + SRC2.f32[7];
"""

mxcsr_used = true
flags_written = []
simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]

memory_alignment = "m128 legacy source must be 16-byte aligned"

handler = "x86_addsubps"
jit_lowering = "arm64_neon_fadd_fsub_by_lane_pattern"
fallback = "zig_lane_loop"

neon_register_model = """
x86 xmm/ymm lanes are mapped onto ARM64 v registers; lane width and MAXVL zero/merge rules are preserved by the lowering.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fadd vTMP.4s, vN.4s, vM.4s
fsub vALT.4s, vN.4s, vM.4s
bsl vMASK.16b, vTMP.16b, vALT.16b
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
