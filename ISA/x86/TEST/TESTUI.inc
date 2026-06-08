// TESTUI.inc
// Instruction family: TESTUI — Determine User Interrupt Flag (UIF)

source_isa = "x86"
target_isa = "arm64_neon"  -- but TESTUI is system/control, not SIMD.
instruction = "TESTUI"
category = "system_user_interrupt"
summary = "Copies current value of User Interrupt Flag (UIF) into EFLAGS.CF."

encodings = {
  { opcode = "F3 0F 01 ED", instruction = "TESTUI", op_en = "ZO", mode64 = "V/I", compat = "V/I", feature = "UINTR", description = "Copies UIF into CF; all other flags cleared" }
}

operand_encoding = {
  ZO = { operand1 = "N/A", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
}

operation = "CF := UIF; all other flags cleared"

semantic = """
CF = UIF
ZF = 0
AF = 0
OF = 0
PF = 0
SF = 0
"""

flags = {
  read = ["UIF (internal, not EFLAGS)"],
  written = ["CF", "ZF", "AF", "OF", "PF", "SF"],
  cleared = ["ZF", "AF", "OF", "PF", "SF"],
  result_dependent = ["CF = UIF"]
}

mode_notes = [
  "TESTUI can be executed at any CPL (unlike some privileged instructions).",
  "TESTUI may be executed normally inside a transactional region.",
  "Only available when CPUID.UINTR bit 5 is set and CR4.UINTR = 1.",
  "Not recognized in Real-Address, Virtual-8086, or Compatibility modes."
]

availability = {
  cpuid_requirement = "CPUID.07H.0H:EDX.UINTR[bit 5] = 1",
  cr4_requirement = "CR4.UINTR = 1",
  enclave_requirement = "Not permitted inside an enclave"
}

exceptions = {
  protected_mode = ["#UD: TESTUI instruction not recognized in protected mode"],
  real_address_mode = ["#UD: TESTUI instruction not recognized in real-address mode"],
  virtual_8086_mode = ["#UD: TESTUI instruction not recognized in virtual-8086 mode"],
  compatibility_mode = ["#UD: TESTUI instruction not recognized in compatibility mode"],
  mode64 = [
    "#UD if LOCK prefix is used",
    "#UD if executed inside an enclave",
    "#UD if CR4.UINTR = 0",
    "#UD if CPUID.07H.0H:EDX.UINTR[bit 5] = 0"
  ]
}

translation = {
  arm64_lowering = "MRS to read PSTATE interrupt-related flag + insert into NZCV.C",
  system_instruction_note = "Privilege-agnostic but enclave-restricted",
  flag_mapping = "UIF → CF, all other condition flags cleared"
}