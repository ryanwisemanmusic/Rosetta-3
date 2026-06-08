// POPCNT.inc
// Instruction family: POPCNT — Return the Count of Number of Bits Set to 1

source_isa = "x86"
target_isa = "arm64_neon"
instruction = "POPCNT"
category = "bit_population_count"
summary = "Counts number of bits set to 1 in source operand, stores count in destination."

encodings = {
  { opcode = "F3 0F B8 /r", instruction = "POPCNT r16, r/m16", op_en = "RM", mode64 = "Valid", compat = "Valid", description = "POPCNT on r/m16" },
  { opcode = "F3 0F B8 /r", instruction = "POPCNT r32, r/m32", op_en = "RM", mode64 = "Valid", compat = "Valid", description = "POPCNT on r/m32" },
  { opcode = "F3 REX.W 0F B8 /r", instruction = "POPCNT r64, r/m64", op_en = "RM", mode64 = "Valid", compat = "N.E.", description = "POPCNT on r/m64" }
}

operand_encoding = {
  RM = { operand1 = "ModRM:reg (w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" }
}

operation = "DEST := count of 1-bits in SRC"

semantic = """
Count = 0
FOR i = 0 TO OperandSize - 1:
    IF SRC[i] == 1:
        Count = Count + 1
DEST = Count
"""

flags = {
  read = [],
  written = ["ZF", "OF", "SF", "AF", "CF", "PF"],
  cleared = ["OF", "SF", "AF", "CF", "PF"],
  result_dependent = ["ZF = (SRC == 0)"]
}

mode_notes = [
  "Available only when CPUID.01H:ECX.POPCNT[bit 23] = 1",
  "All flags except ZF are cleared to 0",
  "ZF is set if SRC == 0, otherwise ZF is cleared",
  "SSE4.2 instruction"
]

exceptions = {
  protected_mode = [
    "#GP(0) if memory operand effective address outside CS/DS/ES/FS/GS segments",
    "#SS(0) if memory operand effective address outside SS segment limit",
    "#PF(fault-code) for page fault",
    "#AC(0) if unaligned memory reference at CPL 3 with alignment checking enabled",
    "#UD if CPUID.POPCNT bit = 0",
    "#UD if LOCK prefix is used"
  ],
  real_address_mode = [
    "#GP(0) if operand lies outside 0-0xFFFF address space",
    "#SS(0) if memory operand effective address outside SS segment limit",
    "#UD if CPUID.POPCNT bit = 0",
    "#UD if LOCK prefix is used"
  ],
  virtual_8086_mode = [
    "#GP(0) if operand lies outside 0-0xFFFF address space",
    "#SS(0) if memory operand effective address outside SS segment limit",
    "#PF(fault-code) for page fault",
    "#AC(0) if unaligned memory reference with alignment checking enabled",
    "#UD if CPUID.POPCNT bit = 0",
    "#UD if LOCK prefix is used"
  ],
  compatibility_mode = ["same as protected mode"],
  mode64 = [
    "#GP(0) if memory address in non-canonical form",
    "#SS(0) if memory address referencing SS in non-canonical form",
    "#PF(fault-code) for page fault",
    "#AC(0) if alignment checking enabled and unaligned memory reference at CPL 3",
    "#UD if CPUID.POPCNT bit = 0",
    "#UD if LOCK prefix is used"
  ]
}

intrinsics = {
  cpp = ["int _mm_popcnt_u32(unsigned int a)", "int64_t _mm_popcnt_u64(unsigned __int64 a)"]
}

translation = {
  arm64_lowering = "CNT (population count per byte) + ADDV for reduction",
  sve_lowering = "CNTP + UADDV for predicate population count",
  flags_clear = "All flags except ZF cleared to 0"
}