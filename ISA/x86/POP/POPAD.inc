// POPAD.inc
// Instruction: POPAD — Pop All General-Purpose Registers (32-bit)

source_isa = "x86"
target_isa = "arm64_neon"
instruction = "POPAD"
category = "stack_pop_all"
summary = "Pops doubleword values from stack into EDI, ESI, EBP, EBX, EDX, ECX, EAX (32-bit operand size)."

encodings = {
  { opcode = "61", instruction = "POPAD", op_en = "ZO", mode64 = "Invalid", compat = "Valid", description = "Pop EDI, ESI, EBP, EBX, EDX, ECX, EAX" }
}

operand_encoding = {
  ZO = { operand1 = "N/A", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
}

operation = """
EDI := Pop()
ESI := Pop()
EBP := Pop()
ESP := ESP + 4   -- Skip the value that would have gone into ESP
EBX := Pop()
EDX := Pop()
ECX := Pop()
EAX := Pop()
"""

semantic = """
IF 64-Bit Mode:
    #UD
ELSE:
    EDI := [SS:ESP]; ESP := ESP + 4
    ESI := [SS:ESP]; ESP := ESP + 4
    EBP := [SS:ESP]; ESP := ESP + 4
    ESP := ESP + 4    -- Skip ESP value
    EBX := [SS:ESP]; ESP := ESP + 4
    EDX := [SS:ESP]; ESP := ESP + 4
    ECX := [SS:ESP]; ESP := ESP + 4
    EAX := [SS:ESP]; ESP := ESP + 4
"""

flags_affected = "None"

mode_notes = [
  "POPAD is for 32-bit operand size only",
  "The value for ESP on the stack is skipped (not loaded)",
  "POPAD reverses the operation of PUSHAD",
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
  arm64_lowering = "Multiple LDR post-indexed instructions with SP skip",
  not_in_64bit = "Not supported in AArch64 (no direct analog)",
  skip_sp = "ESP value on stack is discarded, not loaded"
}