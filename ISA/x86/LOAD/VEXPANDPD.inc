// LOAD/VEXPANDPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/VEXPANDPD.inc.
// Source contract: VEXPANDPD — Load Sparse Packed Double Precision Floating-Point Values From Dense Memory.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
VEXPANDPD: Expand (load) contiguous double-precision floating-point values from dense memory to sparse elements selected by writemask k1.
Category: simd_expand_float.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/VEXPANDPD.inc"
x86_handler = "x86_vexpandpd"
neon_lowering = "arm64_neon_expand_pd"
lowering_kind = "neon_vector"

name = "VEXPANDPD"
category = "simd_expand_float"
feature = "AVX512F"
element_type = "f64"
element_size = 64

encodings = [
  { opcode = "EVEX.128.66.0F38.W1 88 /r", form = "VEXPANDPD xmm1 {k1}{z}, xmm2/m128", op_en = "A", feature = "AVX512VL AVX512F", vector_length = 128, encoding = "evex" },
  { opcode = "EVEX.256.66.0F38.W1 88 /r", form = "VEXPANDPD ymm1 {k1}{z}, ymm2/m256", op_en = "A", feature = "AVX512VL AVX512F", vector_length = 256, encoding = "evex" },
  { opcode = "EVEX.512.66.0F38.W1 88 /r", form = "VEXPANDPD zmm1 {k1}{z}, zmm2/m512", op_en = "A", feature = "AVX512F", vector_length = 512, encoding = "evex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { xmm = 2, ymm = 4, zmm = 8 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "See Exceptions Type E4.nb in Table 2-49, Type E4 Class Exception Conditions.",
  "#UD If EVEX.vvvv != 1111B."
]

semantic_evex = """
(KL, VL) = (2, 128), (4, 256), (8, 512);
k := 0
FOR j := 0 TO KL-1
    i := j * 64
    IF k1[j] OR *no writemask*
        THEN
            DEST[i+63:i] := SRC[k+63:k];
            k := k + 64
        ELSE
            IF *merging-masking*
                THEN *DEST[i+63:i] remains unchanged*
                ELSE
                    THEN DEST[i+63:i] := 0
            FI
    FI;
ENDFOR
DEST[MAXVL-1:VL] := 0
"""

handler = "x86_vexpandpd"
jit_lowering = "arm64_neon_expand_pd"
fallback = "zig_lane_loop_expand_64"

neon_register_model = """
VEXPANDPD expands contiguous f64 elements from dense memory/register into sparse positions selected by writemask k1. The ARM64 lowering must implement the scatter-from-dense semantic using NEON vector permute operations and mask-driven element insertion.
"""

neon_flag_model = """
No x86 flags are modified by VEXPANDPD.
"""

neon_assembly = """
// VEXPANDPD: ARM64 NEON fallback via documented contract
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "VEXPANDPD is only available with AVX512F or AVX512VL+AVX512F feature flags.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, writemask, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
