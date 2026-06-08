// LOAD/LLDT.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/LLDT.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
encodings = [
  { opcode = "see preserved_source_contract", form = "LLDT documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_lldt" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LLDT.inc"
x86_handler = "x86_lldt"
neon_lowering = "privileged_system_state_write"
lowering_kind = "arm64_documented_contract"

// LOAD/LLDT.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LLDT.inc.
// Source document: LOAD Instructions(1).md
// Family section: LLDT — Load Local Descriptor Table Register
// This file preserves the full x86 source contract for LLDT, then appends the ARM64/NEON lowering contract.


name = "LLDT"
family = "LLDT"
category = "system_descriptor_table_load"
operation = "Load Local Descriptor Table Register"

source_section_title = "LLDT — Load Local Descriptor Table Register"
source_mnemonics_in_section = ["LLDT"]

implicit_reads = ["CPL", "descriptor tables/system state"]
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LLDT — Load Local Descriptor Table Register

Opcode	    Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 00 /2	LLDT r/m16	    M	    Valid	        Valid	            Load segment selector r/m16 into LDTR.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	Operand 3	Operand 4
M	    ModRM:r/m (r)	N/A         N/A	        N/A

Description:

Loads the source operand into the segment selector field of the local descriptor table register (LDTR). The source operand (a general-purpose register or a memory location) contains a segment selector that points to a local descriptor table (LDT). After the segment selector is loaded in the LDTR, the processor uses the segment selector to locate the segment descriptor for the LDT in the global descriptor table (GDT). It then loads the segment limit and base address for the LDT from the segment descriptor into the LDTR. The segment registers DS, ES, SS, FS, GS, and CS are not affected by this instruction, nor is the LDTR field in the task state segment (TSS) for the current task.

If bits 2-15 of the source operand are 0, LDTR is marked invalid and the LLDT instruction completes silently. However, all subsequent references to descriptors in the LDT (except by the LAR, VERR, VERW or LSL instructions) cause a general protection exception (#GP).

The operand-size attribute has no effect on this instruction.

The LLDT instruction is provided for use in operating-system software; it should not be used in application programs. This instruction can only be executed in protected mode or 64-bit mode.

In 64-bit mode, the operand size is fixed at 16 bits.

Operation:

IF SRC(Offset) > descriptor table limit
    THEN #GP(segment selector); FI;
IF segment selector is valid
    Read segment descriptor;
    IF SegmentDescriptor(Type) ≠ LDT
        THEN #GP(segment selector); FI;
    IF segment descriptor is not present
        THEN #NP(segment selector); FI;
    LDTR(SegmentSelector) := SRC;
    LDTR(SegmentDescriptor) := GDTSegmentDescriptor;
ELSE LDTR := INVALID
FI;

Flags Affected:

None.

Protected Mode Exceptions:

#GP(0):
	If the current privilege level is not 0.
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the DS, ES, FS, or GS register contains a NULL segment selector.
#GP(selector):
	If the selector operand does not point into the Global Descriptor Table or if the entry in the GDT is not a Local Descriptor Table.
    Segment selector is beyond GDT limit.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#NP(selector):
	If the LDT descriptor is not present.
#PF(fault-code):
	If a page fault occurs.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#UD:
	The LLDT instruction is not recognized in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The LLDT instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#SS(0):
	If a memory address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the current privilege level is not 0.
    If the memory address is in a non-canonical form.
#GP(selector):
	If the selector operand does not point into the Global Descriptor Table or if the entry in the GDT is not a Local Descriptor Table.
    Segment selector is beyond GDT limit.
#NP(selector):
	If the LDT descriptor is not present.
#PF(fault-code):
	If a page fault occurs.
#UD:
	If the LOCK prefix is used.
"""

semantic = """
Implement LLDT according to source_contract.
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

neon_register_model = """
The x86 architectural operands, implicit state, and memory effects are read from the Rosette register file and emulated system state. ARM64 lowering must preserve the documented source contract before using native scalar or NEON instructions.
"""

neon_flag_model = """
The ARM64 lowering preserves the x86 flag behavior listed in flags_read, flags_written, flags_affected, flags_model, or source_contract. NZCV may be used internally only when repacked into x86 architectural flags.
"""

neon_assembly = """
// LLDT: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""
