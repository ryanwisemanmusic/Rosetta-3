// POP/POP.inc
// ARM64/NEON mirror generated from ISA/x86/POP/POP.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
name = "POP"

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "POP/POP.inc"
x86_handler = "x86_pop"
neon_lowering = "LDR post-indexed addressing mode (e.g., LDR X0, [SP], #8)"
lowering_kind = "arm64_documented_contract"

// POP.inc
// Instruction family: POP — Pop a Value From the Stack

instruction = "POP"
category = "stack_pop"
summary = "Loads value from top of stack into destination operand, then increments stack pointer."

encodings = {
  -- r/m16/32/64
  { opcode = "8F /0", instruction = "POP r/m16", op_en = "M", mode64 = "Valid", compat = "Valid", description = "Pop top of stack into m16; increment stack pointer by 2" },
  { opcode = "8F /0", instruction = "POP r/m32", op_en = "M", mode64 = "N.E.", compat = "Valid", description = "Pop top of stack into m32; increment stack pointer by 4" },
  { opcode = "8F /0", instruction = "POP r/m64", op_en = "M", mode64 = "Valid", compat = "N.E.", description = "Pop top of stack into m64; increment stack pointer by 8; cannot encode 32-bit operand size" },

  -- Register pops (58+)
  { opcode = "58+ rw", instruction = "POP r16", op_en = "O", mode64 = "Valid", compat = "Valid", description = "Pop top of stack into r16; increment stack pointer by 2" },
  { opcode = "58+ rd", instruction = "POP r32", op_en = "O", mode64 = "N.E.", compat = "Valid", description = "Pop top of stack into r32; increment stack pointer by 4" },
  { opcode = "58+ rd", instruction = "POP r64", op_en = "O", mode64 = "Valid", compat = "N.E.", description = "Pop top of stack into r64; increment stack pointer by 8; cannot encode 32-bit operand size" },

  -- Segment register pops (non-64-bit)
  { opcode = "07", instruction = "POP ES", op_en = "ZO", mode64 = "Invalid", compat = "Valid", description = "Pop top of stack into ES; increment stack pointer" },
  { opcode = "1F", instruction = "POP DS", op_en = "ZO", mode64 = "Invalid", compat = "Valid", description = "Pop top of stack into DS; increment stack pointer" },
  { opcode = "17", instruction = "POP SS", op_en = "ZO", mode64 = "Invalid", compat = "Valid", description = "Pop top of stack into SS; increment stack pointer" },

  -- FS/GS pops (64-bit capable)
  { opcode = "0F A1", instruction = "POP FS", op_en = "ZO", mode64 = "Valid", compat = "Valid", description = "Pop top of stack into FS; increment stack pointer by 16 bits" },
  { opcode = "0F A1", instruction = "POP FS", op_en = "ZO", mode64 = "N.E.", compat = "Valid", description = "Pop top of stack into FS; increment stack pointer by 32 bits" },
  { opcode = "0F A1", instruction = "POP FS", op_en = "ZO", mode64 = "Valid", compat = "N.E.", description = "Pop top of stack into FS; increment stack pointer by 64 bits" },
  { opcode = "0F A9", instruction = "POP GS", op_en = "ZO", mode64 = "Valid", compat = "Valid", description = "Pop top of stack into GS; increment stack pointer by 16 bits" },
  { opcode = "0F A9", instruction = "POP GS", op_en = "ZO", mode64 = "N.E.", compat = "Valid", description = "Pop top of stack into GS; increment stack pointer by 32 bits" },
  { opcode = "0F A9", instruction = "POP GS", op_en = "ZO", mode64 = "Valid", compat = "N.E.", description = "Pop top of stack into GS; increment stack pointer by 64 bits" }
}

