// BS/BSR.inc
// ARM64/NEON mirror generated from ISA/x86/BS/BSR.inc.

semantic = """
BSR: preserve the operation and form-specific semantic blocks.
Category: bit_scan.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BS/BSR.inc"
x86_handler = "x86_bsr"
neon_lowering = "arm64_bsr"
lowering_kind = "arm64_documented_contract"

name = "BSR"
aliases = []
category = "bit_scan"
feature = "x86_gpr"
element_type = "u32_u64"
element_size = 32

encodings = [
  { opcode = "0F BD /r", form = "BSR r16, r/m16", op_en = "RM", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "0F BD /r", form = "BSR r32, r/m32", op_en = "RM", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F BD /r", form = "BSR r64, r/m64", op_en = "RM", feature = "x86_gpr", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  RM = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = ["ZF"]
simd_fp_exceptions = []
other_exceptions = [
  "#GP(0), #SS(0), #PF(fault-code), #AC(0), #UD if LOCK prefix"
]

semantic_general = """
IF SRC = 0
    THEN ZF := 1; DEST undefined;
    ELSE ZF := 0; temp := OperandSize - 1;
        WHILE Bit(SRC, temp) = 0 DO temp := temp - 1 OD;
        DEST := temp;
FI;
CF, OF, SF, AF, PF undefined;
"""

handler = "x86_bsr"
jit_lowering = "arm64_bsr"
fallback = "zig_bsr"

neon_register_model = """
x86 GPR mapped to ARM64 xN. BSR is a scalar bit-scan operation.
"""

neon_flag_model = """
ZF set according to x86 contract. CF, OF, SF, AF, PF undefined.
"""

neon_assembly = """
// NEON lowering: clz xDEST, xSRC; cmp xSRC, #0; cset xZF, eq
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
