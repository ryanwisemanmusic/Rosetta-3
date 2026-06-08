// TEST/TESTUI.inc
// ARM64/NEON mirror generated from ISA/x86/TEST/TESTUI.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
name = "TESTUI"

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "TEST/TESTUI.inc"
x86_handler = "x86_testui"
neon_lowering = "MRS to read PSTATE interrupt-related flag + insert into NZCV.C"
lowering_kind = "arm64_documented_contract"

// TESTUI.inc
// Instruction family: TESTUI — Determine User Interrupt Flag (UIF)

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

neon_register_model = """
The x86 architectural operands, implicit state, and memory effects are read from the Rosette register file and emulated system state. ARM64 lowering must preserve the documented source contract before using native scalar or NEON instructions.
"""

neon_flag_model = """
The ARM64 lowering preserves the x86 flag behavior listed in flags_read, flags_written, flags_affected, flags_model, or source_contract. NZCV may be used internally only when repacked into x86 architectural flags.
"""

neon_assembly = """
// TESTUI: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
