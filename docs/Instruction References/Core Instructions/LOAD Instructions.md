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






LDDQU — Load Unaligned Integer 128 Bits

Opcode/Instruction	                        Op/En	64/32-bit Mode	    CPUID Feature Flag	    Description
F2 0F F0 /r LDDQU xmm1, mem	                RM	    V/V	                SSE3	                Load unaligned data from mem and return double quadword in xmm1.
VEX.128.F2.0F.WIG F0 /r VLDDQU xmm1, m128	RM	    V/V	                AVX	                    Load unaligned packed integer values from mem to xmm1.
VEX.256.F2.0F.WIG F0 /r VLDDQU ymm1, m256	RM	    V/V	                AVX	                    Load unaligned packed integer values from mem to ymm1.
Instruction Operand Encoding ¶

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A	        N/A

Description:

The instruction is functionally similar to (V)MOVDQU ymm/xmm, m256/m128 for loading from memory. That is: 32/16 bytes of data starting at an address specified by the source memory operand (second operand) are fetched from memory and placed in a destination register (first operand). The source operand need not be aligned on a 32/16-byte boundary. Up to 64/32 bytes may be loaded from memory; this is implementation dependent.

This instruction may improve performance relative to (V)MOVDQU if the source operand crosses a cache line boundary. In situations that require the data loaded by (V)LDDQU be modified and stored to the same location, use (V)MOVDQU or (V)MOVDQA instead of (V)LDDQU. To move a double quadword to or from memory locations that are known to be aligned on 16-byte boundaries, use the (V)MOVDQA instruction.

Implementation Notes:

