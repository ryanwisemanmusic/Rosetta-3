// RCR.inc
// Instruction family: RCR — Rotate Through Carry Right

source_isa = "x86"
target_isa = "arm64_neon"
instruction = "RCR"
category = "integer_rotate_through_carry_right"
summary = "Rotate CF and destination operand right by specified count; CF participates in rotation."

encodings = {
  -- 8-bit
  { opcode = "D0 /3", instruction = "RCR r/m8, 1", op_en = "M1", mode64 = "Valid", compat = "Valid", description = "Rotate 9 bits (CF, r/m8) right once" },
  { opcode = "REX + D0 /3", instruction = "RCR r/m8, 1", op_en = "M1", mode64 = "Valid", compat = "N.E.", description = "Rotate 9 bits (CF, r/m8) right once" },
  { opcode = "D2 /3", instruction = "RCR r/m8, CL", op_en = "MC", mode64 = "Valid", compat = "Valid", description = "Rotate 9 bits (CF, r/m8) right CL times" },
  { opcode = "REX + D2 /3", instruction = "RCR r/m8, CL", op_en = "MC", mode64 = "Valid", compat = "N.E.", description = "Rotate 9 bits (CF, r/m8) right CL times" },
  { opcode = "C0 /3 ib", instruction = "RCR r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "Rotate 9 bits (CF, r/m8) right imm8 times" },
  { opcode = "REX + C0 /3 ib", instruction = "RCR r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "Rotate 9 bits (CF, r/m8) right imm8 times" },

  -- 16-bit
  { opcode = "D1 /3", instruction = "RCR r/m16, 1", op_en = "M1", mode64 = "Valid", compat = "Valid", description = "Rotate 17 bits (CF, r/m16) right once" },
  { opcode = "D3 /3", instruction = "RCR r/m16, CL", op_en = "MC", mode64 = "Valid", compat = "Valid", description = "Rotate 17 bits (CF, r/m16) right CL times" },
  { opcode = "C1 /3 ib", instruction = "RCR r/m16, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "Rotate 17 bits (CF, r/m16) right imm8 times" },

  -- 32-bit
  { opcode = "D1 /3", instruction = "RCR r/m32, 1", op_en = "M1", mode64 = "Valid", compat = "Valid", description = "Rotate 33 bits (CF, r/m32) right once" },
  { opcode = "D3 /3", instruction = "RCR r/m32, CL", op_en = "MC", mode64 = "Valid", compat = "Valid", description = "Rotate 33 bits (CF, r/m32) right CL times" },
  { opcode = "C1 /3 ib", instruction = "RCR r/m32, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "Rotate 33 bits (CF, r/m32) right imm8 times" },

  -- 64-bit (REX.W)
  { opcode = "REX.W + D1 /3", instruction = "RCR r/m64, 1", op_en = "M1", mode64 = "Valid", compat = "N.E.", description = "Rotate 65 bits (CF, r/m64) right once; uses 6-bit count" },
  { opcode = "REX.W + D3 /3", instruction = "RCR r/m64, CL", op_en = "MC", mode64 = "Valid", compat = "N.E.", description = "Rotate 65 bits (CF, r/m64) right CL times; uses 6-bit count" },
  { opcode = "REX.W + C1 /3 ib", instruction = "RCR r/m64, imm8", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "Rotate 65 bits (CF, r/m64) right imm8 times; uses 6-bit count" }
}

operand_encoding = {
  M1 = { operand1 = "ModRM:r/m (w)", operand2 = "1", operand3 = "N/A", operand4 = "N/A" },
  MC = { operand1 = "ModRM:r/m (w)", operand2 = "CL", operand3 = "N/A", operand4 = "N/A" },
  MI = { operand1 = "ModRM:r/m (w)", operand2 = "imm8", operand3 = "N/A", operand4 = "N/A" }
}

operation = "SIZE-bit rotation (CF + DEST) right by COUNT times"

semantic_rcr = """
SIZE = operand size in bits (8, 16, 32, or 64)
IF SIZE == 8:
    COUNTMASK = 0x1F
    tempCOUNT = (COUNT & 0x1F) % 9
ELIF SIZE == 16:
    COUNTMASK = 0x1F
    tempCOUNT = (COUNT & 0x1F) % 17
ELIF SIZE == 32:
    COUNTMASK = 0x1F
    tempCOUNT = COUNT & 0x1F
ELIF SIZE == 64:
    COUNTMASK = 0x3F
    tempCOUNT = COUNT & 0x3F

WHILE tempCOUNT != 0:
    tempCF = LSB(DEST)
    DEST = (DEST >> 1) + (CF << (SIZE - 1))
    CF = tempCF
    tempCOUNT = tempCOUNT - 1

IF (COUNT & COUNTMASK) == 1:
    OF = MSB(DEST) XOR CF
ELSE:
    OF = undefined
"""

flags = {
  read = ["CF"],
  written = ["CF", "OF"],
  affected_by_count = ["CF", "OF"],
  undefined = ["OF when masked_count != 1"],
  unaffected = ["SF", "ZF", "AF", "PF"]
}

mode_notes = [
  "For 8-bit rotates: count masked to 5 bits, then modulo 9",
  "For 16-bit rotates: count masked to 5 bits, then modulo 17",
  "For 32-bit rotates: count masked to 5 bits (masked count 0-31)",
  "For 64-bit rotates (REX.W): count masked to 6 bits (masked count 0-63)",
  "Zero-bit rotate (masked_count = 0) affects no flags",
  "In 64-bit mode, r/m8 cannot encode AH/BH/CH/DH when REX prefix is used",
  "RCR includes CF flag as part of the rotation (9/17/33/65 bits total)"
]

exceptions = {
  protected_mode = [
    "#GP(0) if destination is in a non-writable segment",
    "#GP(0) if memory operand effective address is outside CS/DS/ES/FS/GS segment limit",
    "#GP(0) if DS/ES/FS/GS contains NULL segment selector",
    "#SS(0) if memory operand effective address is outside SS segment limit",
    "#PF(fault-code) if page fault occurs",
    "#AC(0) if alignment checking enabled and unaligned memory reference at CPL 3",
    "#UD if LOCK prefix is used"
  ],
  real_address_mode = [
    "#GP if memory operand effective address is outside CS/DS/ES/FS/GS segment limit",
    "#SS if memory operand effective address is outside SS segment limit",
    "#UD if LOCK prefix is used"
  ],
  virtual_8086_mode = [
    "#GP(0) if memory operand effective address is outside CS/DS/ES/FS/GS segment limit",
    "#SS(0) if memory operand effective address is outside SS segment limit",
    "#PF(fault-code) if page fault occurs",
    "#AC(0) if alignment checking enabled and unaligned memory reference",
    "#UD if LOCK prefix is used"
  ],
  compatibility_mode = ["same as protected mode"],
  mode64 = [
    "#SS(0) if memory address referencing SS is non-canonical",
    "#GP(0) if destination is in a non-writable segment",
    "#GP(0) if memory address is non-canonical",
    "#PF(fault-code) if page fault occurs",
    "#AC(0) if alignment checking enabled and unaligned memory reference at CPL 3",
    "#UD if LOCK prefix is used"
  ]
}

translation = {
  arm64_lowering = "ROR + CSEL or loop for RCR; note ARM has no direct RCR equivalent",
  carry_rotation = "CF participates as the 9th/17th/33rd/65th bit",
  zero_rotate_optimization = "Masked count of 0 = no operation, no flags affected"
}