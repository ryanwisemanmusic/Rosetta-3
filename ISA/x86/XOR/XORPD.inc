// XORPD.inc
// Generated directly from: XOR INSTRUCTIONS(1).md
// Instruction family: XORPD/VXORPD — Bitwise Logical XOR of Packed Double Precision Floating-Point Values

// Canonical table metadata for registry-wide .inc validation.
name = "XORPD"
semantic = """
XORPD: preserve bitwise XOR of packed 64-bit lanes.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_bitwise_logical_xor_packed_double.
"""

source_isa = "x86"
target_isa = "arm64_neon"
instruction = "XORPD"
aliases = ["VXORPD"]
category = "simd_bitwise_logical_xor_packed_double"
element_size = 64

encodings = [
  { opcode = "66 0F 57 /r", instruction = "XORPD xmm1, xmm2/m128", op_en = "A", modes = "V/V", feature = "SSE2", encoding = "legacy_sse", vector_length = 128, description = "bitwise XOR packed double values in xmm1 and xmm2/mem" },
  { opcode = "VEX.128.66.0F.WIG 57 /r", instruction = "VXORPD xmm1, xmm2, xmm3/m128", op_en = "B", modes = "V/V", feature = "AVX", encoding = "VEX.128", vector_length = 128, description = "bitwise XOR packed double values in xmm2 and xmm3/mem" },
  { opcode = "VEX.256.66.0F.WIG 57 /r", instruction = "VXORPD ymm1, ymm2, ymm3/m256", op_en = "B", modes = "V/V", feature = "AVX", encoding = "VEX.256", vector_length = 256, description = "bitwise XOR packed double values in ymm2 and ymm3/mem" },
  { opcode = "EVEX.128.66.0F.W1 57 /r", instruction = "VXORPD xmm1{k1}{z}, xmm2, xmm3/m128/m64bcst", op_en = "C", modes = "V/V", feature = "AVX512VL+AVX512DQ", encoding = "EVEX.128", vector_length = 128, broadcast = "m64bcst", description = "masked bitwise XOR packed double values" },
  { opcode = "EVEX.256.66.0F.W1 57 /r", instruction = "VXORPD ymm1{k1}{z}, ymm2, ymm3/m256/m64bcst", op_en = "C", modes = "V/V", feature = "AVX512VL+AVX512DQ", encoding = "EVEX.256", vector_length = 256, broadcast = "m64bcst", description = "masked bitwise XOR packed double values" },
  { opcode = "EVEX.512.66.0F.W1 57 /r", instruction = "VXORPD zmm1{k1}{z}, zmm2, zmm3/m512/m64bcst", op_en = "C", modes = "V/V", feature = "AVX512DQ", encoding = "EVEX.512", vector_length = 512, broadcast = "m64bcst", description = "masked bitwise XOR packed double values" }
]

operand_encoding = {
  A = { operand1 = "ModRM:reg (r,w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  B = { operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" },
  C = { operand1 = "ModRM:reg (w)", operand2 = "EVEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" }
}

operation = "bitwise XOR of packed 64-bit lanes"

semantic_legacy_sse_128 = """
DEST[63:0]   := DEST[63:0]   BITWISE XOR SRC[63:0]
DEST[127:64] := DEST[127:64] BITWISE XOR SRC[127:64]
DEST[MAXVL-1:128] remains unmodified
"""

semantic_vex_128 = """
DEST[63:0]   := SRC1[63:0]   BITWISE XOR SRC2[63:0]
DEST[127:64] := SRC1[127:64] BITWISE XOR SRC2[127:64]
DEST[MAXVL-1:128] := 0
"""

semantic_vex_256 = """
DEST[63:0]    := SRC1[63:0]    BITWISE XOR SRC2[63:0]
DEST[127:64]  := SRC1[127:64]  BITWISE XOR SRC2[127:64]
DEST[191:128] := SRC1[191:128] BITWISE XOR SRC2[191:128]
DEST[255:192] := SRC1[255:192] BITWISE XOR SRC2[255:192]
DEST[MAXVL-1:256] := 0
"""

semantic_evex = """
(KL, VL) = (2, 128), (4, 256), or (8, 512)
FOR j := 0 TO KL-1:
    i := j * 64
    IF k1[j] OR no writemask:
        IF EVEX.b == 1 AND SRC2 is memory:
            DEST[i+63:i] := SRC1[i+63:i] BITWISE XOR SRC2[63:0]
        ELSE:
            DEST[i+63:i] := SRC1[i+63:i] BITWISE XOR SRC2[i+63:i]
    ELSE:
        IF merging-masking:
            DEST[i+63:i] remains unchanged
        ELSE zeroing-masking:
            DEST[i+63:i] := 0
DEST[MAXVL-1:VL] := 0
"""

flags_affected = []
simd_floating_point_exceptions = []
other_exceptions = [
  "Non-EVEX-encoded instructions use Type 4 class exception conditions.",
  "EVEX-encoded instructions use Type E4 class exception conditions."
]

translation = {
  arm64_lowering = "NEON/ASIMD bitwise EOR over 64-bit lanes",
  legacy_upper_bits = "preserve upper MAXVL-1:128 for legacy SSE form",
  vex_upper_bits = "zero upper bits beyond VL",
  evex_masking = "honor k1 merge/zero masking and EVEX.b m64bcst broadcast"
}
