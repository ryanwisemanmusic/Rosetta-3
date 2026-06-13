// LOAD/VPEXPANDD.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/VPEXPANDD.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
VPEXPANDD: Expand (load) contiguous doubleword integer values from dense memory to sparse elements selected by writemask k1.
Category: simd_expand_integer.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VPEXPANDD.inc"
x86_handler = "x86_vpexpandd"
neon_lowering = "arm64_neon_expand_i32"
lowering_kind = "arm64_documented_contract"

// LOAD/VPEXPANDD.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VPEXPANDD.inc.
// Source contract: VPEXPANDD — Load Sparse Packed Doubleword Integer Values From Dense Memory/Register.

name = "VPEXPANDD"
category = "simd_expand_integer"
feature = "AVX512F"
element_type = "i32"
element_size = 32

encodings = [
  { opcode = "EVEX.128.66.0F38.W0 89 /r", form = "VPEXPANDD xmm1 {k1}{z}, xmm2/m128", op_en = "A", feature = "AVX512VL AVX512F", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F38.W0 89 /r", form = "VPEXPANDD ymm1 {k1}{z}, ymm2/m256", op_en = "A", feature = "AVX512VL AVX512F", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F38.W0 89 /r", form = "VPEXPANDD zmm1 {k1}{z}, zmm2/m512", op_en = "A", feature = "AVX512F", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { xmm = 4, ymm = 8, zmm = 16 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "See Exceptions Type E4.nb in Table 2-49, Type E4 Class Exception Conditions.",
  "#UD If EVEX.vvvv != 1111B."
]

semantic_evex = """
(KL, VL) = (4, 128), (8, 256), (16, 512);
k := 0
FOR j := 0 TO KL-1
    i := j * 32
    IF k1[j] OR *no writemask*
        THEN
            DEST[i+31:i] := SRC[k+31:k];
            k := k + 32
        ELSE
            IF *merging-masking*
                THEN *DEST[i+31:i] remains unchanged*
                ELSE
                    THEN DEST[i+31:i] := 0
            FI
    FI;
ENDFOR
DEST[MAXVL-1:VL] := 0
"""

handler = "x86_vpexpandd"
jit_lowering = "arm64_neon_expand_i32"
fallback = "zig_lane_loop_expand_i32"

neon_register_model = """
VPEXPANDD expands contiguous i32 elements from dense memory/register into sparse positions selected by writemask k1. The ARM64 lowering must implement the scatter-from-dense semantic using NEON vector permute operations and mask-driven element insertion.
"""

neon_flag_model = """
No x86 flags are modified by VPEXPANDD.
"""

neon_assembly = """
// VPEXPANDD: ARM64 NEON fallback via documented contract
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "VPEXPANDD is only available with AVX512F or AVX512VL+AVX512F feature flags.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, writemask, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
