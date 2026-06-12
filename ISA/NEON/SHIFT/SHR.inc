// SHIFT/SHR.inc
// ARM64/NEON mirror generated from ISA/x86/SHIFT/SHR.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SHIFT/SHR.inc"
x86_handler = "x86_shr"
neon_lowering = "arm64_shr"
lowering_kind = "arm64_documented_contract"

name = "SHR"
aliases = []
category = "shift"
feature = "8086"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "D0 /5", form = "SHR r/m8, 1", op_en = "M1", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "REX + D0 /5", form = "SHR r/m8, 1", op_en = "M1", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "D2 /5", form = "SHR r/m8, CL", op_en = "MC", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "REX + D2 /5", form = "SHR r/m8, CL", op_en = "MC", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "C0 /5 ib", form = "SHR r/m8, imm8", op_en = "MI", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "REX + C0 /5 ib", form = "SHR r/m8, imm8", op_en = "MI", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "D1 /5", form = "SHR r/m16, 1", op_en = "M1", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "D3 /5", form = "SHR r/m16, CL", op_en = "MC", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "C1 /5 ib", form = "SHR r/m16, imm8", op_en = "MI", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "D1 /5", form = "SHR r/m32, 1", op_en = "M1", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + D1 /5", form = "SHR r/m64, 1", op_en = "M1", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "D3 /5", form = "SHR r/m32, CL", op_en = "MC", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + D3 /5", form = "SHR r/m64, CL", op_en = "MC", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "C1 /5 ib", form = "SHR r/m32, imm8", op_en = "MI", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "REX.W + C1 /5 ib", form = "SHR r/m64, imm8", op_en = "MI", feature = "8086", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  M1 = ["ModRM:r/m (r,w)", "1"],
  MC = ["ModRM:r/m (r,w)", "CL"],
  MI = ["ModRM:r/m (r,w)", "imm8"]
}

flags_written = ["CF", "OF", "SF", "ZF", "PF", "AF"]
simd_fp_exceptions = []

semantic_general = """
Shifts bits in destination operand to the right by count bits. For each shift, LSB shifted into CF, MSB cleared (logical shift).
"""

handler = "x86_shr"
jit_lowering = "arm64_shr"
fallback = "zig_shr"

neon_register_model = "x86 GP registers mapped to ARM64 X registers."
neon_flag_model = "CF, OF, SF, ZF, PF, AF set per x86 shift semantics via ARM64 shifts + flag synthesis."
neon_assembly = "// ARM64: LSR, shifted register or immediate"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
