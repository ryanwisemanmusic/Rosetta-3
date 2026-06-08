// LOAD/LAHF.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LAHF.inc.
// Source document: LOAD Instructions(1).md
// Family section: LAHF — Load Status Flags Into AH Register
// This file preserves the full x86 source contract for LAHF, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LAHF.inc"
x86_handler = "x86_lahf"
neon_lowering = "flags_pack_to_AH"
lowering_kind = "flags_load"

name = "LAHF"
family = "LAHF"
category = "flags_load"
operation = "Load Status Flags Into AH Register"

source_section_title = "LAHF — Load Status Flags Into AH Register"
source_mnemonics_in_section = ["LAHF"]

implicit_reads = ["RFLAGS/EFLAGS"]
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LAHF — Load Status Flags Into AH Register

Opcode	En	Mode	Leg Mode	Description
9F					            Load: AH := EFLAGS(SF:ZF:0:AF:0:PF:1:CF).

1. Valid in specific steppings; see Description section.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

This instruction executes as described above in compatibility mode and legacy mode. It is valid in 64-bit mode only if CPUID.80000001H:ECX.LAHF-SAHF[bit 0] = 1.

Operation:

IF 64-Bit Mode
    THEN
        IF CPUID.80000001H:ECX.LAHF-SAHF[bit 0] = 1;
            THEN AH := RFLAGS(SF:ZF:0:AF:0:PF:1:CF);
            ELSE #UD;
        FI;
    ELSE
        AH := EFLAGS(SF:ZF:0:AF:0:PF:1:CF);
FI;

Flags Affected:

None. The state of the flags in the EFLAGS register is not affected.

Protected Mode Exceptions:

#UD	If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as in protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as in protected mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#UD:
	If CPUID.80000001H:ECX.LAHF-SAHF[bit 0] = 0.
    If the LOCK prefix is used.
"""

semantic = """
Implement LAHF according to source_contract.
Decode opcode, prefixes, ModRM, operand size, address size, CPUID feature gates, privilege gates, and mode restrictions exactly as described.
Perform architectural reads/writes exactly as the Intel-style operation section specifies.
Do not collapse this instruction into a generic load if source_contract requires descriptor validation, segment-register hidden-cache updates, MXCSR validation, AMX tile configuration, Key Locker state, string-index update, or fence ordering.
"""

arm64_lowering_contract = """
Rosette/Rosetta lowering must mirror the x86 architectural side effects, not merely emit a native load.
Where host ARM64 lacks the x86 architectural facility, route through the emulator/system-state model and raise the matching x86 exception.
For memory operands, run the x86 effective-address, segment, canonicality, alignment, paging, and access checks before host memory access.
For vector/string forms, preserve width, zeroing/unmodified upper-lane behavior, implicit operands, and DF-controlled index update.
For privileged/system forms, require CPL/feature checks before mutating emulated descriptor or control state.
"""

neon_notes = [
  "The complete source section is embedded above so no LOAD-related behavior from the Markdown is dropped.",
  "If this instruction is unsupported by the current Rosette runtime, the decoder should still recognize it and raise the documented x86 exception or unsupported-instruction path.",
  "Runtime ABI validation checks the x86 source table shape, mode restrictions, exception list, implicit operands, and ARM64 lowering shape."
]

abi_contract = ["x86_table_shape", "source_contract_preserved", "arm64_lowering_shape", "full_scope_preserved"]
