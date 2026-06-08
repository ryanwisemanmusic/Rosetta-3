// LOAD/LAR.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LAR.inc.
// Source document: LOAD Instructions(1).md
// Family section: LAR — Load Access Rights Byte
// This file preserves the full x86 source contract for LAR, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LAR.inc"
x86_handler = "x86_lar"
neon_lowering = "descriptor_table_query"
lowering_kind = "descriptor_query_load"

name = "LAR"
family = "LAR"
category = "descriptor_query_load"
operation = "Load Access Rights Byte"

source_section_title = "LAR — Load Access Rights Byte"
source_mnemonics_in_section = ["LAR"]

implicit_reads = ["GDT/LDT descriptors", "CPL", "RPL"]
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LAR — Load Access Rights Byte

Opcode	    Instruction	        Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 02 /r	LAR r16, r16/m16	RM	    Valid	        Valid	            r16 := access rights referenced by r16/m16
0F 02 /r	LAR reg, r32/m161	RM	    Valid	        Valid	            reg := access rights referenced by r32/m16

1. For all loads (regardless of source or destination sizing) only bits 16-0 are used. Other bits are ignored.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A	        N/A

Description:

Loads the access rights from the segment descriptor specified by the second operand (source operand) into the first operand (destination operand) and sets the ZF flag in the flag register. The source operand (which can be a register or a memory location) contains the segment selector for the segment descriptor being accessed. If the source operand is a memory address, only 16 bits of data are accessed. The destination operand is a general-purpose register.

The processor performs access checks as part of the loading process. Once loaded in the destination register, software can perform additional checks on the access rights information.

The access rights for a segment descriptor include fields located in the second doubleword (bytes 4–7) of the segment descriptor. The following fields are loaded by the LAR instruction:

Bits 7:0 are returned as 0
Bits 11:8 return the segment type.
Bit 12 returns the S flag.
Bits 14:13 return the DPL.
Bit 15 returns the P flag.
The following fields are returned only if the operand size is greater than 16 bits:
Bits 19:16 are undefined.
Bits 19:16 are undefined.
Bit 20 returns the software-available bit in the descriptor.
Bit 20 returns the software-available bit in the descriptor.
Bit 21 returns the L flag.
Bit 21 returns the L flag.
Bit 22 returns the D/B flag.
Bit 22 returns the D/B flag.
Bit 23 returns the G flag.
Bit 23 returns the G flag.
Bits 31:24 are returned as 0.
Bits 31:24 are returned as 0.
This instruction performs the following checks before it loads the access rights in the destination register:

Checks that the segment selector is not NULL.
Checks that the segment selector points to a descriptor that is within the limits of the GDT or LDT being accessed
Checks that the descriptor type is valid for this instruction. All code and data segment descriptors are valid for (can be accessed with) the LAR instruction. The valid system segment and gate descriptor types are given in Table 3-53.
If the segment is not a conforming code segment, it checks that the specified segment descriptor is visible at the CPL (that is, if the CPL and the RPL of the segment selector are less than or equal to the DPL of the segment selector).
If the segment descriptor cannot be accessed or is an invalid type for the instruction, the ZF flag is cleared and no access rights are loaded in the destination operand.

The LAR instruction can only be executed in protected mode and IA-32e mode.

Type	Protected Mode (Name)	Protected Mode (Valid)	IA-32e Mode (Name)	    IA-32e Mode (Valid)
0	    Reserved	            No	                    Reserved	            No
1	    Available 16-bit TSS	Yes	                    Reserved	            No
2	    LDT	                    Yes	                    LDT	                    Yes
3	    Busy 16-bit TSS	        Yes	                    Reserved	            No
4	    16-bit call gate	    Yes	                    Reserved	            No
5	    16-bit/32-bit task gate	Yes	                    Reserved	            No
6	    16-bit interrupt gate	No	                    Reserved	            No
7	    16-bit trap gate	    No	                    Reserved	            No
8	    Reserved	            No	                    Reserved	            No
9	    Available 32-bit TSS	Yes	                    Available 64-bit TSS	Yes
A	    Reserved	            No	                    Reserved	            No
B	    Busy 32-bit TSS	        Yes	                    Busy 64-bit TSS	        Yes
C	    32-bit call gate	    No	                    64-bit call gate	    Yes
D	    Reserved	            No	                    Reserved	            No
E	    32-bit interrupt gate	No	                    64-bit interrupt gate	No
F	    32-bit trap gate	    No	                    64-bit trap gate	    No
Table 3-53. Segment and Gate Types

Operation:

IF Offset(SRC) > descriptor table limit
    THEN
        ZF := 0;
    ELSE
        SegmentDescriptor := descriptor referenced by SRC;
        IF SegmentDescriptor(Type) ≠ conforming code segment
        and (CPL > DPL) or (RPL > DPL)
        or SegmentDescriptor(Type) is not valid for instruction
            THEN
                ZF := 0;
            ELSE
                DEST := access rights from SegmentDescriptor as given in Description section;
                ZF := 1;
        FI;
FI;

Flags Affected:

The ZF flag is set to 1 if the access rights are loaded successfully; otherwise, it is cleared to 0.

Protected Mode Exceptions:

#GP(0):
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and the memory operand effective address is unaligned while the current privilege level is 3.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#UD:
	The LAR instruction is not recognized in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The LAR instruction cannot be executed in virtual-8086 mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#SS(0):
	If the memory operand effective address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the memory operand effective address is in a non-canonical form.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and the memory operand effective address is unaligned while the current privilege level is 3.
#UD:
	If the LOCK prefix is used.
"""

semantic = """
Implement LAR according to source_contract.
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
