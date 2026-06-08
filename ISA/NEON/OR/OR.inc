// OR/OR.inc
// ARM64/NEON mirror generated from ISA/x86/OR/OR.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "OR/OR.inc"
x86_handler = "x86_or"
neon_lowering = "arm64_or_with_x86_flags"
lowering_kind = "arm64_documented_contract"

// OR/OR.inc
// ARM64/NEON translation mirror generated from ISA/x86/OR/OR.inc.
// Source contract: OR — Logical Inclusive OR.


name = "OR"
category = "integer_logic"
operation = "DEST = DEST bitwise OR SRC"

encodings = [
  { opcode = "0C ib", form = "OR AL, imm8", op_en = "I", mode64 = "valid", mode_compat = "valid" },
  { opcode = "0D iw", form = "OR AX, imm16", op_en = "I", mode64 = "valid", mode_compat = "valid" },
  { opcode = "0D id", form = "OR EAX, imm32", op_en = "I", mode64 = "valid", mode_compat = "valid" },
  { opcode = "REX.W + 0D id", form = "OR RAX, imm32", op_en = "I", mode64 = "valid", mode_compat = "not_encodable", imm = "sign_extend_to_64" },

  { opcode = "80 /1 ib", form = "OR r/m8, imm8", op_en = "MI", mode64 = "valid", mode_compat = "valid" },
  { opcode = "REX + 80 /1 ib", form = "OR r/m8, imm8", op_en = "MI", mode64 = "valid", mode_compat = "not_encodable", rex_byte_register_rule = "AH_BH_CH_DH_not_encodable" },
  { opcode = "81 /1 iw", form = "OR r/m16, imm16", op_en = "MI", mode64 = "valid", mode_compat = "valid" },
  { opcode = "81 /1 id", form = "OR r/m32, imm32", op_en = "MI", mode64 = "valid", mode_compat = "valid" },
  { opcode = "REX.W + 81 /1 id", form = "OR r/m64, imm32", op_en = "MI", mode64 = "valid", mode_compat = "not_encodable", imm = "sign_extend_to_64" },
  { opcode = "83 /1 ib", form = "OR r/m16, imm8", op_en = "MI", mode64 = "valid", mode_compat = "valid", imm = "sign_extend_to_operand_size" },
  { opcode = "83 /1 ib", form = "OR r/m32, imm8", op_en = "MI", mode64 = "valid", mode_compat = "valid", imm = "sign_extend_to_operand_size" },
  { opcode = "REX.W + 83 /1 ib", form = "OR r/m64, imm8", op_en = "MI", mode64 = "valid", mode_compat = "not_encodable", imm = "sign_extend_to_64" },

  { opcode = "08 /r", form = "OR r/m8, r8", op_en = "MR", mode64 = "valid", mode_compat = "valid" },
  { opcode = "REX + 08 /r", form = "OR r/m8, r8", op_en = "MR", mode64 = "valid", mode_compat = "not_encodable", rex_byte_register_rule = "AH_BH_CH_DH_not_encodable" },
  { opcode = "09 /r", form = "OR r/m16, r16", op_en = "MR", mode64 = "valid", mode_compat = "valid" },
  { opcode = "09 /r", form = "OR r/m32, r32", op_en = "MR", mode64 = "valid", mode_compat = "valid" },
  { opcode = "REX.W + 09 /r", form = "OR r/m64, r64", op_en = "MR", mode64 = "valid", mode_compat = "not_encodable" },

  { opcode = "0A /r", form = "OR r8, r/m8", op_en = "RM", mode64 = "valid", mode_compat = "valid" },
  { opcode = "REX + 0A /r", form = "OR r8, r/m8", op_en = "RM", mode64 = "valid", mode_compat = "not_encodable", rex_byte_register_rule = "AH_BH_CH_DH_not_encodable" },
  { opcode = "0B /r", form = "OR r16, r/m16", op_en = "RM", mode64 = "valid", mode_compat = "valid" },
  { opcode = "0B /r", form = "OR r32, r/m32", op_en = "RM", mode64 = "valid", mode_compat = "valid" },
  { opcode = "REX.W + 0B /r", form = "OR r64, r/m64", op_en = "RM", mode64 = "valid", mode_compat = "not_encodable" }
]

operand_encoding = {
  I  = ["AL/AX/EAX/RAX (r,w)", "imm8/16/32"],
  MI = ["ModRM:r/m (r,w)", "imm8/16/32"],
  MR = ["ModRM:r/m (r,w)", "ModRM:reg (r)"],
  RM = ["ModRM:reg (r,w)", "ModRM:r/m (r)"]
}

reads = ["DEST", "SRC"]
writes = ["DEST"]
flags_read = []
flags_written = ["OF", "CF", "SF", "ZF", "PF", "AF"]
flags_cleared = ["OF", "CF"]
flags_undefined = ["AF"]
lock_allowed = "only_if_destination_is_memory"
memory_operands = "at_most_one_memory_operand"
mode64_default_operand_size = 32
mode64_rex_w_operand_size = 64
mode64_rex_r_allows = ["R8-R15"]

semantic = """
result = DEST | SRC;
DEST = truncate(result, operand_size);
OF = 0;
CF = 0;
SF = most_significant_bit(DEST);
ZF = (DEST == 0);
PF = parity(low8(DEST));
AF = undefined;
"""

exceptions = {
  protected_mode = [
    "#GP(0) if destination operand points to a non-writable segment",
    "#GP(0) if a memory effective address is outside CS/DS/ES/FS/GS segment limit",
    "#GP(0) if DS/ES/FS/GS contains a NULL selector when used for memory",
    "#SS(0) if a memory effective address is outside SS segment limit",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL3",
    "#UD if LOCK prefix is used but destination is not a memory operand"
  ],
  real_address_mode = [
    "#GP if a memory effective address is outside CS/DS/ES/FS/GS segment limit",
    "#SS if a memory effective address is outside SS segment limit",
    "#UD if LOCK prefix is used but destination is not a memory operand"
  ],
  virtual_8086_mode = [
    "#GP(0) if a memory effective address is outside CS/DS/ES/FS/GS segment limit",
    "#SS(0) if a memory effective address is outside SS segment limit",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made",
    "#UD if LOCK prefix is used but destination is not a memory operand"
  ],
  compatibility_mode = ["same_as_protected_mode"],
  mode64 = [
    "#SS(0) if a memory address referencing SS is non-canonical",
    "#GP(0) if the memory address is non-canonical",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL3",
    "#UD if LOCK prefix is used but destination is not a memory operand"
  ]
}

handler = "x86_or"
jit_lowering = "arm64_or_with_x86_flags"

neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback. Memory destinations preserve x86 read-modify-write and LOCK atomicity rules.
"""

neon_flag_model = """
ARM64 logical OR can update NZ flags with ORRS/ANDS-style lowering when useful, but x86 flag packing must explicitly force OF=0 and CF=0, compute PF from low byte, and mark AF undefined.
"""

neon_assembly = """
orr xD, xN, xM
bl rosette_pack_x86_logic_flags_or
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, writemask, broadcast, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