If the source is aligned to a 32/16-byte boundary, based on the implementation, the 32/16 bytes may be loaded more than once. For that reason, the usage of (V)LDDQU should be avoided when using uncached or write-combining (WC) memory regions. For uncached or WC memory regions, keep using (V)MOVDQU.
This instruction is a replacement for (V)MOVDQU (load) in situations where cache line splits significantly affect performance. It should not be used in situations where store-load forwarding is performance critical. If performance of store-load forwarding is critical to the application, use (V)MOVDQA store-load pairs when data is 256/128-bit aligned or (V)MOVDQU store-load pairs when data is 256/128-bit unaligned.
If the memory address is not aligned on 32/16-byte boundary, some implementations may load up to 64/32 bytes and return 32/16 bytes in the destination. Some processor implementations may issue multiple loads to access the appropriate 32/16 bytes. Developers of multi-threaded or multi-processor software should be aware that on these processors the loads will be performed in a non-atomic way.
If alignment checking is enabled (CR0.AM = 1, RFLAGS.AC = 1, and CPL = 3), an alignment-check exception (#AC) may or may not be generated (depending on processor implementation) when the memory address is not aligned on an 8-byte boundary.
In 64-bit mode, use of the REX.R prefix permits this instruction to access additional registers (XMM8-XMM15).

Note: In VEX-encoded versions, VEX.vvvv is reserved and must be 1111b otherwise instructions will #UD.

Operation:

LDDQU (128-bit Legacy SSE Version):

DEST[127:0] := SRC[127:0]
DEST[MAXVL-1:128] (Unmodified)

VLDDQU (VEX.128 Encoded Version):

DEST[127:0] := SRC[127:0]
DEST[MAXVL-1:128] := 0

VLDDQU (VEX.256 Encoded Version):

DEST[255:0] := SRC[255:0]

Intel C/C++ Compiler Intrinsic Equivalent:

LDDQU __m128i _mm_lddqu_si128 (__m128i * p);
VLDDQU __m256i _mm256_lddqu_si256 (__m256i * p);

Numeric Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”

Note treatment of #AC varies.





LDMXCSR — Load MXCSR Register

Opcode/Instruction	                Op/En	64/32-bit Mode	    CPUID Feature Flag	    Description
NP 0F AE /2 LDMXCSR m32	            M	    V/V	                SSE	                    Load MXCSR register from m32.
VEX.LZ.0F.WIG AE /2 VLDMXCSR m32	M	    V/V	                AVX	                    Load MXCSR register from m32.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	Operand 3	Operand 4
M	    ModRM:r/m (r)	N/A	        N/A	        N/A

Description:

Loads the source operand into the MXCSR control/status register. The source operand is a 32-bit memory location. See “MXCSR Control and Status Register” in Chapter 10, of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1, for a description of the MXCSR register and its contents.

The LDMXCSR instruction is typically used in conjunction with the (V)STMXCSR instruction, which stores the contents of the MXCSR register in memory.

The default MXCSR value at reset is 1F80H.

If a (V)LDMXCSR instruction clears a SIMD floating-point exception mask bit and sets the corresponding exception flag bit, a SIMD floating-point exception will not be immediately generated. The exception will be generated only upon the execution of the next instruction that meets both conditions below:

the instruction must operate on an XMM or YMM register operand,
the instruction causes that particular SIMD floating-point exception to be reported.
This instruction’s operation is the same in non-64-bit modes and 64-bit mode.

If VLDMXCSR is encoded with VEX.L= 1, an attempt to execute the instruction encoded with VEX.L= 1 will cause an #UD exception.

Note: In VEX-encoded versions, VEX.vvvv is reserved and must be 1111b, otherwise instructions will #UD.

Operation:

MXCSR := m32;

C/C++ Compiler Intrinsic Equivalent:

_mm_setcsr(unsigned int i)

Numeric Exceptions:

None.

Other Exceptions:

See Table 2-22, “Type 5 Class Exception Conditions,” additionally:

#GP:
	For an attempt to set reserved bits in MXCSR.
#UD:
	If VEX.vvvv ≠ 1111B.






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





LDTILECFG — Load Tile Configuration

Opcode/Instruction	                                Op/En	64/32 bit Mode Support	CPUID Feature Flag	    Description
VEX.128.NP.0F38.W0 49 !(11):000:bbb LDTILECFG m512	A	    V/N.E.	                AMX-TILE	            Load tile configuration as specified in m512.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	    Operand 2	Operand 3	Operand 4
A	    N/A	    ModRM:r/m (r)	N/A	        N/A	        N/A

Description:

The LDTILECFG instruction takes an operand containing a pointer to a 64-byte memory location containing the description of the tiles to be supported. In order to configure the tiles, the AMX-TILE bit in CPUID must be set and the operating system has to have enabled the tiles architecture.

The memory area contains the palette and describes how many tiles are being used and defines each tile in terms of rows and column bytes. Requests must be compatible with the restrictions provided by CPUID; see Table 3-10 below.

Byte(s)	    Field Name	                Description
0	        palette	Palette             selects the supported configuration of the tiles that will be used.
1	        start_row	                start_row is used for storing the restart values for interrupted operations.
2-15	    reserved, must be zero	
16-17	    tile0.colsb	                Tile 0 bytes per row.
18-19	    tile1.colsb	                Tile 1 bytes per row.
20-21	    tile2.colsb	                Tile 2 bytes per row.
...	(sequence continues)	
30-31	    tile7.colsb	                Tile 7 bytes per row.
32-47	    reserved, must be zero	
48	        tile0.rows	                Tile 0 rows.
49	        tile1.rows	                Tile 1 rows.
50	        tile2.rows	                Tile 2 rows.
...	(sequence continues)	
55	        tile7.rows	                Tile 7 rows.
56-63	    reserved, must be zero	
Table 3-10. Memory Area Layout

If a tile row and column pair is not used to specify tile parameters, they must have the value zero. All enabled tiles (based on the palette) must be configured. Specifying tile parameters for more tiles than the implementation limit or the palette limit results in a #GP fault.

If the palette_id is zero, that signifies the INIT state for both TILECFG and TILEDATA. Tiles are zeroed in the INIT state. The only legal non-INIT value for palette_id is 1.

Any attempt to execute the LDTILECFG instruction inside an Intel TSX transaction will result in a transaction abort.

Operation:

LDTILECFG mem:

error := False
buf := read_memory(mem, 64)
temp_tilecfg.palette_id := buf.byte[0]
if temp_tilecfg.palette_id > max_palette:
    error := True
if not xcr0_supports_palette(temp_tilecfg.palette_id):
    error := True
if temp_tilecfg.palette_id !=0:
    temp_tilecfg.start_row := buf.byte[1]
    if buf.byte[2..15] is nonzero:
        error := True
    p := 16
    # configure columns
    for n in 0 ... palette_table[temp_tilecfg.palette_id].max_names-1:
        temp_tilecfg.t[n].colsb:= buf.word[p/2]
        p := p + 2
        if temp_tilecfg.t[n].colsb > palette_table[temp_tilecfg.palette_id].bytes_per_row:
            error := True
    if nonzero(buf[p...47]):
        error := True
    # configure rows
    p := 48
    for n in 0 ... palette_table[temp_tilecfg.palette_id].max_names-1:
        temp_tilecfg.t[n].rows:= buf.byte[p]
        if temp_tilecfg.t[n].rows > palette_table[temp_tilecfg.palette_id].max_rows:
            error := True
        p := p + 1
    if nonzero(buf[p...63]):
        error := True
    # validate each tile's row & col configs are reasonable and enable the valid tiles
    for n in 0 ... palette_table[temp_tilecfg.palette_id].max_names-1:
        if temp_tilecfg.t[n].rows !=0 and temp_tilecfg.t[n].colsb != 0:
            temp_tilecfg.t[n].valid := 1
        elif temp_tilecfg.t[n].rows == 0 and temp_tilecfg.t[n].colsb == 0:
            temp_tilecfg.t[n].valid := 0
        else:
            error := True// one of rows or colsbwas 0 but not both.
if error:
    #GP
elif temp_tilecfg.palette_id == 0:
    TILES_CONFIGURED := 0// init state
    tilecfg := 0// equivalent to 64B of zeros
    zero_all_tile_data()
else:
    tilecfg := temp_tilecfg
    zero_all_tile_data()
    TILES_CONFIGURED := 1

Intel C/C++ Compiler Intrinsic Equivalent:

LDTILECFG void _tile_loadconfig(const void *);

Flags Affected:

None.

Exceptions:

AMX-E1; see Section 2.10, “Intel® AMX Instruction Exception Classes,” for details.






LEA — Load Effective Address

Opcode	        Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
8D /r	        LEA r16,m	    RM	    Valid	        Valid	            Store effective address for m in register r16.
8D /r	        LEA r32,m	    RM	    Valid	        Valid	            Store effective address for m in register r32.
REX.W + 8D /r	LEA r64,m	    RM	    Valid	        N.E.	            Store effective address for m in register r64.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A	        N/A

Description:

Computes the effective address of the second operand (the source operand) and stores it in the first operand (destination operand). The source operand is a memory address (offset part) specified with one of the processors addressing modes; the destination operand is a general-purpose register. The address-size and operand-size attributes affect the action performed by this instruction, as shown in the following table. The operand-size attribute of the instruction is determined by the chosen register; the address-size attribute is determined by the attribute of the code segment.

Operand Size	Address Size	Action Performed
16	            16	            16-bit effective address is calculated and stored in requested 16-bit register destination.
16	            32	            32-bit effective address is calculated. The lower 16 bits of the address are stored in the requested 16-bit register destination.
32	            16	            16-bit effective address is calculated. The 16-bit address is zero-extended and stored in the requested 32-bit register destination.
32	            32	            32-bit effective address is calculated and stored in the requested 32-bit register destination.
Table 3-54. Non-64-bit Mode LEA Operation with Address and Operand Size Attributes

Different assemblers may use different algorithms based on the size attribute and symbolic reference of the source operand.

In 64-bit mode, the instruction’s destination operand is governed by operand size attribute, the default operand size is 32 bits. Address calculation is governed by address size attribute, the default address size is 64-bits. In 64-bit mode, address size of 16 bits is not encodable. See Table 3-55.

Operand Size	Address Size	Action Performed
16	            32	            32-bit effective address is calculated (using 67H prefix). The lower 16 bits of the address are stored in the requested 16-bit register destination (using 66H prefix).
16	            64	            64-bit effective address is calculated (default address size). The lower 16 bits of the address are stored in the requested 16-bit register destination (using 66H prefix).
32	            32	            32-bit effective address is calculated (using 67H prefix) and stored in the requested 32-bit register destination.
32	            64	            64-bit effective address is calculated (default address size) and the lower 32 bits of the address are stored in the requested 32-bit register destination.
64	            32	            32-bit effective address is calculated (using 67H prefix), zero-extended to 64-bits, and stored in the requested 64-bit register destination (using REX.W).
64	            64	            64-bit effective address is calculated (default address size) and all 64-bits of the address are stored in the requested 64-bit register destination (using REX.W).
Table 3-55. 64-bit Mode LEA Operation with Address and Operand Size Attributes

Operation:

IF OperandSize = 16 and AddressSize = 16
    THEN
        DEST := EffectiveAddress(SRC); (* 16-bit address *)
    ELSE IF OperandSize = 16 and AddressSize = 32
        THEN
            temp := EffectiveAddress(SRC); (* 32-bit address *)
            DEST := temp[0:15]; (* 16-bit address *)
        FI;
    ELSE IF OperandSize = 32 and AddressSize = 16
        THEN
            temp := EffectiveAddress(SRC); (* 16-bit address *)
            DEST := ZeroExtend(temp); (* 32-bit address *)
        FI;
    ELSE IF OperandSize = 32 and AddressSize = 32
        THEN
            DEST := EffectiveAddress(SRC); (* 32-bit address *)
        FI;
    ELSE IF OperandSize = 16 and AddressSize = 64
        THEN
            temp := EffectiveAddress(SRC); (* 64-bit address *)
            DEST := temp[0:15]; (* 16-bit address *)
        FI;
    ELSE IF OperandSize = 32 and AddressSize = 64
        THEN
            temp := EffectiveAddress(SRC); (* 64-bit address *)
            DEST := temp[0:31]; (* 16-bit address *)
        FI;
    ELSE IF OperandSize = 64 and AddressSize = 64
        THEN
            DEST := EffectiveAddress(SRC); (* 64-bit address *)
        FI;
FI;

Flags Affected:

None.

Protected Mode Exceptions:

#UD:
	If source operand is not a memory location.
    If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as in protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as in protected mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

Same exceptions as in protected mode.







LFENCE — Load Fence

Opcode / Instruction	Op/En	64/32 bit Mode Support	    CPUID Feature Flag	    Description
NP 0F AE E8 LFENCE	    ZO	    V/V	                        SSE2	                Serializes load operations.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Performs a serializing operation on all load-from-memory instructions that were issued prior the LFENCE instruction. Specifically, LFENCE does not execute until all prior instructions have completed locally, and no later instruction begins execution until LFENCE completes. In particular, an instruction that loads from memory and that precedes an LFENCE receives data from memory prior to completion of the LFENCE. (An LFENCE that follows an instruction that stores to memory might complete before the data being stored have become globally visible.) Instructions following an LFENCE may be fetched from memory before the LFENCE, but they will not execute (even speculatively) until the LFENCE completes.

Weakly ordered memory types can be used to achieve higher processor performance through such techniques as out-of-order issue and speculative reads. The degree to which a consumer of data recognizes or knows that the data is weakly ordered varies among applications and may be unknown to the producer of this data. The LFENCE instruction provides a performance-efficient way of ensuring load ordering between routines that produce weakly-ordered results and routines that consume that data.

Processors are free to fetch and cache data speculatively from regions of system memory that use the WB, WC, and WT memory types. This speculative fetching can occur at any time and is not tied to instruction execution. Thus, it is not ordered with respect to executions of the LFENCE instruction; data can be brought into the caches speculatively just before, during, or after the execution of an LFENCE instruction.

This instruction’s operation is the same in non-64-bit modes and 64-bit mode.

Specification of the instruction's opcode above indicates a ModR/M byte of E8. For this instruction, the processor ignores the r/m field of the ModR/M byte. Thus, LFENCE is encoded by any opcode of the form 0F AE Ex, where x is in the range 8-F.

Operation:

Wait_On_Following_Instructions_Until(preceding_instructions_complete);

Intel C/C++ Compiler Intrinsic Equivalent:

void _mm_lfence(void)

Exceptions (All Modes of Operation):

#UD:
    If CPUID.01H:EDX.SSE2[bit 26] = 0.
    If the LOCK prefix is used.






LGDT/LIDT — Load Global/Interrupt Descriptor Table Register

Opcode	    Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 01 /2	LGDT m16&32	    M	    N.E.	        Valid	            Load m into GDTR.
0F 01 /3	LIDT m16&32	    M	    N.E.	        Valid	            Load m into IDTR.
0F 01 /2	LGDT m16&64	    M	    Valid	        N.E.	            Load m into GDTR.
0F 01 /3	LIDT m16&64	    M	    Valid	        N.E.	            Load m into IDTR.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	Operand 3	Operand 4
M	    ModRM:r/m (r)	N/A	        N/A	        N/A

Description:

Loads the values in the source operand into the global descriptor table register (GDTR) or the interrupt descriptor table register (IDTR). The source operand specifies a 6-byte memory location that contains the base address (a linear address) and the limit (size of table in bytes) of the global descriptor table (GDT) or the interrupt descriptor table (IDT). If operand-size attribute is 32 bits, a 16-bit limit (lower 2 bytes of the 6-byte data operand) and a 32-bit base address (upper 4 bytes of the data operand) are loaded into the register. If the operand-size attribute is 16 bits, a 16-bit limit (lower 2 bytes) and a 24-bit base address (third, fourth, and fifth byte) are loaded. Here, the high-order byte of the operand is not used and the high-order byte of the base address in the GDTR or IDTR is filled with zeros.

The LGDT and LIDT instructions are used only in operating-system software; they are not used in application programs. They are the only instructions that directly load a linear address (that is, not a segment-relative address) and a limit in protected mode. They are commonly executed in real-address mode to allow processor initialization prior to switching to protected mode.

In 64-bit mode, the instruction’s operand size is fixed at 8+2 bytes (an 8-byte base and a 2-byte limit). See the summary chart at the beginning of this section for encoding data and limits.

See “SGDT—Store Global Descriptor Table Register” in Chapter 4, of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 2B, for information on storing the contents of the GDTR and IDTR.

Operation:

IF Instruction is LIDT
    THEN
        IF OperandSize = 16
            THEN
                IDTR(Limit) := SRC[0:15];
                IDTR(Base) := SRC[16:47] AND 00FFFFFFH;
            ELSE IF 32-bit Operand Size
                THEN
                    IDTR(Limit) := SRC[0:15];
                    IDTR(Base) := SRC[16:47];
                FI;
            ELSE IF 64-bit Operand Size (* In 64-Bit Mode *)
                THEN
                    IDTR(Limit) := SRC[0:15];
                    IDTR(Base) := SRC[16:79];
                FI;
        FI;
    ELSE (* Instruction is LGDT *)
        IF OperandSize = 16
            THEN
                GDTR(Limit) := SRC[0:15];
                GDTR(Base) := SRC[16:47] AND 00FFFFFFH;
            ELSE IF 32-bit Operand Size
                THEN
                    GDTR(Limit) := SRC[0:15];
                    GDTR(Base) := SRC[16:47];
                FI;
            ELSE IF 64-bit Operand Size (* In 64-Bit Mode *)
                THEN
                    GDTR(Limit) := SRC[0:15];
                    GDTR(Base) := SRC[16:79];
                FI;
        FI;
FI;

Flags Affected:

None.

Protected Mode Exceptions:

#UD:
	If the LOCK prefix is used.
#GP(0):
	If the current privilege level is not 0.
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
	If a page fault occurs.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used.
#GP:
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS:
	If a memory operand effective address is outside the SS segment limit.

Virtual-8086 Mode Exceptions:

#UD:
	If the LOCK prefix is used.
#GP:
	If the current privilege level is not 0.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#SS(0):
	If a memory address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the current privilege level is not 0.
    If the memory address is in a non-canonical form.
#UD:
	If the LOCK prefix is used.
#PF(fault-code):
	If a page fault occurs.






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






LOADIWKEY — Load Internal Wrapping Key With Key Locker

Opcode/Instruction	                                        Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 DC 11:rrr:bbb LOADIWKEY xmm1, xmm2, <EAX>, <XMM0>	A	    V/V	            KL	                Load internal wrapping key from xmm1, xmm2, and XMM0.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	    Operand 2	    Operand 3	        Operand 4
A	    N/A	    ModRM:reg (r)	ModRM:r/m (r)	Implicit EAX (r)	Implicit XMM0 (r)

Description:

The LOADIWKEY1 instruction writes the Key Locker internal wrapping key, which is called IWKey. This IWKey is used by the ENCODEKEY* instructions to wrap keys into handles. Conversely, the AESENC/DEC*KL instructions use IWKey to unwrap those keys from the handles and help verify the handle integrity. For security reasons, no instruction is designed to allow software to directly read the IWKey value.

IWKey includes two cryptographic keys as well as metadata. The two cryptographic keys are loaded from register sources so that LOADIWKEY can be executed without the keys ever being in memory.

The key input operands are:

The 256-bit encryption key is loaded from the two explicit operands.
The 128-bit integrity key is loaded from the implicit operand XMM0.
The implicit operand EAX specifies the KeySource and whether backing up the key is permitted:

EAX[0] – When set, the wrapping key being initialized is not permitted to be backed up to platform-scoped storage.
EAX[4:1] – This specifies the KeySource, which is the type of key. Currently only two encodings are supported. A KeySource of 0 indicates that the key input operands described above should be directly stored as the internal wrapping keys. LOADIWKEY with a KeySource of 1 will have random numbers from the on-chip random number generator XORed with the source registers (including XMM0) so that the software that executes the LOADIWKEY does not know the actual IWKey encryption and integrity keys. Software can choose to put additional random data into the source registers so that other sources of random data are combined with the hardware random number generator supplied value. Software should always check ZF after executing LOADIWKEY with KeySource of 1 as this operation may fail due to it being unable to get sufficient full-entropy data from the on-chip random number generator. Both KeySource of 0 and 1 specify that IWKey be used with the AES-GCM-SIV algorithm. CPUID.19H.ECX[1] enumerates support for KeySource of 1. All other KeySource encodings are reserved.
EAX[31:5] – Reserved.
1. Further details on Key Locker and usage of this instruction can be found here:

https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html. ¶

Operation:

LOADIWKEY:

IF CPL > 0
                    // LOADKWKEY only allowed at ring 0 (supervisor mode)
    THEN #GP (0); FI;
IF EAX[4:1] > 1
                    // Reserved KeySource encoding used
    THEN #GP (0); FI;
IF EAX[31:5] != 0
                    // Reserved bit in EAX is set
    THEN #GP (0); FI;
IF EAX[0] AND (CPUID.19H.ECX[0] == 0)
                        // NoBackup is not supported on this part
    THEN #GP (0); FI;
IF (EAX[4:1] == 1) AND (CPUID.19H.ECX[1] == 0)
                        // KeySource of 1 is not supported on this part
    THEN #GP (0); FI;
IF (EAX[4:1] == 0) // KeySource of 0
    THEN
        IWKey.Encryption Key[127:0] := SRC2[127:0]:
        IWKey.Encryption Key[255:128] := SRC1[127:0];
        IWKey.IntegrityKey[127:0] := XMM0[127:0];
        IWKey.NoBackup = EAX [0];
        IWKey.KeySource = EAX [4:1];
        RFLAGS.ZF := 0;
    ELSE // KeySource of 1. See RDSEED definition for details of randomness
        IF HW_NRND_GEN.ready == 1 // Full-entropy random data from RDSEED hardware block was received
            THEN
                IWKey.Encryption Key[127:0] := SRC2[127:0] XOR HW_NRND_GEN.data[127:0];
                IWKey.Encryption Key[255:128] := SRC1[127:0] XOR HW_NRND_GEN.data[255:128];
                IWKey.IntegrityKey[127:0] := XMM0[127:0] XOR HW_NRND_GEN.data[383:256];
                IWKey.NoBackup = EAX [0];
                IWKey.KeySource = EAX [4:1];
                RFLAGS.ZF := 0;
            ELSE // Random data was not returned from RDSEED hardware block. IWKey was not loaded
                RFLAGS.ZF := 1;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to full-entropy random data not being received from RDSEED. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

Intel C/C++ Compiler Intrinsic Equivalent:

LOADIWKEY void _mm_loadiwkey(unsigned int ctl, __m128i intkey, __m128i enkey_lo, __m128i enkey_hi);

Exceptions (All Operating Modes):

#GP:
    If CPL > 0. (Does not apply in real-address mode.)

    If EAX[4:1] > 1.

    If EAX[31:5] != 0.

    If (EAX[0] == 1) AND (CPUID.19H.ECX[0] == 0).

    If (EAX[4:1] == 1) AND (CPUID.19H.ECX[1] == 0).

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

#NM:
    If CR0.TS = 1.








LODS/LODSB/LODSW/LODSD/LODSQ — Load String

Opcode	    Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
AC	        LODS m8	        ZO	    Valid	        Valid	            For legacy mode, Load byte at address DS:(E)SI into AL. For 64-bit mode load byte at address (R)SI into AL.
AD	        LODS m16	    ZO	    Valid	        Valid	            For legacy mode, Load word at address DS:(E)SI into AX. For 64-bit mode load word at address (R)SI into AX.
AD	        LODS m32	    ZO	    Valid	        Valid	            For legacy mode, Load dword at address DS:(E)SI into EAX. For 64-bit mode load dword at address (R)SI into EAX.
REX.W + AD	LODS m64	    ZO	    Valid	        N.E.	            Load qword at address (R)SI into RAX.
AC	        LODSB	        ZO	    Valid	        Valid	            For legacy mode, Load byte at address DS:(E)SI into AL. For 64-bit mode load byte at address (R)SI into AL.
AD	        LODSW	        ZO	    Valid	        Valid	            For legacy mode, Load word at address DS:(E)SI into AX. For 64-bit mode load word at address (R)SI into AX.
AD	        LODSD	        ZO	    Valid	        Valid	            For legacy mode, Load dword at address DS:(E)SI into EAX. For 64-bit mode load dword at address (R)SI into EAX.
REX.W + AD	LODSQ	        ZO	    Valid	        N.E.	            Load qword at address (R)SI into RAX.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Loads a byte, word, or doubleword from the source operand into the AL, AX, or EAX register, respectively. The source operand is a memory location, the address of which is read from the DS:ESI or the DS:SI registers (depending on the address-size attribute of the instruction, 32 or 16, respectively). The DS segment may be overridden with a segment override prefix.

At the assembly-code level, two forms of this instruction are allowed: the “explicit-operands” form and the “no-operands” form. The explicit-operands form (specified with the LODS mnemonic) allows the source operand to be specified explicitly. Here, the source operand should be a symbol that indicates the size and location of the source value. The destination operand is then automatically selected to match the size of the source operand (the AL register for byte operands, AX for word operands, and EAX for doubleword operands). This explicit-operands form is provided to allow documentation; however, note that the documentation provided by this form can be misleading. That is, the source operand symbol must specify the correct type (size) of the operand (byte, word, or doubleword), but it does not have to specify the correct location. The location is always specified by the DS:(E)SI registers, which must be loaded correctly before the load string instruction is executed.

The no-operands form provides “short forms” of the byte, word, and doubleword versions of the LODS instructions. Here also DS:(E)SI is assumed to be the source operand and the AL, AX, or EAX register is assumed to be the destination operand. The size of the source and destination operands is selected with the mnemonic: LODSB (byte loaded into register AL), LODSW (word loaded into AX), or LODSD (doubleword loaded into EAX).

After the byte, word, or doubleword is transferred from the memory location into the AL, AX, or EAX register, the (E)SI register is incremented or decremented automatically according to the setting of the DF flag in the EFLAGS register. (If the DF flag is 0, the (E)SI register is incremented; if the DF flag is 1, the ESI register is decremented.) The (E)SI register is incremented or decremented by 1 for byte operations, by 2 for word operations, or by 4 for doubleword operations.

In 64-bit mode, use of the REX.W prefix promotes operation to 64 bits. LODS/LODSQ load the quadword at address (R)SI into RAX. The (R)SI register is then incremented or decremented automatically according to the setting of the DF flag in the EFLAGS register.

The LODS, LODSB, LODSW, and LODSD instructions can be preceded by the REP prefix for block loads of ECX bytes, words, or doublewords. More often, however, these instructions are used within a LOOP construct because further processing of the data moved into the register is usually necessary before the next transfer can be made. See “REP/REPE/REPZ /REPNE/REPNZ—Repeat String Operation Prefix” in Chapter 4 of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 2B, for a description of the REP prefix.

Operation:

IF AL := SRC; (* Byte load *)
    THEN AL := SRC; (* Byte load *)
        IF DF = 0
            THEN (E)SI := (E)SI + 1;
            ELSE (E)SI := (E)SI – 1;
        FI;
ELSE IF AX := SRC; (* Word load *)
    THEN IF DF = 0
            THEN (E)SI := (E)SI + 2;
            ELSE (E)SI := (E)SI – 2;
        IF;
    FI;
ELSE IF EAX := SRC; (* Doubleword load *)
    THENIFDF =0
            THEN (E)SI := (E)SI + 4;
            ELSE (E)SI := (E)SI – 4;
        FI;
    FI;
ELSE IF RAX := SRC; (* Quadword load *)
    THEN IF DF = 0
            THEN (R)SI := (R)SI + 8;
            ELSE (R)SI := (R)SI – 8;
        FI;
    FI;
FI;

Flags Affected:

None.

Protected Mode Exceptions:

#GP(0):
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the DS, ES, FS, or GS register contains a NULL segment selector.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while the current privilege level is 3.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#GP:
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS:
	If a memory operand effective address is outside the SS segment limit.
#UD:
	If the LOCK prefix is used.

Virtual-8086 Mode Exceptions:

#GP(0):
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made.
#UD:
	If the LOCK prefix is used.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#SS(0):
	If a memory address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the memory address is in a non-canonical form.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while the current privilege level is 3.
#UD:
	If the LOCK prefix is used.







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