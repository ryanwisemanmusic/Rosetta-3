// LOAD/LGS.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LGS.inc.
// Source document: LOAD Instructions(1).md
// Family section: LDS/LES/LFS/LGS/LSS — Load Far Pointer
// This file preserves the full x86 source contract for LGS, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
encodings = [
  { opcode = "see preserved_source_contract", form = "LGS documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_lgs" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LGS.inc"
x86_handler = "x86_lgs"
neon_lowering = "far_pointer_load_and_segment_state_update"
lowering_kind = "far_pointer_segment_load"

name = "LGS"
family = "LDS/LES/LFS/LGS/LSS"
category = "far_pointer_segment_load"
operation = "Load Far Pointer; LGS loads its opcode-selected segment/register pair and offset from a far pointer memory operand"

source_section_title = "LDS/LES/LFS/LGS/LSS — Load Far Pointer"
source_mnemonics_in_section = ["LDS", "LES", "LFS", "LGS", "LSS"]

implicit_reads = ["segment descriptor tables when protected/IA-32e mode"]
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LDS/LES/LFS/LGS/LSS — Load Far Pointer

Opcode	        Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
C5 /r	        LDS r16,m16:16	RM	    Invalid	        Valid	            Load DS:r16 with far pointer from memory.
C5 /r	        LDS r32,m16:32	RM	    Invalid	        Valid	            Load DS:r32 with far pointer from memory.
0F B2 /r	    LSS r16,m16:16	RM	    Valid	        Valid	            Load SS:r16 with far pointer from memory.
0F B2 /r	    LSS r32,m16:32	RM	    Valid	        Valid	            Load SS:r32 with far pointer from memory.
REX + 0F B2 /r	LSS r64,m16:64	RM	    Valid	        N.E.	            Load SS:r64 with far pointer from memory.
C4 /r	        LES r16,m16:16	RM	    Invalid	        Valid	            Load ES:r16 with far pointer from memory.
C4 /r	        LES r32,m16:32	RM	    Invalid	        Valid	            Load ES:r32 with far pointer from memory.
0F B4 /r	    LFS r16,m16:16	RM	    Valid	        Valid	            Load FS:r16 with far pointer from memory.
0F B4 /r	    LFS r32,m16:32	RM	    Valid	        Valid	            Load FS:r32 with far pointer from memory.
REX + 0F B4 /r	LFS r64,m16:64	RM	    Valid	        N.E.	            Load FS:r64 with far pointer from memory.
0F B5 /r	    LGS r16,m16:16	RM	    Valid	        Valid	            Load GS:r16 with far pointer from memory.
0F B5 /r	    LGS r32,m16:32	RM	    Valid	        Valid	            Load GS:r32 with far pointer from memory.
REX + 0F B5 /r	LGS r64,m16:64	RM	    Valid	        N.E.	            Load GS:r64 with far pointer from memory.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A	        N/A

Description:

Loads a far pointer (segment selector and offset) from the second operand (source operand) into a segment register and the first operand (destination operand). The source operand specifies a 48-bit or a 32-bit pointer in memory depending on the current setting of the operand-size attribute (32 bits or 16 bits, respectively). The instruction opcode and the destination operand specify a segment register/general-purpose register pair. The 16-bit segment selector from the source operand is loaded into the segment register specified with the opcode (DS, SS, ES, FS, or GS). The 32-bit or 16-bit offset is loaded into the register specified with the destination operand.

If one of these instructions is executed in protected mode, additional information from the segment descriptor pointed to by the segment selector in the source operand is loaded in the hidden part of the selected segment register.

Also in protected mode, a NULL selector (values 0000 through 0003) can be loaded into DS, ES, FS, or GS registers without causing a protection exception. (Any subsequent reference to a segment whose corresponding segment register is loaded with a NULL selector, causes a general-protection exception (#GP) and no memory reference to the segment occurs.)

In 64-bit mode, the instruction’s default operation size is 32 bits. Using a REX prefix in the form of REX.W promotes operation to specify a source operand referencing an 80-bit pointer (16-bit selector, 64-bit offset) in memory. Using a REX prefix in the form of REX.R permits access to additional registers (R8-R15). See the summary chart at the beginning of this section for encoding data and limits.

Operation:

64-BIT_MODE
    IF SS is loaded
        THEN
            IF SegmentSelector = NULL and ( (RPL = 3) or
                    (RPL ≠ 3 and RPL ≠ CPL) )
                THEN #GP(0);
            ELSE IF descriptor is in non-canonical space
                THEN #GP(selector); FI;
            ELSE IF Segment selector index is not within descriptor table limits
                    or segment selector RPL ≠ CPL
                    or access rights indicate nonwritable data segment
                    or DPL ≠ CPL
                THEN #GP(selector); FI;
            ELSE IF Segment marked not present
                THEN #SS(selector); FI;
            FI;
            SS := SegmentSelector(SRC);
            SS := SegmentDescriptor([SRC]);
    ELSE IF attempt to load DS, or ES
        THEN #UD;
    ELSE IF FS, or GS is loaded with non-NULL segment selector
        THEN IF Segment selector index is not within descriptor table limits
            or access rights indicate segment neither data nor readable code segment
            or segment is data or nonconforming-code segment
            and ( RPL > DPL or CPL > DPL)
                THEN #GP(selector); FI;
            ELSE IF Segment marked not present
                THEN #NP(selector); FI;
            FI;
            SegmentRegister := SegmentSelector(SRC) ;
            SegmentRegister := SegmentDescriptor([SRC]);
        FI;
    ELSE IF FS, or GS is loaded with a NULL selector:
        THEN
            SegmentRegister := NULLSelector;
            SegmentRegister(DescriptorValidBit) := 0; FI; (* Hidden flag;
                not accessible by software *)
    FI;
    DEST := Offset(SRC);
PREOTECTED MODE OR COMPATIBILITY MODE;
    IF SS is loaded
        THEN
            IF SegementSelector = NULL
                THEN #GP(0);
            ELSE IF Segment selector index is not within descriptor table limits
                    or segment selector RPL ≠ CPL
                    or access rights indicate nonwritable data segment
                    or DPL ≠ CPL
                THEN #GP(selector); FI;
            ELSE IF Segment marked not present
                THEN #SS(selector); FI;
            FI;
            SS := SegmentSelector(SRC);
            SS := SegmentDescriptor([SRC]);
    ELSE IF DS, ES, FS, or GS is loaded with non-NULL segment selector
        THEN IF Segment selector index is not within descriptor table limits
            or access rights indicate segment neither data nor readable code segment
            or segment is data or nonconforming-code segment
            and (RPL > DPL or CPL > DPL)
                THEN #GP(selector); FI;
            ELSE IF Segment marked not present
                THEN #NP(selector); FI;
            FI;
            SegmentRegister := SegmentSelector(SRC) AND RPL;
            SegmentRegister := SegmentDescriptor([SRC]);
        FI;
    ELSE IF DS, ES, FS, or GS is loaded with a NULL selector:
        THEN
            SegmentRegister := NULLSelector;
            SegmentRegister(DescriptorValidBit) := 0; FI; (* Hidden flag;
                not accessible by software *)
    FI;
    DEST := Offset(SRC);
Real-Address or Virtual-8086 Mode
    SegmentRegister := SegmentSelector(SRC); FI;
    DEST := Offset(SRC);

Flags Affected:

None.

Protected Mode Exceptions:

#UD:
	If source operand is not a memory location.
    If the LOCK prefix is used.
#GP(0):
	If a NULL selector is loaded into the SS register.
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.
#GP(selector):
	If the SS register is being loaded and any of the following is true: the segment selector index is not within the descriptor table limits, the segment selector RPL is not equal to CPL, the segment is a non-writable data segment, or DPL is not equal to CPL.
    If the DS, ES, FS, or GS register is being loaded with a non-NULL segment selector and any of the following is true: the segment selector index is not within descriptor table limits, the segment is neither a data nor a readable code segment, or the segment is a data or nonconforming-code segment and both RPL and CPL are greater than DPL.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#SS(selector):
	If the SS register is being loaded and the segment is marked not present.
#NP(selector):
	If DS, ES, FS, or GS register is being loaded with a non-NULL segment selector and the segment is marked not present.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while the current privilege level is 3.

Real-Address Mode Exceptions:

#GP:
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS:
	If a memory operand effective address is outside the SS segment limit.
#UD:
	If source operand is not a memory location.
    If the LOCK prefix is used.

Virtual-8086 Mode Exceptions:

#UD:
	If source operand is not a memory location.
    If the LOCK prefix is used.
#GP(0):
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
    If a page fault occurs.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#GP(0):
	If the memory address is in a non-canonical form.
    If a NULL selector is attempted to be loaded into the SS register in compatibility mode.
    If a NULL selector is attempted to be loaded into the SS register in CPL3 and 64-bit mode.
    If a NULL selector is attempted to be loaded into the SS register in non-CPL3 and 64-bit mode where its RPL is not equal to CPL.
#GP(Selector):
	If the FS, or GS register is being loaded with a non-NULL segment selector and any of the following is true: the segment selector index is not within descriptor table limits, the memory address of the descriptor is non-canonical, the segment is neither a data nor a readable code segment, or the segment is a data or nonconforming-code segment and both RPL and CPL are greater than DPL.
    If the SS register is being loaded and any of the following is true: the segment selector index is not within the descriptor table limits, the memory address of the descriptor is non-canonical, the segment selector RPL is not equal to CPL, the segment is a nonwritable data segment, or DPL is not equal to CPL.
#SS(0):
	If a memory operand effective address is non-canonical
#SS(Selector):
	If the SS register is being loaded and the segment is marked not present.
#NP(selector):
	If FS, or GS register is being loaded with a non-NULL segment selector and the segment is marked not present.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while the current privilege level is 3.
#UD:
	If source operand is not a memory location.
    If the LOCK prefix is used.
"""

semantic = """
Implement LGS according to source_contract.
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
