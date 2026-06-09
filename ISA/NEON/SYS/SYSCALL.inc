// SYS/SYSCALL.inc
// ARM64/NEON mirror generated from ISA/x86/SYS/SYSCALL.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "SYS/SYSCALL.inc"
x86_handler = "x86_syscall"
neon_lowering = "arm64_smc_syscall"
lowering_kind = "arm64_documented_contract"

// SYS/SYSCALL.inc
// ARM64/NEON translation mirror generated from ISA/x86/SYS/SYSCALL.inc.
// Source contract: SYSCALL — Fast System Call.

name = "SYSCALL"
category = "system_call"
feature = "system"
element_type = "system"

encodings = [
  { opcode = "0F 05", form = "SYSCALL", op_en = "ZO", mode64 = "valid", mode_compat = "invalid" }
]

operand_encoding = {
  ZO = []
}

reads = ["IA32_LSTAR", "IA32_STAR", "IA32_FMASK", "RIP", "RFLAGS"]
writes = ["RCX", "RIP", "R11", "RFLAGS", "CS", "SS"]
flags_read = []
flags_written = ["ALL"]
implicit_operands = ["RCX", "R11", "IA32_LSTAR", "IA32_STAR", "IA32_FMASK"]

semantic = """
RCX = RIP;
RIP = IA32_LSTAR;
R11 = RFLAGS;
RFLAGS = RFLAGS & ~(IA32_FMASK);
CS.Selector = (IA32_STAR[47:32] & 0xFFFC);
SS.Selector = (IA32_STAR[47:32] + 8);
"""

exceptions = {
  protected_mode = ["#UD — SYSCALL is not recognized in protected mode"],
  real_address_mode = ["#UD"],
  virtual_8086_mode = ["#UD"],
  compatibility_mode = ["#UD"],
  mode64 = ["#UD if IA32_EFER.SCE = 0", "#UD if LOCK prefix is used"]
}

handler = "x86_syscall"
jit_lowering = "arm64_smc_syscall"

neon_register_model = """
SYSCALL transitions to privilege level 0, saving RIP to RCX and RFLAGS to R11, then loading CS/SS from IA32_STAR and RIP from IA32_LSTAR. ARM64 SVC or SMC hypercall lowering is stubbed as a documented contract.
"""

neon_flag_model = """
All RFLAGS are overwritten according to IA32_FMASK masking.
"""

neon_assembly = """
svc #0
"""

neon_notes = [
  "SYSCALL is only valid in 64-bit mode with IA32_EFER.SCE=1.",
  "ARM64 lowering uses SVC (supervisor call) with documented contract for OS integration."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
