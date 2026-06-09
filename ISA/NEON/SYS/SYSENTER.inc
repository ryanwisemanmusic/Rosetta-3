// SYS/SYSENTER.inc
// ARM64/NEON mirror generated from ISA/x86/SYS/SYSENTER.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SYS/SYSENTER.inc"
x86_handler = "x86_sysenter"
neon_lowering = "arm64_smc_sysenter"
lowering_kind = "arm64_documented_contract"

// SYS/SYSENTER.inc
// ARM64/NEON translation mirror generated from ISA/x86/SYS/SYSENTER.inc.
// Source contract: SYSENTER — Fast System Call (legacy).

name = "SYSENTER"
category = "system_call"
feature = "system"
element_type = "system"

encodings = [
  { opcode = "0F 34", form = "SYSENTER", op_en = "ZO", mode64 = "valid", mode_compat = "valid" }
]

operand_encoding = {
  ZO = []
}

reads = ["IA32_SYSENTER_CS", "IA32_SYSENTER_EIP", "IA32_SYSENTER_ESP", "RFLAGS"]
writes = ["RSP", "RIP", "RFLAGS", "CS", "SS"]
implicit_operands = ["IA32_SYSENTER_CS", "IA32_SYSENTER_EIP", "IA32_SYSENTER_ESP"]

semantic = """
IF CR0.PE == 0 OR IA32_SYSENTER_CS[15:2] == 0 THEN #GP(0);
RFLAGS.VM = 0;
RFLAGS.IF = 0;
RSP = IA32_SYSENTER_ESP;
RIP = IA32_SYSENTER_EIP;
CS.Selector = IA32_SYSENTER_CS[15:0] & 0xFFFC;
SS.Selector = CS.Selector + 8;
"""

exceptions = {
  protected_mode = ["#GP(0) if IA32_SYSENTER_CS[15:2] = 0", "#UD if LOCK prefix is used"],
  real_address_mode = ["#GP", "#UD if LOCK prefix is used"],
  virtual_8086_mode = ["same_as_protected_mode"],
  compatibility_mode = ["same_as_protected_mode"],
  mode64 = ["same_as_protected_mode"]
}

handler = "x86_sysenter"
jit_lowering = "arm64_smc_sysenter"

neon_register_model = """
SYSENTER loads RIP and RSP from MSRs and sets CS/SS selectors. ARM64 lowering is a documented contract stub.
"""

neon_flag_model = """
VM and IF flags are cleared.
"""

neon_assembly = """
svc #0
"""

neon_notes = [
  "SYSENTER is valid in protected mode and 64-bit mode.",
  "ARM64 lowering uses SVC (supervisor call) with documented contract for OS integration."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