operand_encoding = {
  M  = { operand1 = "ModRM:r/m (w)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  O  = { operand1 = "opcode + rd (w)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  ZO = { operand1 = "N/A", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
}

operation = "DEST := [SS:SP/RSP/ESP]; SP/RSP/ESP += operand_size_bytes"

semantic = """
IF StackAddrSize == 32:
    IF OperandSize == 32:
        DEST := SS:ESP
        ESP := ESP + 4
    ELSE:  -- OperandSize == 16
        DEST := SS:ESP
        ESP := ESP + 2
ELIF StackAddrSize == 64:
    IF OperandSize == 64:
        DEST := SS:RSP
        RSP := RSP + 8
    ELSE:  -- OperandSize == 16
        DEST := SS:RSP
        RSP := RSP + 2
ELSE:  -- StackAddrSize == 16
    IF OperandSize == 16:
        DEST := SS:SP
        SP := SP + 2
    ELSE:  -- OperandSize == 32
        DEST := SS:SP
        SP := SP + 4

-- Segment register validation in protected mode (abbreviated)
IF loading segment register (non-NULL selector):
    validate segment descriptor, privilege levels, and present bit
"""

flags_affected = "None"

mode_notes = [
  "POP ESP increments SP before writing to destination",
  "POP SS suppresses debug exceptions and inhibits interrupts for one instruction boundary",
  "Cannot pop into CS register (use RET for that)",
  "NULL segment selector (0000-0003) can be popped into DS/ES/FS/GS without #GP",
  "In 64-bit mode, POP to DS/ES/SS is invalid",
  "In 64-bit mode, 32-bit operand size POP is not encodable",
  "Use LSS instruction to load SS and ESP together (Intel recommendation)"
]

exceptions = {
  protected_mode = [
    "#GP(0) if loading SS with NULL selector",
    "#GP(0) if destination operand in non-writable segment",
    "#GP(0) if memory operand effective address outside segment limit",
    "#GP(0) if DS/ES/FS/GS contains NULL selector when accessing memory",
    "#GP(selector) if segment selector index outside descriptor table limits",
    "#GP(selector) if loading SS with RPL or DPL != CPL",
    "#GP(selector) if loading SS with non-writable data segment",
    "#GP(selector) if loading DS/ES/FS/GS with non-data or non-readable code segment",
    "#GP(selector) if loading DS/ES/FS/GS and both RPL and CPL > DPL",
    "#SS(0) if current top of stack not within stack segment",
    "#SS(0) if memory operand effective address outside SS segment limit",
    "#SS(selector) if loading SS and segment not present",
    "#NP if loading DS/ES/FS/GS and segment not present",
    "#PF(fault-code) if page fault occurs",
    "#AC(0) if unaligned memory reference at CPL 3 with alignment checking enabled",
    "#UD if LOCK prefix is used"
  ],
  real_address_mode = [
    "#GP if memory operand effective address outside CS/DS/ES/FS/GS segment limit",
    "#UD if LOCK prefix is used"
  ],
  virtual_8086_mode = [
    "#GP(0) if memory operand effective address outside segment limit",
    "#PF(fault-code) if page fault occurs",
    "#AC(0) if unaligned memory reference with alignment checking enabled",
    "#UD if LOCK prefix is used"
  ],
  compatibility_mode = ["same as protected mode"],
  mode64 = [
    "#GP(0) if memory address in non-canonical form",
    "#SS(0) if stack address in non-canonical form",
    "#GP(selector) if descriptor outside descriptor table limit",
    "#GP(selector) if loading FS/GS with non-data or non-readable code segment",
    "#GP(selector) if loading FS/GS and both RPL and CPL > DPL",
    "#AC(0) if unaligned memory reference with alignment checking enabled at CPL 3",
    "#PF(fault-code) if page fault occurs",
    "#NP if loading FS/GS and segment not present",
    "#UD if LOCK prefix is used",
    "#UD if loading DS, ES, or SS register"
  ]
}

translation = {
  arm64_lowering = "LDR post-indexed addressing mode (e.g., LDR X0, [SP], #8)",
  stack_pointer_increment = "SP moves forward by operand size (2, 4, or 8 bytes)",
  no_flags = "POP affects no EFLAGS bits"
}

neon_register_model = """
The x86 architectural operands, implicit state, and memory effects are read from the Rosette register file and emulated system state. ARM64 lowering must preserve the documented source contract before using native scalar or NEON instructions.
"""

neon_flag_model = """
The ARM64 lowering preserves the x86 flag behavior listed in flags_read, flags_written, flags_affected, flags_model, or source_contract. NZCV may be used internally only when repacked into x86 architectural flags.
"""

neon_assembly = """
// POP: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
