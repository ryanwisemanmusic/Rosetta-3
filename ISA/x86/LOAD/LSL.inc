// LOAD/LSL.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LSL.inc.
// Source document: LOAD Instructions(1).md
// Family section: LSL — Load Segment Limit
// This file preserves the full x86 source contract for LSL, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LSL.inc"
x86_handler = "x86_lsl"
neon_lowering = "descriptor_table_query"
lowering_kind = "descriptor_query_load"

name = "LSL"
family = "LSL"
category = "descriptor_query_load"
operation = "Load Segment Limit"

source_section_title = "LSL — Load Segment Limit"
source_mnemonics_in_section = ["LSL"]

implicit_reads = ["GDT/LDT descriptors", "CPL", "RPL"]
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LSL — Load Segment Limit

Opcode	            Instruction	        Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 03 /r	        LSL r16, r16/m16	RM	    Valid	        Valid	            Load: r16 := segment limit, selector r16/m16.
0F 03 /r	        LSL r32, r32/m161	RM	    Valid	        Valid	            Load: r32 := segment limit, selector r32/m16.
REX.W + 0F 03 /r	LSL r64, r32/m161	RM	    Valid	        Valid	            Load: r64 := segment limit, selector r32/m16

1. For all loads (regardless of destination sizing), only bits 16-0 are used. Other bits are ignored.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A	        N/A

Description:

Loads the unscrambled segment limit from the segment descriptor specified with the second operand (source operand) into the first operand (destination operand) and sets the ZF flag in the EFLAGS register. The source operand (which can be a register or a memory location) contains the segment selector for the segment descriptor being accessed. The destination operand is a general-purpose register.

The processor performs access checks as part of the loading process. Once loaded in the destination register, software can compare the segment limit with the offset of a pointer.

The segment limit is a 20-bit value contained in bytes 0 and 1 and in the first 4 bits of byte 6 of the segment descriptor. If the descriptor has a byte granular segment limit (the granularity flag is set to 0), the destination operand is loaded with a byte granular value (byte limit). If the descriptor has a page granular segment limit (the granularity flag is set to 1), the LSL instruction will translate the page granular limit (page limit) into a byte limit before loading it into the destination operand. The translation is performed by shifting the 20-bit “raw” limit left 12 bits and filling the low-order 12 bits with 1s.

When the operand size is 32 bits, the 32-bit byte limit is stored in the destination operand. When the operand size is 16 bits, a valid 32-bit limit is computed; however, the upper 16 bits are truncated and only the low-order 16 bits are loaded into the destination operand.

This instruction performs the following checks before it loads the segment limit into the destination register:

Checks that the segment selector is not NULL.
Checks that the segment selector points to a descriptor that is within the limits of the GDT or LDT being accessed
Checks that the descriptor type is valid for this instruction. All code and data segment descriptors are valid for (can be accessed with) the LSL instruction. The valid special segment and gate descriptor types are given in the following table.
If the segment is not a conforming code segment, the instruction checks that the specified segment descriptor is visible at the CPL (that is, if the CPL and the RPL of the segment selector are less than or equal to the DPL of the segment selector).
If the segment descriptor cannot be accessed or is an invalid type for the instruction, the ZF flag is cleared and no value is loaded in the destination operand.

Type	Protected Mode (Name)	    Protected Mode (Valid)	IA-32e Mode (Name)	    IA-32e Mode (Valid)
0	    Reserved	                No	                    Reserved	            No
1	    Available 16-bit TSS	    Yes	                    Reserved	            No
2	    LDT	                        Yes	                    LDT1	                Yes
3	    Busy 16-bit TSS	            Yes	                    Reserved	            No
4	    16-bit call gate	        No	                    Reserved	            No
5	    16-bit/32-bit task gate	    No	                    Reserved	            No
6	    16-bit interrupt gate	    No	                    Reserved	            No
7	    16-bit trap gate	        No	                    Reserved	            No
8	    Reserved	                No	                    Reserved	            No
9	    Available 32-bit TSS	    Yes	                    64-bit TSS1	            Yes
A	    Reserved	                No	                    Reserved	            No
B	    Busy 32-bit TSS	            Yes	                    Busy 64-bit TSS1	    Yes
C	    32-bit call gate	        No	                    64-bit call gate	    No
D	    Reserved	                No	                    Reserved	            No
E	    32-bit interrupt gate	    No	                    64-bit interrupt gate	No
F	    32-bit trap gate	        No	                    64-bit trap gate	    No
Table 3-56. Segment and Gate Descriptor Types

1. In this case, the descriptor comprises 16 bytes; bits 12:8 of the upper 4 bytes must be 0.

Operation:

IF SRC(Offset) > descriptor table limit
    THEN ZF := 0; FI;
Read segment descriptor;
IF SegmentDescriptor(Type) ≠ conforming code segment
and (CPL > DPL) OR (RPL > DPL)
or Segment type is not valid for instruction
        THEN
            ZF := 0;
        ELSE
            temp := SegmentLimit([SRC]);
            IF (SegmentDescriptor(G) = 1)
                THEN temp := (temp << 12) OR 00000FFFH;
            ELSE IF OperandSize = 32
                THEN DEST := temp; FI;
            ELSE IF OperandSize = 64 (* REX.W used *)
                THEN DEST := temp(* Zero-extended *); FI;
            ELSE (* OperandSize = 16 *)
                DEST := temp AND FFFFH;
            FI;
FI;

Flags Affected:

The ZF flag is set to 1 if the segment limit is loaded successfully; otherwise, it is set to 0.

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
	The LSL instruction cannot be executed in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The LSL instruction cannot be executed in virtual-8086 mode.

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
Implement LSL according to source_contract.
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
