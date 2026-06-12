// BS/BSWAP.inc
// ARM64/NEON mirror generated from ISA/x86/BS/BSWAP.inc.

semantic = """
BSWAP: preserve the operation and form-specific semantic blocks.
Category: byte_swap.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BS/BSWAP.inc"
x86_handler = "x86_bswap"
neon_lowering = "arm64_bswap"
lowering_kind = "arm64_documented_contract"

name = "BSWAP"
aliases = []
category = "byte_swap"
feature = "x86_gpr"
element_type = "u32_u64"
element_size = 32

encodings = [
  { opcode = "0F C8+rd", form = "BSWAP r32", op_en = "O", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F C8+rd", form = "BSWAP r64", op_en = "O", feature = "x86_gpr", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  O = ["opcode + rd (r,w)"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "#UD if LOCK prefix"
]

semantic_general = """
TEMP := DEST;
IF 64-bit mode AND OperandSize = 64
    THEN DEST[7:0] := TEMP[63:56]; DEST[15:8] := TEMP[55:48];
         DEST[23:16] := TEMP[47:40]; DEST[31:24] := TEMP[39:32];
         DEST[39:32] := TEMP[31:24]; DEST[47:40] := TEMP[23:16];
         DEST[55:48] := TEMP[15:8]; DEST[63:56] := TEMP[7:0];
    ELSE DEST[7:0] := TEMP[31:24]; DEST[15:8] := TEMP[23:16];
         DEST[23:16] := TEMP[15:8]; DEST[31:24] := TEMP[7:0];
FI;
"""

handler = "x86_bswap"
jit_lowering = "arm64_bswap"
fallback = "zig_bswap"

neon_register_model = """
x86 GPR mapped to ARM64 xN. BSWAP is a scalar byte-reversal operation.
"""

neon_flag_model = """
No x86 flags modified by BSWAP.
"""

neon_assembly = """
// NEON lowering: rev32 xDEST, xSRC (32-bit); rev64 xDEST, xSRC (64-bit)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
