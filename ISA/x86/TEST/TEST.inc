// TEST.inc
// Instruction family: TEST — Logical Compare (Bitwise AND discard result, set flags)

// Canonical table metadata for registry-wide .inc validation.
name = "TEST"

source_isa = "x86"
target_isa = "arm64_neon"
instruction = "TEST"
category = "integer_logical_compare_and_discard"
summary = "Bitwise AND between destination and source, result discarded, SF/ZF/PF set according to result."

encodings = {
  -- AL/AX/EAX/RAX with imm8/16/32
  { opcode = "A8 ib", instruction = "TEST AL, imm8", op_en = "I", mode64 = "Valid", compat = "Valid", description = "AND imm8 with AL; set SF, ZF, PF" },
  { opcode = "A9 iw", instruction = "TEST AX, imm16", op_en = "I", mode64 = "Valid", compat = "Valid", description = "AND imm16 with AX; set SF, ZF, PF" },
  { opcode = "A9 id", instruction = "TEST EAX, imm32", op_en = "I", mode64 = "Valid", compat = "Valid", description = "AND imm32 with EAX; set SF, ZF, PF" },
  { opcode = "REX.W + A9 id", instruction = "TEST RAX, imm32", op_en = "I", mode64 = "Valid", compat = "N.E.", description = "AND imm32 sign-extended to 64-bits with RAX; set SF, ZF, PF" },

  -- r/m8 with imm8
  { opcode = "F6 /0 ib", instruction = "TEST r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "AND imm8 with r/m8; set SF, ZF, PF" },
  { opcode = "REX + F6 /0 ib", instruction = "TEST r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "AND imm8 with r/m8; set SF, ZF, PF; AH/BH/CH/DH unavailable with REX" },

  -- r/m16/32/64 with imm16/imm32
  { opcode = "F7 /0 iw", instruction = "TEST r/m16, imm16", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "AND imm16 with r/m16; set SF, ZF, PF" },
  { opcode = "F7 /0 id", instruction = "TEST r/m32, imm32", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "AND imm32 with r/m32; set SF, ZF, PF" },
  { opcode = "REX.W + F7 /0 id", instruction = "TEST r/m64, imm32", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "AND imm32 sign-extended to 64-bits with r/m64; set SF, ZF, PF" },

  -- r/m8 with r8
  { opcode = "84 /r", instruction = "TEST r/m8, r8", op_en = "MR", mode64 = "Valid", compat = "Valid", description = "AND r8 with r/m8; set SF, ZF, PF" },
  { opcode = "REX + 84 /r", instruction = "TEST r/m8, r8", op_en = "MR", mode64 = "Valid", compat = "N.E.", description = "AND r8 with r/m8; set SF, ZF, PF; AH/BH/CH/DH unavailable with REX" },

  -- r/m16/32/64 with r16/r32/r64
  { opcode = "85 /r", instruction = "TEST r/m16, r16", op_en = "MR", mode64 = "Valid", compat = "Valid", description = "AND r16 with r/m16; set SF, ZF, PF" },
  { opcode = "85 /r", instruction = "TEST r/m32, r32", op_en = "MR", mode64 = "Valid", compat = "Valid", description = "AND r32 with r/m32; set SF, ZF, PF" },
  { opcode = "REX.W + 85 /r", instruction = "TEST r/m64, r64", op_en = "MR", mode64 = "Valid", compat = "N.E.", description = "AND r64 with r/m64; set SF, ZF, PF" }
}

operand_encoding = {
  I  = { operand1 = "AL/AX/EAX/RAX", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" },
  MI = { operand1 = "ModRM:r/m (r)", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" },
  MR = { operand1 = "ModRM:r/m (r)", operand2 = "ModRM:reg (r)", operand3 = "N/A", operand4 = "N/A" }
}

operation = "DEST := DEST AND SRC; result discarded; set SF, ZF, PF"

semantic = """
TEMP = SRC1 AND SRC2
SF = MSB(TEMP)
ZF = (TEMP == 0)
PF = parity(LOW8(TEMP))
CF = 0
OF = 0
AF = undefined
DEST unchanged
"""

flags = {
  read = [],
  written = ["SF", "ZF", "PF", "CF", "OF", "AF"],
  cleared = ["CF", "OF"],
  result_dependent = ["SF", "ZF", "PF"],
  undefined = ["AF"]
}

mode_notes = [
  "Unlike AND/XOR/OR, TEST does not store the result — only sets flags.",
  "In 64-bit mode, REX.R permits access to R8-R15.",
  "In 64-bit mode, REX.W promotes operation to 64 bits.",
  "With a REX prefix, AH, BH, CH, and DH cannot be encoded as r/m8 byte registers.",
  "TEST with same register (e.g., TEST EAX, EAX) is common for zero-check without affecting other flags."
]

exceptions = {
  protected_mode = [
    "#GP(0) if a memory operand effective address is outside CS, DS, ES, FS, or GS segment limit",
    "#GP(0) if DS, ES, FS, or GS contains a NULL segment selector",
    "#SS(0) if a memory operand effective address is outside SS segment limit",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL 3",
    "#UD if LOCK prefix is used (LOCK not allowed with TEST)"
  ],
  real_address_mode = [
    "#GP if a memory operand effective address is outside CS, DS, ES, FS, or GS segment limit",
    "#SS if a memory operand effective address is outside SS segment limit",
    "#UD if LOCK prefix is used"
  ],
  virtual_8086_mode = [
    "#GP(0) if a memory operand effective address is outside CS, DS, ES, FS, or GS segment limit",
    "#SS(0) if a memory operand effective address is outside SS segment limit",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made",
    "#UD if LOCK prefix is used"
  ],
  compatibility_mode = ["same as protected mode"],
  mode64 = [
    "#SS(0) if a memory address referencing SS is non-canonical",
    "#GP(0) if the memory address is non-canonical",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL 3",
    "#UD if LOCK prefix is used"
  ]
}

translation = {
  arm64_lowering = "AND with temporary register + condition flags mapping to NZCV",
  zero_result_note = "TEMP = 0 sets ZF=1, SF=0, PF=1",
  non_destructive_note = "Destination operand not modified (unlike AND/XOR/OR)",
  lock_unsupported = "TEST does not support LOCK prefix"
}