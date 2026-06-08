// LOAD/LTR.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LTR.inc.
// Source document: LOAD Instructions(1).md
// Family section: LTR — Load Task Register
// This file preserves the full x86 source contract for LTR, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
encodings = [
  { opcode = "see preserved_source_contract", form = "LTR documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_ltr" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LTR.inc"
x86_handler = "x86_ltr"
neon_lowering = "privileged_system_state_write"
lowering_kind = "system_descriptor_table_load"

name = "LTR"
family = "LTR"
category = "system_descriptor_table_load"
operation = "Load Task Register"

source_section_title = "LTR — Load Task Register"
source_mnemonics_in_section = ["LTR"]

implicit_reads = ["CPL", "descriptor tables/system state"]
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LTR — Load Task Register

Opcode	    Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 00 /3	LTR r/m16	    M	    Valid	    Valid	                Load r/m16 into task register.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	Operand 3	Operand 4
M	    ModRM:r/m (r)	N/A	        N/A	        N/A

Description:

Loads the source operand into the segment selector field of the task register. The source operand (a general-purpose register or a memory location) contains a segment selector that points to a task state segment (TSS). After the segment selector is loaded in the task register, the processor uses the segment selector to locate the segment descriptor for the TSS in the global descriptor table (GDT). It then loads the segment limit and base address for the TSS from the segment descriptor into the task register. The task pointed to by the task register is marked busy, but a switch to the task does not occur.

The LTR instruction is provided for use in operating-system software; it should not be used in application programs. It can only be executed in protected mode when the CPL is 0. It is commonly used in initialization code to establish the first task to be executed.

The operand-size attribute has no effect on this instruction.

In 64-bit mode, the operand size is still fixed at 16 bits. The instruction references a 16-byte descriptor to load the 64-bit base.

Operation:

IF SRC is a NULL selector
    THEN #GP(0);
IF SRC(Offset) > descriptor table limit OR IF SRC(type) ≠ global
    THEN #GP(segment selector); FI;
Read segment descriptor;
IF segment descriptor is not for an available TSS
    THEN #GP(segment selector); FI;
IF segment descriptor is not present
    THEN #NP(segment selector); FI;
TSSsegmentDescriptor(busy) := 1;
(* Locked read-modify-write operation on the entire descriptor when setting busy flag *)
TaskRegister(SegmentSelector) := SRC;
TaskRegister(SegmentDescriptor) := TSSSegmentDescriptor;

Flags Affected:

None.

Protected Mode Exceptions:

#GP(0):
	If the current privilege level is not 0.
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the source operand contains a NULL segment selector.
    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.
#GP(selector):
	If the source selector points to a segment that is not a TSS or to one for a task that is already busy.
    If the selector points to LDT or is beyond the GDT limit.
#NP(selector):
	If the TSS descriptor is marked not present.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
    #PF(fault-code)	If a page fault occurs.
    #UD	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#UD:	
    The LTR instruction is not recognized in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The LTR instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode, as well as the following:

#GP(selector):
	If the source selector points to a 16-bit TSS.

64-Bit Mode Exceptions:

#SS(0):
	If a memory address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the current privilege level is not 0.
    If the memory address is in a non-canonical form.
    If the source operand contains a NULL segment selector.
#GP(selector):
	If the source selector points to a segment that is not a TSS, to a 16-bit TSS, or to a TSS for a task that is already busy.
    If the selector points to LDT or is beyond the GDT limit.
    If the descriptor type of the upper 8-byte of the 16-byte descriptor is non-zero.
#NP(selector):
	If the TSS descriptor is marked not present.
#PF(fault-code):
	If a page fault occurs.
#UD:
	If the LOCK prefix is used.
"""

semantic = """
Implement LTR according to source_contract.
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
