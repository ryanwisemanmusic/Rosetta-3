// XOR/XORPS.inc
// ARM64/NEON mirror generated from ISA/x86/XOR/XORPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
name = "XORPS"
semantic = """
XORPS: preserve bitwise XOR of packed 32-bit lanes.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: simd_bitwise_logical_xor_packed_single.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "XOR/XORPS.inc"
x86_handler = "x86_xorps"
neon_lowering = "NEON/ASIMD bitwise EOR over 32-bit lanes"
lowering_kind = "arm64_documented_contract"

// XORPS.inc
// Instruction family: XORPS/VXORPS — Bitwise Logical XOR of Packed Single Precision Floating-Point Values

instruction = "XORPS"
aliases = ["VXORPS"]
category = "simd_bitwise_logical_xor_packed_single"
element_size = 32

encodings = [
  { opcode = "NP 0F 57 /r", instruction = "XORPS xmm1, xmm2/m128", op_en = "A", modes = "V/V", feature = "SSE", encoding = "legacy_sse", vector_length = 128, description = "bitwise XOR packed single values in xmm1 and xmm2/mem" },
  { opcode = "VEX.128.0F.WIG 57 /r", instruction = "VXORPS xmm1, xmm2, xmm3/m128", op_en = "B", modes = "V/V", feature = "AVX", encoding = "VEX.128", vector_length = 128, description = "bitwise XOR packed single values in xmm2 and xmm3/mem" },
  { opcode = "VEX.256.0F.WIG 57 /r", instruction = "VXORPS ymm1, ymm2, ymm3/m256", op_en = "B", modes = "V/V", feature = "AVX", encoding = "VEX.256", vector_length = 256, description = "bitwise XOR packed single values in ymm2 and ymm3/mem" },
  { opcode = "EVEX.128.0F.W0 57 /r", instruction = "VXORPS xmm1{k1}{z}, xmm2, xmm3/m128/m32bcst", op_en = "C", modes = "V/V", feature = "AVX512VL+AVX512DQ", encoding = "EVEX.128", vector_length = 128, broadcast = "m32bcst", description = "masked bitwise XOR packed single values" },
  { opcode = "EVEX.256.0F.W0 57 /r", instruction = "VXORPS ymm1{k1}{z}, ymm2, xmm3/m256/m32bcst", op_en = "C", modes = "V/V", feature = "AVX512VL+AVX512DQ", encoding = "EVEX.256", vector_length = 256, broadcast = "m32bcst", description = "masked bitwise XOR packed single values" },
  { opcode = "EVEX.512.0F.W0 57 /r", instruction = "VXORPS zmm1{k1}{z}, zmm2, zmm3/m512/m32bcst", op_en = "C", modes = "V/V", feature = "AVX512DQ", encoding = "EVEX.512", vector_length = 512, broadcast = "m32bcst", description = "masked bitwise XOR packed single values" }
]

operand_encoding = {
  A = { operand1 = "ModRM:reg (r,w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  B = { operand1 = "ModRM:reg (w)", operand2 = "VEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" },
  C = { operand1 = "ModRM:reg (w)", operand2 = "EVEX.vvvv (r)", operand3 = "ModRM:r/m (r)", operand4 = "N/A" }
}

operation = "bitwise XOR of packed 32-bit lanes"

semantic_legacy_sse_128 = """
DEST[31:0]   := DEST[31:0]   BITWISE XOR SRC[31:0]
DEST[63:32]  := DEST[63:32]  BITWISE XOR SRC[63:32]
DEST[95:64]  := DEST[95:64]  BITWISE XOR SRC[95:64]
DEST[127:96] := DEST[127:96] BITWISE XOR SRC[127:96]
DEST[MAXVL-1:128] remains unmodified
"""

semantic_vex_128 = """
DEST[31:0]   := SRC1[31:0]   BITWISE XOR SRC2[31:0]
DEST[63:32]  := SRC1[63:32]  BITWISE XOR SRC2[63:32]
DEST[95:64]  := SRC1[95:64]  BITWISE XOR SRC2[95:64]
DEST[127:96] := SRC1[127:96] BITWISE XOR SRC2[127:96]
DEST[MAXVL-1:128] := 0
"""

semantic_vex_256 = """
DEST[31:0]    := SRC1[31:0]    BITWISE XOR SRC2[31:0]
DEST[63:32]   := SRC1[63:32]   BITWISE XOR SRC2[63:32]
DEST[95:64]   := SRC1[95:64]   BITWISE XOR SRC2[95:64]
DEST[127:96]  := SRC1[127:96]  BITWISE XOR SRC2[127:96]
DEST[159:128] := SRC1[159:128] BITWISE XOR SRC2[159:128]
DEST[191:160] := SRC1[191:160] BITWISE XOR SRC2[191:160]
DEST[223:192] := SRC1[223:192] BITWISE XOR SRC2[223:192]
DEST[255:224] := SRC1[255:224] BITWISE XOR SRC2[255:224]
DEST[MAXVL-1:256] := 0
"""

semantic_evex = """
(KL, VL) = (4, 128), (8, 256), or (16, 512)
FOR j := 0 TO KL-1:
    i := j * 32
    IF k1[j] OR no writemask:
        IF EVEX.b == 1 AND SRC2 is memory:
            DEST[i+31:i] := SRC1[i+31:i] BITWISE XOR SRC2[31:0]
        ELSE:
            DEST[i+31:i] := SRC1[i+31:i] BITWISE XOR SRC2[i+31:i]
    ELSE:
        IF merging-masking:
            DEST[i+31:i] remains unchanged
        ELSE zeroing-masking:
            DEST[i+31:i] := 0
DEST[MAXVL-1:VL] := 0
"""

flags_affected = []
simd_floating_point_exceptions = []
other_exceptions = [
  "Non-EVEX-encoded instructions use Type 4 class exception conditions.",
  "EVEX-encoded instructions use Type E4 class exception conditions."
]

translation = {
  arm64_lowering = "NEON/ASIMD bitwise EOR over 32-bit lanes",
  legacy_upper_bits = "preserve upper MAXVL-1:128 for legacy SSE form",
  vex_upper_bits = "zero upper bits beyond VL",
  evex_masking = "honor k1 merge/zero masking and EVEX.b m32bcst broadcast"
}

neon_register_model = """
The x86 architectural operands, implicit state, and memory effects are read from the Rosette register file and emulated system state. ARM64 lowering must preserve the documented source contract before using native scalar or NEON instructions.
"""

neon_flag_model = """
The ARM64 lowering preserves the x86 flag behavior listed in flags_read, flags_written, flags_affected, flags_model, or source_contract. NZCV may be used internally only when repacked into x86 architectural flags.
"""

neon_assembly = """
// XORPS: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
