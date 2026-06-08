// SUB/SUBSD.inc
// ARM64/NEON translation mirror generated from ISA/x86/SUB/SUBSD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
SUBSD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_float_subtract_scalar.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SUB/SUBSD.inc"
x86_handler = "x86_subsd"
neon_lowering = "arm64_neon_fsub_sd"
lowering_kind = "neon_vector"


name = "SUBSD"
category = "simd_float_subtract_scalar"
feature = "SSE2"
element_type = "f64"
scalar_width = 64
mxcsr_used = true

encodings = [
  { opcode = "F2 0F 5C /r", form = "SUBSD xmm1, xmm2/m64", op_en = "A", feature = "SSE2", mode = "V/V", handler = "x86_subsd_xmm_xmmm64" },
  { opcode = "VEX.LIG.F2.0F.WIG 5C /r", form = "VSUBSD xmm1, xmm2, xmm3/m64", op_en = "B", feature = "AVX", mode = "V/V", handler = "x86_vsubsd_xmm_xmm_xmmm64" },
  { opcode = "EVEX.LLIG.F2.0F.W1 5C /r", form = "VSUBSD xmm1 {k1}{z}, xmm2, xmm3/m64{er}", op_en = "C", feature = "AVX512F", tuple = "Tuple1 Scalar", handler = "x86_vsubsd_evex" }
]

operand_encodings = [
  { op_en = "A", tuple = "N/A", operand1 = "ModRM:reg (r, w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "B", tuple = "N/A", operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" },
  { op_en = "C", tuple = "Tuple1 Scalar", operand1 = "ModRM:reg (w)", operand2 = "EVEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" }
]

semantic_legacy = """
DEST[63:0] = DEST[63:0] - SRC[63:0];
DEST[MAXVL-1:64] unchanged;
"""

semantic_vex_128 = """
DEST[63:0] = SRC1[63:0] - SRC2[63:0];
DEST[127:64] = SRC1[127:64];
DEST[MAXVL-1:128] = 0;
"""

semantic_evex = """
if k1[0] or no writemask:
    DEST[63:0] = SRC1[63:0] - SRC2[63:0];
else merge old low element or zero according to masking mode;
DEST[127:64] = SRC1[127:64];
DEST[MAXVL-1:128] = 0;
"""

notes = [
  "Only the low double precision element is subtracted.",
  "Legacy SSE keeps upper bits above bit 63 unmodified.",
  "VEX/EVEX copies bits 127:64 from SRC1 and zeroes bits above 128.",
  "Software should encode VSUBSD with VEX.L=0; VEX.L=1 may be unpredictable across processors."
]

simd_fp_exceptions = ["overflow", "underflow", "invalid", "precision", "denormal"]
other_exceptions = ["VEX Type 3 class exceptions", "EVEX Type E3 class exceptions"]

handler = "x86_subsd"
jit_lowering = "arm64_neon_fsub_sd"


neon_register_model = """
x86 xmm/ymm lanes are mapped onto ARM64 v registers; lane width and MAXVL zero/merge rules are preserved by the lowering.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fsub dD, dN, dM
bl rosette_merge_scalar_high_lanes
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
