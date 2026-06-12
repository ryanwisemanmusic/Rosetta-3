// BT/BTC.inc
// ARM64/NEON translation mirror generated from ISA/x86/BT/BTC.inc.
// Source contract: BTC — Bit Test and Complement.

semantic = """
BTC: preserve the operation and form-specific semantic blocks.
Category: bit_test.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BT/BTC.inc"
x86_handler = "x86_btc"
neon_lowering = "arm64_btc"
lowering_kind = "arm64_documented_contract"

name = "BTC"
aliases = []
category = "bit_test"
feature = "x86_gpr"
element_type = "u32_u64"
element_size = 32

encodings = [
  { opcode = "0F BB /r", form = "BTC r/m16, r16", op_en = "MR", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "0F BB /r", form = "BTC r/m32, r32", op_en = "MR", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F BB /r", form = "BTC r/m64, r64", op_en = "MR", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "0F BA /7 ib", form = "BTC r/m16, imm8", op_en = "MI", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "0F BA /7 ib", form = "BTC r/m32, imm8", op_en = "MI", feature = "x86_gpr", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + 0F BA /7 ib", form = "BTC r/m64, imm8", op_en = "MI", feature = "x86_gpr", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  MR = ["ModRM:r/m (r,w)", "ModRM:reg (r)"],
  MI = ["ModRM:r/m (r,w)", "imm8"]
}

lanes = { xmm = 0, ymm = 0 }
flags_written = ["CF"]
simd_fp_exceptions = []
other_exceptions = [
  "#GP(0), #SS(0), #PF(fault-code), #AC(0), #UD if LOCK prefix used without memory operand"
]

semantic_general = """
CF := Bit(BitBase, BitOffset);
Bit(BitBase, BitOffset) := NOT Bit(BitBase, BitOffset);
OF, SF, AF, PF undefined;
"""

handler = "x86_btc"
jit_lowering = "arm64_btc"
fallback = "zig_btc"

neon_register_model = """
x86 GPR mapped to ARM64 xN. BTC is a scalar bit-test-and-complement operation.
"""

neon_flag_model = """
CF set according to x86 contract. OF, SF, AF, PF undefined.
"""

neon_assembly = """
// NEON lowering: lsr xTMP, xBASE, xOFFSET; and xCF, xTMP, #1; eor xDST, xBASE, xMASK
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
