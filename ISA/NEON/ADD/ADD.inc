// ADD/ADD.inc
// ARM64/NEON translation mirror generated from ISA/x86/ADD/ADD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ADD/ADD.inc"
x86_handler = "x86_add"
neon_lowering = "arm64_add_with_x86_flags"
lowering_kind = "arm64_scalar"


name = "ADD"
category = "integer_arithmetic"
operation = "dest = dest + src"

encodings = [
  { opcode = "04 ib", form = "ADD AL, imm8", op_en = "I" },
  { opcode = "05 iw", form = "ADD AX, imm16", op_en = "I" },
  { opcode = "05 id", form = "ADD EAX, imm32", op_en = "I" },
  { opcode = "80 /0 ib", form = "ADD r/m8, imm8", op_en = "MI" },
  { opcode = "81 /0 iw", form = "ADD r/m16, imm16", op_en = "MI" },
  { opcode = "81 /0 id", form = "ADD r/m32, imm32", op_en = "MI" },
  { opcode = "83 /0 ib", form = "ADD r/m16|r/m32, imm8", op_en = "MI", imm = "sign_extend" },
  { opcode = "00 /r", form = "ADD r/m8, r8", op_en = "MR" },
  { opcode = "01 /r", form = "ADD r/m16|r/m32, r16|r32", op_en = "MR" },
  { opcode = "02 /r", form = "ADD r8, r/m8", op_en = "RM" },
  { opcode = "03 /r", form = "ADD r16|r32, r/m16|r/m32", op_en = "RM" }
]

reads = ["DEST", "SRC"]
writes = ["DEST"]
flags_written = ["OF", "SF", "ZF", "AF", "CF", "PF"]

lock_allowed = "only_if_dest_is_memory"

semantic = """
result = DEST + SRC;
DEST = truncate(result, operand_size);
update_add_flags(DEST_old, SRC, result, operand_size);
"""

handler = "x86_add"
jit_lowering = "arm64_add_with_x86_flags"

neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback.
"""

neon_flag_model = """
ARM64 NZCV is repacked into x86 OF/SF/ZF/AF/CF/PF according to the source table flag contract.
"""

neon_assembly = """
adds xD, xN, xM
mrs xFLAGS, nzcv
bl rosette_pack_x86_add_flags
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
