// SYS/SYSRET.inc
// ARM64/NEON translation mirror generated from ISA/x86/SYS/SYSRET.inc.
// Source contract: SYSRET — Return From Fast System Call.

name = "SYSRET"
category = "system_call"
feature = "system"
element_type = "system"

encodings = [
  { opcode = "0F 07", form = "SYSRET", op_en = "ZO", mode64 = "valid", mode_compat = "invalid", operand_size = "32" },
  { opcode = "REX.W + 0F 07", form = "SYSRET", op_en = "ZO", mode64 = "valid", mode_compat = "invalid", operand_size = "64" }
]

operand_encoding = {
  ZO = []
}

reads = ["IA32_STAR", "RCX", "R11", "RFLAGS"]
writes = ["RIP", "RFLAGS", "CS", "SS", "CPL"]
implicit_operands = ["RCX", "R11", "IA32_STAR"]

semantic = """
IF CS.L != 1 OR IA32_EFER.LMA != 1 OR IA32_EFER.SCE != 1 THEN #UD;
IF CPL != 0 THEN #GP(0);
IF operand_size == 64:
    IF RCX is non-canonical THEN #GP(0);
    RIP = RCX;
ELSE:
    RIP = ECX;
RFLAGS = (R11 & 0x3C7FD7) | 2;
IF operand_size == 64:
    CS.Selector = (IA32_STAR[63:48] + 16) | 3;
ELSE:
    CS.Selector = (IA32_STAR[63:48]) | 3;
SS.Selector = (IA32_STAR[63:48] + 8) | 3;
CPL = 3;
"""

exceptions = {
  protected_mode = ["#UD — SYSRET is not recognized in protected mode"],
  real_address_mode = ["#UD"],
  virtual_8086_mode = ["#UD"],
  compatibility_mode = ["#UD"],
  mode64 = ["#UD if IA32_EFER.SCE = 0 or LOCK prefix is used", "#GP(0) if CPL != 0 or non-canonical RCX"]
}

handler = "x86_sysret"
jit_lowering = "arm64_smc_sysret"

neon_register_model = """
SYSRET loads RIP from RCX and RFLAGS from R11, setting CPL to 3. ARM64 lowering is a documented contract stub.
"""

neon_flag_model = """
All RFLAGS are restored from R11 (with RF, VM cleared and bit 1 set).
"""

neon_assembly = """
svc #0
"""

neon_notes = [
  "SYSRET is only valid in 64-bit mode with IA32_EFER.SCE=1.",
  "ARM64 lowering uses SVC (supervisor call) with documented contract for OS integration."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
