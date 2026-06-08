// ADD/ADDSD.inc
// ARM64/NEON translation mirror generated from ISA/x86/ADD/ADDSD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
ADDSD: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_scalar_float_add.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ADD/ADDSD.inc"
x86_handler = "x86_addsd"
neon_lowering = "arm64_scalar_fadd_d"
lowering_kind = "neon_scalar"


name = "ADDSD"
category = "simd_scalar_float_add"
feature = "SSE2"
element_type = "f64"

encodings = [
  { opcode = "F2 0F 58 /r", form = "ADDSD xmm1, xmm2/m64", op_en = "A", feature = "SSE2" },
  { opcode = "VEX.LIG.F2.0F.WIG 58 /r", form = "VADDSD xmm1, xmm2, xmm3/m64", op_en = "B", feature = "AVX" },
  { opcode = "EVEX.LLIG.F2.0F.W1 58 /r", form = "VADDSD xmm1{k1}{z}, xmm2, xmm3/m64", op_en = "C", feature = "AVX512F" }
]

element_size = 64
active_lane = 0
lane_type = "scalar_double_precision"

mxcsr_used = true

simd_fp_exceptions = [
  "overflow",
  "underflow",
  "invalid",
  "precision",
  "denormal"
]

flags_written = []

semantic_legacy = """
DEST.f64[0] = DEST.f64[0] + SRC.f64[0];
DEST[MAXVL-1:64] unchanged;
"""

semantic_vex = """
DEST.f64[0] = SRC1.f64[0] + SRC2.f64[0];
DEST[127:64] = SRC1[127:64];
DEST[MAXVL-1:128] = 0;
"""

semantic_evex = """
if writemask_enabled:
    DEST.f64[0] = SRC1.f64[0] + SRC2.f64[0];
else if zero_masking:
    DEST.f64[0] = 0;

DEST[127:64] = SRC1[127:64];
DEST[MAXVL-1:128] = 0;
"""

handler = "x86_addsd"
jit_lowering = "arm64_scalar_fadd_d"
fallback = "zig_scalar_double"


neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback.
"""

neon_flag_model = """
MXCSR exception/status behavior is preserved through Rosette SIMD floating-point side-effect handlers.
"""

neon_assembly = """
fadd dD, dN, dM
bl rosette_apply_mxcsr_float_exceptions
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
