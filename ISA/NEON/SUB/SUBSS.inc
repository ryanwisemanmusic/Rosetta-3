// SUB/SUBSS.inc
// ARM64/NEON translation mirror generated from ISA/x86/SUB/SUBSS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SUB/SUBSS.inc"
x86_handler = "x86_subss"
neon_lowering = "arm64_neon_fsub_ss"
lowering_kind = "neon_vector"


name = "SUBSS"
category = "simd_float_subtract_scalar"
feature = "SSE"
element_type = "f32"
scalar_width = 32
mxcsr_used = true

encodings = [
  { opcode = "F3 0F 5C /r", form = "SUBSS xmm1, xmm2/m32", op_en = "A", feature = "SSE", mode = "V/V", handler = "x86_subss_xmm_xmmm32" },
  { opcode = "VEX.LIG.F3.0F.WIG 5C /r", form = "VSUBSS xmm1, xmm2, xmm3/m32", op_en = "B", feature = "AVX", mode = "V/V", handler = "x86_vsubss_xmm_xmm_xmmm32" },
  { opcode = "EVEX.LLIG.F3.0F.W0 5C /r", form = "VSUBSS xmm1 {k1}{z}, xmm2, xmm3/m32{er}", op_en = "C", feature = "AVX512F", tuple = "Tuple1 Scalar", handler = "x86_vsubss_evex" }
]

operand_encodings = [
  { op_en = "A", tuple = "N/A", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "B", tuple = "N/A", operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" },
  { op_en = "C", tuple = "Tuple1 Scalar", operand1 = "ModRM:reg (w)", operand2 = "EVEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" }
]

semantic_legacy = """
DEST[31:0] = DEST[31:0] - SRC[31:0];
DEST[MAXVL-1:32] unchanged;
"""

semantic_vex_128 = """
DEST[31:0] = SRC1[31:0] - SRC2[31:0];
DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

semantic_evex = """
if k1[0] or no writemask:
    DEST[31:0] = SRC1[31:0] - SRC2[31:0];
else merge old low element or zero according to masking mode;
DEST[127:32] = SRC1[127:32];
DEST[MAXVL-1:128] = 0;
"""

notes = [
  "Only the low single precision element is subtracted.",
  "Legacy SSE keeps upper bits above bit 31 unmodified.",
  "VEX/EVEX copies bits 127:32 from SRC1 and zeroes bits above 128.",
  "Software should encode VSUBSS with VEX.L=0; VEX.L=1 may be unpredictable across processors."
]

simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]
other_exceptions = ["VEX Type 3 class exceptions", "EVEX Type E3 class exceptions"]

handler = "x86_subss"
jit_lowering = "arm64_neon_fsub_ss"


neon_register_model = """
x86 xmm/ymm lanes are mapped onto ARM64 v registers; lane width and MAXVL zero/merge rules are preserved by the lowering.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fsub sD, sN, sM
bl rosette_merge_scalar_high_lanes
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
