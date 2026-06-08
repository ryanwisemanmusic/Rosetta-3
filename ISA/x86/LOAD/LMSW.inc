// LOAD/LMSW.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LMSW.inc.
// Source document: LOAD Instructions(1).md
// Family section: LMSW — Load Machine Status Word
// This file preserves the full x86 source contract for LMSW, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LMSW.inc"
x86_handler = "x86_lmsw"
neon_lowering = "privileged_system_state_write"
lowering_kind = "system_machine_status_load"

name = "LMSW"
family = "LMSW"
category = "system_machine_status_load"
operation = "Load Machine Status Word"

source_section_title = "LMSW — Load Machine Status Word"
source_mnemonics_in_section = ["LMSW"]

implicit_reads = ["CPL", "descriptor tables/system state"]
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LMSW — Load Machine Status Word

Opcode	    Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 01 /6	LMSW r/m16	    M	    Valid	        Valid	            Loads r/m16 in machine status word of CR0.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	Operand 3	Operand 4
M	    ModRM:r/m (r)	N/A	        N/A	        N/A

Description:

Loads the source operand into the machine status word, bits 0 through 15 of register CR0. The source operand can be a 16-bit general-purpose register or a memory location. Only the low-order 4 bits of the source operand (which contains the PE, MP, EM, and TS flags) are loaded into CR0. The PG, CD, NW, AM, WP, NE, and ET flags of CR0 are not affected. The operand-size attribute has no effect on this instruction.

If the PE flag of the source operand (bit 0) is set to 1, the instruction causes the processor to switch to protected mode. While in protected mode, the LMSW instruction cannot be used to clear the PE flag and force a switch back to real-address mode.

The LMSW instruction is provided for use in operating-system software; it should not be used in application programs. In protected or virtual-8086 mode, it can only be executed at CPL 0.

This instruction is provided for compatibility with the Intel 286 processor; programs and procedures intended to run on IA-32 and Intel 64 processors beginning with Intel386 processors should use the MOV (control registers) instruction to load the whole CR0 register. The MOV CR0 instruction can be used to set and clear the PE flag in CR0, allowing a procedure or program to switch between protected and real-address modes.

This instruction is a serializing instruction.

This instruction’s operation is the same in non-64-bit modes and 64-bit mode. Note that the operand size is fixed at 16 bits.

See “Changes to Instruction Behavior in VMX Non-Root Operation” in Chapter 26 of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 3C, for more information about the behavior of this instruction in VMX non-root operation.

Operation:

CR0[0:3] := SRC[0:3];

Flags Affected:

None.

Protected Mode Exceptions:

#GP(0):
	If the current privilege level is not 0.
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
	If a page fault occurs.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#GP:
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#UD:
	If the LOCK prefix is used.

Virtual-8086 Mode Exceptions:

#GP(0):
	The LMSW instruction is not recognized in virtual-8086 mode.
#UD:
	If the LOCK prefix is used.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#SS(0):
	If a memory address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the current privilege level is not 0.
If the memory address is in a non-canonical form.

#PF(fault-code):
	If a page fault occurs.
#UD:
	If the LOCK prefix is used.
"""

semantic = """
Implement LMSW according to source_contract.
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
