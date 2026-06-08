// POP/POPA.inc
// ARM64/NEON mirror generated from ISA/x86/POP/POPA.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
name = "POPA"

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "POP/POPA.inc"
x86_handler = "x86_popa"
neon_lowering = "Multiple LDRH post-indexed instructions with SP skip"
lowering_kind = "arm64_documented_contract"

// POPA.inc
// Instruction: POPA — Pop All General-Purpose Registers (16-bit)

instruction = "POPA"
category = "stack_pop_all"
summary = "Pops word values from stack into DI, SI, BP, BX, DX, CX, AX (16-bit operand size)."

encodings = {
  { opcode = "61", instruction = "POPA", op_en = "ZO", mode64 = "Invalid", compat = "Valid", description = "Pop DI, SI, BP, BX, DX, CX, AX" }
}

operand_encoding = {
  ZO = { operand1 = "N/A", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
}

operation = """
DI := Pop()
SI := Pop()
BP := Pop()
SP := SP + 2   -- Skip the value that would have gone into SP
BX := Pop()
DX := Pop()
CX := Pop()
AX := Pop()
"""

semantic = """
IF 64-Bit Mode:
    #UD
ELSE:
    DI := [SS:SP]; SP := SP + 2
    SI := [SS:SP]; SP := SP + 2
    BP := [SS:SP]; SP := SP + 2
    SP := SP + 2    -- Skip SP value
    BX := [SS:SP]; SP := SP + 2
    DX := [SS:SP]; SP := SP + 2
    CX := [SS:SP]; SP := SP + 2
    AX := [SS:SP]; SP := SP + 2
"""

flags_affected = "None"

mode_notes = [
  "POPA is for 16-bit operand size only",
  "The value for SP on the stack is skipped (not loaded)",
  "POPA reverses the operation of PUSHA",
  "Not valid in 64-bit mode (#UD)"
]

exceptions = {
  protected_mode = [
    "#SS(0) if starting or ending stack address not within stack segment",
    "#PF(fault-code) if page fault occurs",
    "#AC(0) if unaligned memory reference at CPL 3 with alignment checking enabled",
    "#UD if LOCK prefix is used"
  ],
  real_address_mode = [
    "#SS if starting or ending stack address not within stack segment",
    "#UD if LOCK prefix is used"
  ],
  virtual_8086_mode = [
    "#SS(0) if starting or ending stack address not within stack segment",
    "#PF(fault-code) if page fault occurs",
    "#AC(0) if unaligned memory reference with alignment checking enabled",
    "#UD if LOCK prefix is used"
  ],
  compatibility_mode = ["same as protected mode"],
  mode64 = ["#UD: not valid in 64-bit mode"]
}

translation = {
  arm64_lowering = "Multiple LDRH post-indexed instructions with SP skip",
  not_in_64bit = "Not supported in AArch64 (no direct analog)",
  skip_sp = "SP value on stack is discarded, not loaded"
}

neon_register_model = """
The x86 architectural operands, implicit state, and memory effects are read from the Rosette register file and emulated system state. ARM64 lowering must preserve the documented source contract before using native scalar or NEON instructions.
"""

neon_flag_model = """
The ARM64 lowering preserves the x86 flag behavior listed in flags_read, flags_written, flags_affected, flags_model, or source_contract. NZCV may be used internally only when repacked into x86 architectural flags.
"""

neon_assembly = """
// POPA: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
