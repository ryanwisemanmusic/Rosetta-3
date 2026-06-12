BNDCL — Check Lower Bound

Opcode/Instruction	            Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
F3 0F 1A /r BNDCL bnd, r/m32	RM	    N.E./V	                MPX	                Generate a #BR if the address in r/m32 is lower than the lower bound in bnd.LB.
F3 0F 1A /r BNDCL bnd, r/m64	RM	    V/N.E.	                MPX	                Generate a #BR if the address in r/m64 is lower than the lower bound in bnd.LB.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A

Description:

Compare the address in the second operand with the lower bound in bnd. The second operand can be either a register or memory operand. If the address is lower than the lower bound in bnd.LB, it will set BNDSTATUS to 01H and signal a #BR exception.

This instruction does not cause any memory access, and does not read or write any flags.

Operation:

BNDCL BND, reg:

IF reg < BND.LB Then
    BNDSTATUS := 01H;
    #BR;
FI;

BNDCL BND, mem:

TEMP := LEA(mem);
IF TEMP < BND.LB Then
    BNDSTATUS := 01H;
    #BR;
FI;

Intel C/C++ Compiler Intrinsic Equivalent:

BNDCL void _bnd_chk_ptr_lbounds(const void *q)

Flags Affected:

None

Protected Mode Exceptions:

#BR:
	If lower bound check fails.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 67H prefix is not used and CS.D=0.
    If 67H prefix is used and CS.D=1.

Real-Address Mode Exceptions:

#BR:
	If lower bound check fails.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.

Virtual-8086 Mode Exceptions:

#BR:
	If lower bound check fails.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#UD:
	If ModRM.r/m and REX encodes BND4-BND15 when Intel MPX is enabled.
    Same exceptions as in protected mode.


BNDCU/BNDCN — Check Upper Bound

Opcode/Instruction	            Op/En	    64/32 bit Mode Support	CPUID Feature Flag	Description
F2 0F 1A /r BNDCU bnd, r/m32	RM	        N.E./V	                MPX	                Generate a #BR if the address in r/m32 is higher than the upper bound in bnd.UB (bnb.UB in 1's complement form).
F2 0F 1A /r BNDCU bnd, r/m64	RM	        V/N.E.	                MPX	                Generate a #BR if the address in r/m64 is higher than the upper bound in bnd.UB (bnb.UB in 1's complement form).
F2 0F 1B /r BNDCN bnd, r/m32	RM	        N.E./V	                MPX	                Generate a #BR if the address in r/m32 is higher than the upper bound in bnd.UB (bnb.UB not in 1's complement form).
F2 0F 1B /r BNDCN bnd, r/m64	RM	        V/N.E.	                MPX	                Generate a #BR if the address in r/m64 is higher than the upper bound in bnd.UB (bnb.UB not in 1's complement form).

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A

Description:

Compare the address in the second operand with the upper bound in bnd. The second operand can be either a register or a memory operand. If the address is higher than the upper bound in bnd.UB, it will set BNDSTATUS to 01H and signal a #BR exception.

BNDCU perform 1’s complement operation on the upper bound of bnd first before proceeding with address comparison. BNDCN perform address comparison directly using the upper bound in bnd that is already reverted out of 1’s complement form.

This instruction does not cause any memory access, and does not read or write any flags.

Effective address computation of m32/64 has identical behavior to LEA

Operation:

BNDCU BND, reg:

IF reg > NOT(BND.UB) Then
    BNDSTATUS := 01H;
    #BR;
FI;

BNDCU BND, mem:

TEMP := LEA(mem);
IF TEMP > NOT(BND.UB) Then
    BNDSTATUS := 01H;
    #BR;
FI;

BNDCN BND, reg:

IF reg > BND.UB Then
    BNDSTATUS := 01H;
    #BR;
FI;

BNDCN BND, mem:

TEMP := LEA(mem);
IF TEMP > BND.UB Then
    BNDSTATUS := 01H;
    #BR;
FI;

Intel C/C++ Compiler Intrinsic Equivalent:

BNDCU .void _bnd_chk_ptr_ubounds(const void *q)

Flags Affected:

None

Protected Mode Exceptions:

#BR:
	If upper bound check fails.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 67H prefix is not used and CS.D=0.
    If 67H prefix is used and CS.D=1.

Real-Address Mode Exceptions:

#BR:
	If upper bound check fails.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.

Virtual-8086 Mode Exceptions:

