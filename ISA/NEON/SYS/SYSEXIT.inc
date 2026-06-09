// SYS/SYSEXIT.inc
// ARM64/NEON mirror generated from ISA/x86/SYS/SYSEXIT.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SYS/SYSEXIT.inc"
x86_handler = "x86_sysexit"
neon_lowering = "arm64_smc_sysexit"
lowering_kind = "arm64_documented_contract"

// SYS/SYSEXIT.inc
// ARM64/NEON translation mirror generated from ISA/x86/SYS/SYSEXIT.inc.
// Source contract: SYSEXIT — Fast Return from Fast System Call.

name = "SYSEXIT"
category = "system_call"
feature = "system"
element_type = "system"

encodings = [
  { opcode = "0F 35", form = "SYSEXIT", op_en = "ZO", mode64 = "valid", mode_compat = "valid", operand_size = "32" },
  { opcode = "REX.W + 0F 35", form = "SYSEXIT", op_en = "ZO", mode64 = "valid", mode_compat = "valid", operand_size = "64" }
]

operand_encoding = {
  ZO = []
}

reads = ["IA32_SYSENTER_CS", "RCX", "RDX", "RSP", "RIP"]
writes = ["RSP", "RIP", "CS", "SS", "CPL"]
implicit_operands = ["RDX", "RCX", "IA32_SYSENTER_CS"]

semantic = """
IF IA32_SYSENTER_CS[15:2] == 0 OR CR0.PE == 0 OR CPL != 0 THEN #GP(0);
IF operand_size == 64:
    RSP = RCX;
    RIP = RDX;
    CS.Selector = IA32_SYSENTER_CS[15:0] + 32;
ELSE:
    RSP = ECX;
    RIP = EDX;
    CS.Selector = IA32_SYSENTER_CS[15:0] + 16;
CS.Selector = CS.Selector | 3;
SS.Selector = CS.Selector + 8;
CPL = 3;
"""

exceptions = {
  protected_mode = ["#GP(0) if IA32_SYSENTER_CS[15:2] = 0 or CPL != 0", "#UD if LOCK prefix is used"],
  real_address_mode = ["#GP", "#UD if LOCK prefix is used"],
  virtual_8086_mode = ["#GP(0)"],
  compatibility_mode = ["same_as_protected_mode"],
  mode64 = ["#GP(0) if IA32_SYSENTER_CS = 0 or CPL != 0 or non-canonical address", "#UD if LOCK prefix is used"]
}

handler = "x86_sysexit"
jit_lowering = "arm64_smc_sysexit"

neon_register_model = """
SYSEXIT loads RSP from RCX and RIP from RDX, setting CPL back to 3. ARM64 lowering is a documented contract stub.
"""

neon_flag_model = """
No flags are affected by SYSEXIT.
"""

neon_assembly = """
svc #0
"""

neon_notes = [
  "SYSEXIT must be executed at CPL=0.",
  "ARM64 lowering uses SVC (supervisor call) with documented contract for OS integration."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
