// ROL.inc
// Instruction family: ROL — Rotate Left (without carry)

source_isa = "x86"
target_isa = "arm64_neon"
instruction = "ROL"
category = "integer_rotate_left"
summary = "Rotate destination operand left by specified count; CF receives bit shifted from MSB to LSB."

encodings = {
  -- 8-bit
  { opcode = "D0 /0", instruction = "ROL r/m8, 1", op_en = "M1", mode64 = "Valid", compat = "Valid", description = "Rotate 8 bits r/m8 left once" },
  { opcode = "REX + D0 /0", instruction = "ROL r/m8, 1", op_en = "M1", mode64 = "Valid", compat = "N.E.", description = "Rotate 8 bits r/m8 left once" },
  { opcode = "D2 /0", instruction = "ROL r/m8, CL", op_en = "MC", mode64 = "Valid", compat = "Valid", description = "Rotate 8 bits r/m8 left CL times" },
  { opcode = "REX + D2 /0", instruction = "ROL r/m8, CL", op_en = "MC", mode64 = "Valid", compat = "N.E.", description = "Rotate 8 bits r/m8 left CL times" },
  { opcode = "C0 /0 ib", instruction = "ROL r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "Rotate 8 bits r/m8 left imm8 times" },
  { opcode = "REX + C0 /0 ib", instruction = "ROL r/m8, imm8", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "Rotate 8 bits r/m8 left imm8 times" },

  -- 16-bit
  { opcode = "D1 /0", instruction = "ROL r/m16, 1", op_en = "M1", mode64 = "Valid", compat = "Valid", description = "Rotate 16 bits r/m16 left once" },
  { opcode = "D3 /0", instruction = "ROL r/m16, CL", op_en = "MC", mode64 = "Valid", compat = "Valid", description = "Rotate 16 bits r/m16 left CL times" },
  { opcode = "C1 /0 ib", instruction = "ROL r/m16, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "Rotate 16 bits r/m16 left imm8 times" },

  -- 32-bit
  { opcode = "D1 /0", instruction = "ROL r/m32, 1", op_en = "M1", mode64 = "Valid", compat = "Valid", description = "Rotate 32 bits r/m32 left once" },
  { opcode = "D3 /0", instruction = "ROL r/m32, CL", op_en = "MC", mode64 = "Valid", compat = "Valid", description = "Rotate 32 bits r/m32 left CL times" },
  { opcode = "C1 /0 ib", instruction = "ROL r/m32, imm8", op_en = "MI", mode64 = "Valid", compat = "Valid", description = "Rotate 32 bits r/m32 left imm8 times" },

  -- 64-bit (REX.W)
  { opcode = "REX.W + D1 /0", instruction = "ROL r/m64, 1", op_en = "M1", mode64 = "Valid", compat = "N.E.", description = "Rotate 64 bits r/m64 left once; uses 6-bit count" },
  { opcode = "REX.W + D3 /0", instruction = "ROL r/m64, CL", op_en = "MC", mode64 = "Valid", compat = "N.E.", description = "Rotate 64 bits r/m64 left CL times; uses 6-bit count" },
  { opcode = "REX.W + C1 /0 ib", instruction = "ROL r/m64, imm8", op_en = "MI", mode64 = "Valid", compat = "N.E.", description = "Rotate 64 bits r/m64 left imm8 times; uses 6-bit count" }
}

operand_encoding = {
  M1 = { operand1 = "ModRM:r/m (w)", operand2 = "1", operand3 = "N/A", operand4 = "N/A" },
  MC = { operand1 = "ModRM:r/m (w)", operand2 = "CL", operand3 = "N/A", operand4 = "N/A" },
  MI = { operand1 = "ModRM:r/m (w)", operand2 = "imm8", operand3 = "N/A", operand4 = "N/A" }
}

operation = "SIZE-bit rotation left by COUNT times; CF = LSB(DEST) after rotation"

semantic_rol = """
SIZE = operand size in bits (8, 16, 32, or 64)
IF SIZE == 8:
    COUNTMASK = 0x1F
    tempCOUNT = (COUNT & 0x1F) % 8
ELIF SIZE == 16:
    COUNTMASK = 0x1F
    tempCOUNT = (COUNT & 0x1F) % 16
ELIF SIZE == 32:
    COUNTMASK = 0x1F
    tempCOUNT = COUNT & 0x1F
ELIF SIZE == 64:
    COUNTMASK = 0x3F
    tempCOUNT = COUNT & 0x3F

IF tempCOUNT == 0:
    flags unaffected
    return

WHILE tempCOUNT != 0:
    tempCF = MSB(DEST)
    DEST = (DEST << 1) + tempCF
    tempCOUNT = tempCOUNT - 1

CF = LSB(DEST)

IF (COUNT & COUNTMASK) == 1:
    OF = MSB(DEST) XOR CF
ELSE:
    OF = undefined
"""

flags = {
  read = [],
  written = ["CF", "OF"],
  affected_by_count = ["CF", "OF"],
  undefined = ["OF when masked_count != 1"],
  unaffected = ["SF", "ZF", "AF", "PF"],
  condition = "If masked count is 0, no flags are affected"
}

mode_notes = [
  "For 8-bit rotates: count masked to 5 bits, then modulo 8",
  "For 16-bit rotates: count masked to 5 bits, then modulo 16",
  "For 32-bit rotates: count masked to 5 bits (masked count 0-31)",
  "For 64-bit rotates (REX.W): count masked to 6 bits (masked count 0-63)",
  "Zero-bit rotate (masked_count = 0) affects no flags",
  "CF receives the LSB of the result after rotation",
  "OF is set only for 1-bit rotates (masked_count == 1)",
  "In 64-bit mode, r/m8 cannot encode AH/BH/CH/DH when REX prefix is used"
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
  arm64_lowering = "ROR (rotate right) with (SIZE - count) for ROL, or CSEL/loop",
  cf_derivation = "CF = LSB(DEST) after rotation",
  zero_rotate_optimization = "Masked count of 0 = no operation, no flags affected"
}