#BR:
	If upper bound check fails.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#UD:
	If ModRM.r/m and REX encodes BND4-BND15 when Intel MPX is enabled.
    Same exceptions as in protected mode.



BNDLDX — Load Extended Bounds Using Address Translation

Opcode/Instruction	            Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 1A /r BNDLDX bnd, mib	    RM	    V/V	                    MPX	                Load the bounds stored in a bound table entry (BTE) into bnd with address translation using the base of mib and conditional on the index of mib matching the pointer value in the BTE.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	                                    Operand 3
RM	    ModRM:reg (w)	SIB.base (r): Address of pointer SIB.index(r)	N/A

Description:

BNDLDX uses the linear address constructed from the base register and displacement of the SIB-addressing form of the memory operand (mib) to perform address translation to access a bound table entry and conditionally load the bounds in the BTE to the destination. The destination register is updated with the bounds in the BTE, if the content of the index register of mib matches the pointer value stored in the BTE.

If the pointer value comparison fails, the destination is updated with INIT bounds (lb = 0x0, ub = 0x0) (note: as articulated earlier, the upper bound is represented using 1's complement, therefore, the 0x0 value of upper bound allows for access to full memory).

This instruction does not cause memory access to the linear address of mib nor the effective address referenced by the base, and does not read or write any flags.

Segment overrides apply to the linear address computation with the base of mib, and are used during address translation to generate the address of the bound table entry. By default, the address of the BTE is assumed to be linear address. There are no segmentation checks performed on the base of mib.

The base of mib will not be checked for canonical address violation as it does not access memory.

Any encoding of this instruction that does not specify base or index register will treat those registers as zero (constant). The reg-reg form of this instruction will remain a NOP.

The scale field of the SIB byte has no effect on these instructions and is ignored.

The bound register may be partially updated on memory faults. The order in which memory operands are loaded is implementation specific.

Operation:

base := mib.SIB.base ? mib.SIB.base + Disp: 0;
ptr_value := mib.SIB.index ? mib.SIB.index : 0;

Outside 64-bit Mode:

A_BDE[31:0] := (Zero_extend32(base[31:12] « 2) + (BNDCFG[31:12] «12 );
A_BT[31:0] := LoadFrom(A_BDE );
IF A_BT[0] equal 0 Then
    BNDSTATUS := A_BDE | 02H;
    #BR;
FI;
A_BTE[31:0] := (Zero_extend32(base[11:2] « 4) + (A_BT[31:2] « 2 );
Temp_lb[31:0] := LoadFrom(A_BTE);
Temp_ub[31:0] := LoadFrom(A_BTE + 4);
Temp_ptr[31:0] := LoadFrom(A_BTE + 8);
IF Temp_ptr equal ptr_value Then
    BND.LB := Temp_lb;
    BND.UB := Temp_ub;
ELSE
    BND.LB := 0;
    BND.UB := 0;
FI;

In 64-bit Mode:

A_BDE[63:0] := (Zero_extend64(base[47+MAWA:20] « 3) + (BNDCFG[63:12] «12 );1
A_BT[63:0] := LoadFrom(A_BDE);
IF A_BT[0] equal 0 Then
    BNDSTATUS := A_BDE | 02H;
    #BR;
FI;
A_BTE[63:0] := (Zero_extend64(base[19:3] « 5) + (A_BT[63:3] « 3 );
Temp_lb[63:0] := LoadFrom(A_BTE);
Temp_ub[63:0] := LoadFrom(A_BTE + 8);
Temp_ptr[63:0] := LoadFrom(A_BTE + 16);
IF Temp_ptr equal ptr_value Then
    BND.LB := Temp_lb;
    BND.UB := Temp_ub;
ELSE
    BND.LB := 0;
    BND.UB := 0;
FI;

Intel C/C++ Compiler Intrinsic Equivalent:

BNDLDX: Generated by compiler as needed.

Flags Affected:

None.

Protected Mode Exceptions:

#BR:
	If the bound directory entry is invalid.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 67H prefix is not used and CS.D=0.
    If 67H prefix is used and CS.D=1.
#GP(0):
	If a destination effective address of the Bound Table entry is outside the DS segment limit.
    If DS register contains a NULL segment selector.
#PF(fault	code):
    If a page fault occurs.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.
#GP(0):
	If a destination effective address of the Bound Table entry is outside the DS segment limit.

1. If CPL < 3, the supervisor MAWA (MAWAS) is used; this value is 0. If CPL = 3, the user MAWA (MAWAU) is used; this value is enumerated in CPUID.(EAX=07H,ECX=0H):ECX.MAWAU[bits 21:17]. See Appendix E.3.1 of Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1.

Virtual-8086 Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.
#GP(0):
	If a destination effective address of the Bound Table entry is outside the DS segment limit.
#PF(fault	code):
    If a page fault occurs.
Compatibility Mode Exceptions ¶

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#BR:
	If the bound directory entry is invalid.
#UD:
	If ModRM is RIP relative.
    If the LOCK prefix is used.
    If ModRM.r/m and REX encodes BND4-BND15 when Intel MPX is enabled.
#GP(0):
	If the memory address (A_BDE or A_BTE) is in a non-canonical form.
#PF(fault	code):
    If a page fault occurs.


BNDMK — Make Bounds

Opcode/Instruction	            Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
F3 0F 1B /r BNDMK bnd, m32	    RM	    N.E./V	                MPX	                Make lower and upper bounds from m32 and store them in bnd.
F3 0F 1B /r BNDMK bnd, m64	    RM	    V/N.E.	                MPX	                Make lower and upper bounds from m64 and store them in bnd.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A

Description:

Makes bounds from the second operand and stores the lower and upper bounds in the bound register bnd. The second operand must be a memory operand. The content of the base register from the memory operand is stored in the lower bound bnd.LB. The 1's complement of the effective address of m32/m64 is stored in the upper bound b.UB. Computation of m32/m64 has identical behavior to LEA.

This instruction does not cause any memory access, and does not read or write any flags.

If the instruction did not specify base register, the lower bound will be zero. The reg-reg form of this instruction retains legacy behavior (NOP).

The instruction causes an invalid-opcode exception (#UD) if executed in 64-bit mode with RIP-relative addressing.

Operation:

BND.LB := SRCMEM.base;
IF 64-bit mode Then
    BND.UB := NOT(LEA.64_bits(SRCMEM));
ELSE
    BND.UB := Zero_Extend.64_bits(NOT(LEA.32_bits(SRCMEM)));
FI;

Intel C/C++ Compiler Intrinsic Equivalent:

BNDMKvoid * _bnd_set_ptr_bounds(const void * q, size_t size);

Flags Affected:

None.

Protected Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 67H prefix is not used and CS.D=0.
    If 67H prefix is used and CS.D=1.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.

Virtual-8086 Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m and REX encodes BND4-BND15 when Intel MPX is enabled.
    If RIP-relative addressing is used.
#SS(0):
	If the memory address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the memory address is in a non-canonical form.
    Same exceptions as in protected mode.




BNDMOV — Move Bounds

Opcode/Instruction	                Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
66 0F 1A /r BNDMOV bnd1, bnd2/m64	RM	    N.E./V	                MPX	                Move lower and upper bound from bnd2/m64 to bound register bnd1.
66 0F 1A /r BNDMOV bnd1, bnd2/m128	RM	    V/N.E.	                MPX	                Move lower and upper bound from bnd2/m128 to bound register bnd1.
66 0F 1B /r BNDMOV bnd1/m64, bnd2	MR	    N.E./V	                MPX	                Move lower and upper bound from bnd2 to bnd1/m64.
66 0F 1B /r BNDMOV bnd1/m128, bnd2	MR	    V/N.E.	                MPX	                Move lower and upper bound from bnd2 to bound register bnd1/m128.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A
MR	    ModRM:r/m (w)	ModRM:reg (r)	N/A

Description:

BNDMOV moves a pair of lower and upper bound values from the source operand (the second operand) to the destination (the first operand). Each operation is 128-bit move. The exceptions are same as the MOV instruction. The memory format for loading/store bounds in 64-bit mode is shown in Figure 3-5.

Operation:

BNDMOV register to register:

DEST.LB := SRC.LB;
DEST.UB := SRC.UB;
BNDMOV from memory:

IF 64-bit mode THEN
        DEST.LB := LOAD_QWORD(SRC);
        DEST.UB := LOAD_QWORD(SRC+8);
    ELSE
        DEST.LB := LOAD_DWORD_ZERO_EXT(SRC);
        DEST.UB := LOAD_DWORD_ZERO_EXT(SRC+4);
FI;

BNDMOV to memory:

IF 64-bit mode THEN
        DEST[63:0] := SRC.LB;
        DEST[127:64] := SRC.UB;
    ELSE
        DEST[31:0] := SRC.LB;
        DEST[63:32] := SRC.UB;
FI;

Intel C/C++ Compiler Intrinsic Equivalent:

BNDMOV void * _bnd_copy_ptr_bounds(const void *q, const void *r)

Flags Affected:

None.

Protected Mode Exceptions:

#UD:
	If the LOCK prefix is used but the destination is not a memory operand.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 67H prefix is not used and CS.D=0.
    If 67H prefix is used and CS.D=1.
#SS(0):
	If the memory operand effective address is outside the SS segment limit.
#GP(0):
	If the memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the destination operand points to a non-writable segment
    If the DS, ES, FS, or GS segment register contains a NULL segment selector.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while CPL is 3.
#PF(fault	code):
    If a page fault occurs.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used but the destination is not a memory operand.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.
#GP(0):
	If the memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS:
	If the memory operand effective address is outside the SS segment limit.

Virtual-8086 Mode Exceptions:

#UD:
	If the LOCK prefix is used but the destination is not a memory operand.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.
#GP(0):
	If the memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS(0):
	If the memory operand effective address is outside the SS segment limit.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while CPL is 3.
#PF(fault	code):
    If a page fault occurs.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#UD:
	If the LOCK prefix is used but the destination is not a memory operand.
    If ModRM.r/m and REX encodes BND4-BND15 when Intel MPX is enabled.
#SS(0):
	If the memory address referencing the SS segment is in a non-canonical form.
#GP(0):
	If the memory address is in a non-canonical form.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while CPL is 3.
#PF(fault	code):
    If a page fault occurs.


BNDSTX — Store Extended Bounds Using Address Translation

Opcode/Instruction	            Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 1B /r BNDSTX mib, bnd	    MR	    V/V	                    MPX	                Store the bounds in bnd and the pointer value in the index register of mib to a bound table entry (BTE) with address translation using the base of mib.

Instruction Operand Encoding:

Op/En	Operand 1	                                    Operand 2	    Operand 3
MR	    SIB.base (r): Address of pointer SIB.index(r)	ModRM:reg (r)	N/A

Description:

BNDSTX uses the linear address constructed from the displacement and base register of the SIB-addressing form of the memory operand (mib) to perform address translation to store to a bound table entry. The bounds in the source operand bnd are written to the lower and upper bounds in the BTE. The content of the index register of mib is written to the pointer value field in the BTE.

This instruction does not cause memory access to the linear address of mib nor the effective address referenced by the base, and does not read or write any flags.

Segment overrides apply to the linear address computation with the base of mib, and are used during address translation to generate the address of the bound table entry. By default, the address of the BTE is assumed to be linear address. There are no segmentation checks performed on the base of mib.

The base of mib will not be checked for canonical address violation as it does not access memory.

Any encoding of this instruction that does not specify base or index register will treat those registers as zero (constant). The reg-reg form of this instruction will remain a NOP.

The scale field of the SIB byte has no effect on these instructions and is ignored.

The bound register may be partially updated on memory faults. The order in which memory operands are loaded is implementation specific.

Operation:

base := mib.SIB.base ? mib.SIB.base + Disp: 0;
ptr_value := mib.SIB.index ? mib.SIB.index : 0;

Outside 64-bit Mode:

A_BDE[31:0] := (Zero_extend32(base[31:12] « 2) + (BNDCFG[31:12] «12 );
A_BT[31:0] := LoadFrom(A_BDE);
IF A_BT[0] equal 0 Then
    BNDSTATUS := A_BDE | 02H;
    #BR;
FI;
A_DEST[31:0] := (Zero_extend32(base[11:2] « 4) + (A_BT[31:2] « 2 ); // address of Bound table entry
A_DEST[8][31:0] := ptr_value;
A_DEST[0][31:0] := BND.LB;
A_DEST[4][31:0] := BND.UB;

In 64-bit Mode:

A_BDE[63:0] := (Zero_extend64(base[47+MAWA:20] « 3) + (BNDCFG[63:12] «12 );1
A_BT[63:0] := LoadFrom(A_BDE);
IF A_BT[0] equal 0 Then
    BNDSTATUS := A_BDE | 02H;
    #BR;
FI;
A_DEST[63:0] := (Zero_extend64(base[19:3] « 5) + (A_BT[63:3] « 3 ); // address of Bound table entry
A_DEST[16][63:0] := ptr_value;
A_DEST[0][63:0] := BND.LB;
A_DEST[8][63:0] := BND.UB;

Intel C/C++ Compiler Intrinsic Equivalent:

BNDSTX: _bnd_store_ptr_bounds(const void **ptr_addr, const void *ptr_val);

Flags Affected:

None.

Protected Mode Exceptions:

#BR:
	If the bound directory entry is invalid.
#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 67H prefix is not used and CS.D=0.
    If 67H prefix is used and CS.D=1.
#GP(0):
	If a destination effective address of the Bound Table entry is outside the DS segment limit.
    If DS register contains a NULL segment selector.
    If the destination operand points to a non-writable segment
#PF(fault	code): 
    If a page fault occurs.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.
#GP(0):
	If a destination effective address of the Bound Table entry is outside the DS segment limit.

Virtual-8086 Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If ModRM.r/m encodes BND4-BND7 when Intel MPX is enabled.
    If 16-bit addressing is used.
#GP(0):
	If a destination effective address of the Bound Table entry is outside the DS segment limit.
#PF(fault	code):
    If a page fault occurs.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

1. If CPL < 3, the supervisor MAWA (MAWAS) is used; this value is 0. If CPL = 3, the user MAWA (MAWAU) is used; this value is enumerated in CPUID.(EAX=07H,ECX=0H):ECX.MAWAU[bits 21:17]. See Appendix E.3.1 of Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1.

64-Bit Mode Exceptions:

#BR:
	If the bound directory entry is invalid.
#UD:
	If ModRM is RIP relative.
    If the LOCK prefix is used.
    If ModRM.r/m and REX encodes BND4-BND15 when Intel MPX is enabled.
#GP(0):
	If the memory address (A_BDE or A_BTE) is in a non-canonical form.
    If the destination operand points to a non-writable segment
#PF(fault	code):
    If a page fault occurs.



BOUND — Check Array Index Against Bounds

Opcode	Instruction	        Op/En	64-bit Mode	Compat/Leg Mode	Description
62 /r	BOUND r16, m16&16	RM	    Invalid	    Valid	        Check if r16 (array index) is within bounds specified by m16&16.
62 /r	BOUND r32, m32&32	RM	    Invalid	    Valid	        Check if r32 (array index) is within bounds specified by m32&32.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (r)	ModRM:r/m (r)	N/A	        N/A

Description:

BOUND determines if the first operand (array index) is within the bounds of an array specified the second operand (bounds operand). The array index is a signed integer located in a register. The bounds operand is a memory location that contains a pair of signed doubleword-integers (when the operand-size attribute is 32) or a pair of signed word-integers (when the operand-size attribute is 16). The first doubleword (or word) is the lower bound of the array and the second doubleword (or word) is the upper bound of the array. The array index must be greater than or equal to the lower bound and less than or equal to the upper bound plus the operand size in bytes. If the index is not within bounds, a BOUND range exceeded exception (#BR) is signaled. When this exception is generated, the saved return instruction pointer points to the BOUND instruction.

The bounds limit data structure (two words or doublewords containing the lower and upper limits of the array) is usually placed just before the array itself, making the limits addressable via a constant offset from the beginning of the array. Because the address of the array already will be present in a register, this practice avoids extra bus cycles to obtain the effective address of the array bounds.

This instruction executes as described in compatibility mode and legacy mode. It is not valid in 64-bit mode.

Operation:

IF 64bit Mode
    THEN
        #UD;
    ELSE
        IF (ArrayIndex < LowerBound OR ArrayIndex > UpperBound) THEN
        (* Below lower bound or above upper bound *)
            IF <equation for PL enabled> THEN BNDSTATUS := 0
            #BR;
        FI;
FI;

Flags Affected:

None.

Protected Mode Exceptions:

#BR:
	If the bounds test fails.
#UD:
	If second operand is not a memory location.
    If the LOCK prefix is used.
#GP(0):
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If the DS, ES, FS, or GS register contains a NULL segment selector.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
	If a page fault occurs.
#AC(0):
	If alignment checking is enabled and an unaligned memory reference is made while the current privilege level is 3.

Real-Address Mode Exceptions:

#BR:
	If the bounds test fails.
#UD:
	If second operand is not a memory location.
    If the LOCK prefix is used.
#GP:
	If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
#SS:
	If a memory operand effective address is outside the SS segment limit.

Virtual-8086 Mode Exceptions:

#BR:
	If the bounds test fails.
#UD:
	If second operand is not a memory location.
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

#UD	If in 64-bit mode.
