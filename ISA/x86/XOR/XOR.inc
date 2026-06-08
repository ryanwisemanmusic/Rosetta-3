// XOR.inc
// Generated directly from: XOR INSTRUCTIONS(1).md
// Instruction family: XOR — Logical Exclusive OR

// Canonical table metadata for registry-wide .inc validation.
name = "XOR"

source_isa = "x86"
target_isa = "arm64_neon"
instruction = "XOR"
category = "integer_logical_exclusive_or"
summary = "Performs bitwise exclusive OR between destination and source, stores result in destination."

encodings = [
  { opcode = "34 ib", instruction = "XOR AL, imm8", op_en = "I", mode64 = "Valid", compat = "Valid", description = "AL XOR imm8" },
  { opcode = "35 iw", instruction = "XOR AX, imm16", op_en = "I", mode64 = "Valid", compat = "Valid", description = "AX XOR imm16" },
  { opcode = "35 id", instruction = "XOR EAX, imm32", op_en = "I", mode64 = "Valid", compat = "Valid", description = "EAX XOR imm32" },
  { opcode = "REX.W + 35 id", instruction = "XOR RAX, imm32", op_en = "I", mode64 = "Valid", compat = "N.E.", description = "RAX XOR imm32 sign-extended" },

  { opcode = "80 /6 ib", instruction = "XOR r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "r/m8 XOR imm8" },
  { opcode = "REX + 80 /6 ib", instruction = "XOR r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "r/m8 XOR imm8; AH/BH/CH/DH unavailable with REX" },
  { opcode = "81 /6 iw", instruction = "XOR r/m16, imm16", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "r/m16 XOR imm16" },
  { opcode = "81 /6 id", instruction = "XOR r/m32, imm32", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "r/m32 XOR imm32" },
  { opcode = "REX.W + 81 /6 id", instruction = "XOR r/m64, imm32", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "r/m64 XOR imm32 sign-extended" },
  { opcode = "83 /6 ib", instruction = "XOR r/m16, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "r/m16 XOR imm8 sign-extended" },
  { opcode = "83 /6 ib", instruction = "XOR r/m32, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "r/m32 XOR imm8 sign-extended" },
  { opcode = "REX.W + 83 /6 ib", instruction = "XOR r/m64, imm8", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "r/m64 XOR imm8 sign-extended" },

  { opcode = "30 /r", instruction = "XOR r/m8, r8", op_en = "MR", mode64 = "Valid", compat = "Valid", description = "r/m8 XOR r8" },
  { opcode = "REX + 30 /r", instruction = "XOR r/m8, r8", op_en = "MR", mode64 = "Valid", compat = "N.E.", description = "r/m8 XOR r8; AH/BH/CH/DH unavailable with REX" },
  { opcode = "31 /r", instruction = "XOR r/m16, r16", op_en = "MR", mode64 = "Valid", compat = "Valid", description = "r/m16 XOR r16" },
  { opcode = "31 /r", instruction = "XOR r/m32, r32", op_en = "MR", mode64 = "Valid", compat = "Valid", description = "r/m32 XOR r32" },
  { opcode = "REX.W + 31 /r", instruction = "XOR r/m64, r64", op_en = "MR", mode64 = "Valid", compat = "N.E.", description = "r/m64 XOR r64" },

  { opcode = "32 /r", instruction = "XOR r8, r/m8", op_en = "RM", mode64 = "Valid", compat = "Valid", description = "r8 XOR r/m8" },
  { opcode = "REX + 32 /r", instruction = "XOR r8, r/m8", op_en = "RM", mode64 = "Valid", compat = "N.E.", description = "r8 XOR r/m8; AH/BH/CH/DH unavailable with REX" },
  { opcode = "33 /r", instruction = "XOR r16, r/m16", op_en = "RM", mode64 = "Valid", compat = "Valid", description = "r16 XOR r/m16" },
  { opcode = "33 /r", instruction = "XOR r32, r/m32", op_en = "RM", mode64 = "Valid", compat = "Valid", description = "r32 XOR r/m32" },
  { opcode = "REX.W + 33 /r", instruction = "XOR r64, r/m64", op_en = "RM", mode64 = "Valid", compat = "N.E.", description = "r64 XOR r/m64" }
]

operand_encoding = {
  I  = { operand1 = "AL/AX/EAX/RAX", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" },
  MI = { operand1 = "ModRM:r/m (r,w)", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" },
  MR = { operand1 = "ModRM:r/m (r,w)", operand2 = "ModRM:reg (r)", operand3 = "N/A", operand4 = "N/A" },
  RM = { operand1 = "ModRM:reg (r,w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" }
}

operation = "DEST := DEST XOR SRC"

semantic = """
result = DEST ^ SRC
DEST = truncate_to_operand_size(result)
OF = 0
CF = 0
SF = sign_bit(DEST)
ZF = (DEST == 0)
PF = parity(low8(DEST))
AF = undefined
"""

flags = {
  read = [],
  written = ["OF", "CF", "SF", "ZF", "PF", "AF"],
  cleared = ["OF", "CF"],
  result_dependent = ["SF", "ZF", "PF"],
  undefined = ["AF"]
}

mode_notes = [
  "Two memory operands are not allowed in one XOR instruction.",
  "LOCK prefix is allowed only when destination is a memory operand.",
  "In 64-bit mode, REX.R permits access to R8-R15.",
  "In 64-bit mode, REX.W promotes operation to 64 bits.",
  "With a REX prefix, AH, BH, CH, and DH cannot be encoded as r/m8 byte registers."
]

exceptions = {
  protected_mode = [
    "#GP(0) if destination operand points to a non-writable segment",
    "#GP(0) if a memory operand effective address is outside CS, DS, ES, FS, or GS segment limit",
    "#GP(0) if DS, ES, FS, or GS contains a NULL segment selector",
    "#SS(0) if a memory operand effective address is outside SS segment limit",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL 3",
    "#UD if LOCK prefix is used but destination is not memory"
  ],
  real_address_mode = [
    "#GP if a memory operand effective address is outside CS, DS, ES, FS, or GS segment limit",
    "#SS if a memory operand effective address is outside SS segment limit",
    "#UD if LOCK prefix is used but destination is not memory"
  ],
  virtual_8086_mode = [
    "#GP(0) if a memory operand effective address is outside CS, DS, ES, FS, or GS segment limit",
    "#SS(0) if a memory operand effective address is outside SS segment limit",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made",
    "#UD if LOCK prefix is used but destination is not memory"
  ],
  compatibility_mode = ["same as protected mode"],
  mode64 = [
    "#SS(0) if a memory address referencing SS is non-canonical",
    "#GP(0) if the memory address is non-canonical",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL 3",
    "#UD if LOCK prefix is used but destination is not memory"
  ]
}

translation = {
  arm64_lowering = "EOR plus explicit x86 logic-flag packing",
  atomic_memory_destination = "preserve LOCK read-modify-write semantics",
  zero_idiom_note = "XOR reg, reg may be optimized as zeroing only when x86-visible flags are still produced exactly"
}
