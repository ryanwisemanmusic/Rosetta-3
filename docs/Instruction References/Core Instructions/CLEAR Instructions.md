CLAC — Clear AC Flag in EFLAGS Register

Opcode/Instruction	    Op / En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 01 CA CLAC	    ZO	    V/V	                    SMAP	            Clear the AC flag in the EFLAGS register.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Clears the AC flag bit in EFLAGS register. This disables any alignment checking of user-mode data accesses. Ifthe SMAP bit is set in the CR4 register, this disallows explicit supervisor-mode data accesses to user-mode pages.

This instruction's operation is the same in non-64-bit modes and 64-bit mode. Attempts to execute CLAC when CPL > 0 cause #UD.

Operation:

EFLAGS.AC := 0;

Flags Affected:

AC cleared. Other flags are unaffected.

Protected Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If the CPL > 0.
    If CPUID.(EAX=07H, ECX=0H):EBX.SMAP[bit 20] = 0.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If CPUID.(EAX=07H, ECX=0H):EBX.SMAP[bit 20] = 0.

Virtual-8086 Mode Exceptions:

#UD:
	The CLAC instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If the CPL > 0.
    If CPUID.(EAX=07H, ECX=0H):EBX.SMAP[bit 20] = 0.

64-Bit Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If the CPL > 0.
    If CPUID.(EAX=07H, ECX=0H):EBX.SMAP[bit 20] = 0.




CLC — Clear Carry Flag

Opcode	Instruction	    Op/En	64-bit Mode	Compat/Leg Mode	Description
F8	CLC	                ZO	    Valid	    Valid	        Clear CF flag.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Clears the CF flag in the EFLAGS register. Operation is the same in all modes.

Operation:

CF := 0;

Flags Affected:

The CF flag is set to 0. The OF, ZF, SF, AF, and PF flags are unaffected.

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.



CLC — Clear Carry Flag

Opcode	Instruction	    Op/En	64-bit Mode	Compat/Leg Mode	Description
F8	CLC	                ZO	    Valid	    Valid	        Clear CF flag.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Clears the CF flag in the EFLAGS register. Operation is the same in all modes.

Operation:

CF := 0;

Flags Affected:

The CF flag is set to 0. The OF, ZF, SF, AF, and PF flags are unaffected.

Exceptions (All Operating Modes):

#UD If the LOCK prefix is used.




CLD — Clear Direction Flag

Opcode	Instruction	    Op/En	64-bit Mode	Compat/Leg Mode	Description
FC	CLD	                ZO	    Valid	    Valid	        Clear DF flag.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Clears the DF flag in the EFLAGS register. When the DF flag is set to 0, string operations increment the index registers (ESI and/or EDI). Operation is the same in all modes.

Operation:

DF := 0;

Flags Affected:

The DF flag is set to 0. The CF, OF, ZF, SF, AF, and PF flags are unaffected.

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.




CLI — Clear Interrupt Flag

Opcode	Instruction	    Op/En	64-bit Mode	Compat/Leg Mode	Description
FA	CLI	                ZO	    Valid	    Valid	        Clear interrupt flag; interrupts disabled when interrupt flag cleared.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

In most cases, CLI clears the IF flag in the EFLAGS register and no other flags are affected. Clearing the IF flag causes the processor to ignore maskable external interrupts. The IF flag and the CLI and STI instruction have no effect on the generation of exceptions and NMI interrupts.

Operation is different in two modes defined as follows:

PVI mode (protected-mode virtual interrupts):
    CR0.PE = 1, EFLAGS.VM = 0, CPL = 3, and CR4.PVI = 1;
VME mode (virtual-8086 mode extensions): 
    CR0.PE = 1, EFLAGS.VM = 1, and CR4.VME = 1.
    If IOPL < 3 and either VME mode or PVI mode is active, CLI clears the VIF flag in the EFLAGS register, leaving IF unaffected.

Table 3-7 indicates the action of the CLI instruction depending on the processor operating mode, IOPL, and CPL.

Operation:

IF CR0.PE = 0
    THEN IF := 0; (* Reset Interrupt Flag *)
    ELSE
        IF IOPL ≥ CPL (* CPL = 3 if EFLAGS.VM = 1 *)
            THEN IF := 0; (* Reset Interrupt Flag *)
            ELSE
                IF VME mode OR PVI mode
                    THEN VIF := 0; (* Reset Virtual Interrupt Flag *)
                    ELSE #GP(0);
                FI;
        FI;
FI;

Flags Affected:

Either the IF flag or the VIF flag is cleared to 0. Other flags are unaffected.

Protected Mode Exceptions:

#GP(0):
	If CPL is greater than IOPL and PVI mode is not active.
    If CPL is greater than IOPL and less than 3.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used.

Virtual-8086 Mode Exceptions:

#GP(0):
	If IOPL is less than 3 and VME mode is not active.
#UD:
	If the LOCK prefix is used.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

Same exceptions as in protected mode.




CLRSSBSY — Clear Busy Flag in a Supervisor Shadow Stack Token

Opcode/Instruction	        Op / En	64/32 bit Mode Support	CPUID Feature Flag	Description
F3 0F AE /6 CLRSSBSY m64	M	    V/V	                    CET_SS	            Clear busy flag in supervisor shadow stack token reference by m64.

Instruction Operand Encoding:

Op/En	Tuple Type	Operand 1	        Operand 2	Operand 3	Operand 4
M	    N/A	        ModRM:r/m (r, w)	N/A	        N/A	        N/A

Description:

Clear busy flag in supervisor shadow stack token reference by m64. Subsequent to marking the shadow stack as not busy the SSP is loaded with value 0.

Operation:

IF (CR4.CET = 0)
    THEN #UD; FI;
IF (IA32_S_CET.SH_STK_EN = 0)
    THEN #UD; FI;
IF CPL > 0
    THEN GP(0); FI;
SSP_LA = Linear_Address(mem operand)
IF SSP_LA not aligned to 8 bytes
    THEN #GP(0); FI;
expected_token_value=SSP_LA|BUSY_BIT (*busybit-bitposition0-mustbeset*)
new_token_value = SSP_LA (* Clear the busy bit *)
IF shadow_stack_lock_cmpxchg8b(SSP_LA, new_token_value, expected_token_value) != expected_token_value
    invalid_token := 1; FI
(* Set the CF if invalid token was detected *)
RFLAGS.CF = (invalid_token == 1) ? 1 : 0;
RFLAGS.ZF,PF,AF,OF,SF := 0;
SSP := 0

Flags Affected:

CF is set if an invalid token was detected, else it is cleared. ZF, PF, AF, OF, and SF are cleared.

Protected Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If CR4.CET = 0.
    IF IA32_S_CET.SH_STK_EN = 0.
#GP(0):
	If memory operand linear address not aligned to 8 bytes.
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.
    If destination is located in a non-writeable segment.
    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.
    If CPL is not 0.
#SS(0):
	If a memory operand effective address is outside the SS segment limit.
#PF(fault-code):
	If a page fault occurs.

Real-Address Mode Exceptions:

#UD:
	The CLRSSBSY instruction is not recognized in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The CLRSSBSY instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

#UD:
	Same exceptions as in protected mode.
#GP(0):
	Same exceptions as in protected mode.
#PF(fault-code):
	If a page fault occurs.

64-Bit Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If CR4.CET = 0.
    IF IA32_S_CET.SH_STK_EN = 0.
#GP(0):
	If memory operand linear address not aligned to 8 bytes.
    If CPL is not 0.
    If the memory address is in a non-canonical form.
    If token is invalid.
#SS(0):
	If a memory address referencing the SS segment is in a non-canonical form.
#PF(fault-code):
	If a page fault occurs.



CLTS — Clear Task-Switched Flag in CR0

Opcode	Instruction	    Op/En	64-bit Mode	Compat/Leg Mode	Description
0F 06	CLTS	        ZO	    Valid	    Valid	        Clears TS flag in CR0.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Clears the task-switched (TS) flag in the CR0 register. This instruction is intended for use in operating-system procedures. It is a privileged instruction that can only be executed at a CPL of 0. It is allowed to be executed in real-address mode to allow initialization for protected mode.

The processor sets the TS flag every time a task switch occurs. The flag is used to synchronize the saving of FPU context in multitasking applications. See the description of the TS flag in the section titled “Control Registers” in Chapter 2 of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 3A, for more information about this flag.

CLTS operation is the same in non-64-bit modes and 64-bit mode.

See Chapter 26, “VMX Non-Root Operation,” of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 3C, for more information about the behavior of this instruction in VMX non-root operation.

Operation:

CR0.TS[bit 3] := 0;

Flags Affected:

The TS flag in CR0 register is cleared.

Protected Mode Exceptions:

#GP(0):
	If the current privilege level is not 0.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#UD:
	If the LOCK prefix is used.

Virtual-8086 Mode Exceptions:

#GP(0):
	CLTS is not recognized in virtual-8086 mode.
#UD:
	If the LOCK prefix is used.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#GP(0):
	If the CPL is greater than 0.
#UD:
	If the LOCK prefix is used.



CLUI — Clear User Interrupt Flag

Opcode/Instruction	    Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
F3 0F 01 EE CLUI	    ZO	    V/I	                    UINTR	            Clear user interrupt flag; user interrupts blocked when user interrupt flag cleared.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	    N/A	        N/A	        N/A	        N/A

Description:

CLUI clears the user interrupt flag (UIF). Its effect takes place immediately: a user interrupt cannot be delivered on the instruction boundary following CLUI.

An execution of CLUI inside a transactional region causes a transactional abort; the abort loads EAX as it would have had it been caused due to an execution of CLI.

Operation:

UIF := 0;

Flags Affected:

None.

Protected Mode Exceptions:

#UD:
	The CLUI instruction is not recognized in protected mode.

Real-Address Mode Exceptions:

#UD:
	The CLUI instruction is not recognized in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The CLUI instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

#UD:
	The CLUI instruction is not recognized in compatibility mode.

64-Bit Mode Exceptions:

#UD:
	If the LOCK prefix is used.
    If executed inside an enclave.
    If CR4.UINTR = 0.
    If CPUID.07H.0H:EDX.UINTR[bit 5] = 0.



FCLEX/FNCLEX — Clear Exceptions

Opcode:

Instruction	        64-Bit Mode	Compat/Leg Mode	Description
9B DB E2	FCLEX	Valid	    Valid	        Clear floating-point exception flags after checking for pending unmasked floating-point exceptions.
DB E2	FNCLEX1	    Valid	    Valid	        Clear floating-point exception flags without checking for pending unmasked floating-point exceptions.

1. See IA-32 Architecture Compatibility section below.

Description:

Clears the floating-point exception flags (PE, UE, OE, ZE, DE, and IE), the exception summary status flag (ES), the stack fault flag (SF), and the busy flag (B) in the FPU status word. The FCLEX instruction checks for and handles any pending unmasked floating-point exceptions before clearing the exception flags; the FNCLEX instruction does not.

The assembler issues two instructions for the FCLEX instruction (an FWAIT instruction followed by an FNCLEX instruction), and the processor executes each of these instructions separately. If an exception is generated for either of these instructions, the save EIP points to the instruction that caused the exception.

IA-32 Architecture Compatibility:

When operating a Pentium or Intel486 processor in MS-DOS* compatibility mode, it is possible (under unusual circumstances) for an FNCLEX instruction to be interrupted prior to being executed to handle a pending FPU exception. See the section titled “No-Wait FPU Instructions Can Get FPU Interrupt in Window” in Appendix D of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1, for a description of these circumstances. An FNCLEX instruction cannot be interrupted in this way on later Intel processors, except for the Intel QuarkTM X1000 processor.

This instruction affects only the x87 FPU floating-point exception flags. It does not affect the SIMD floating-point exception flags in the MXCSR register.

This instruction’s operation is the same in non-64-bit modes and 64-bit mode.

Operation:

FPUStatusWord[0:7] := 0;
FPUStatusWord[15] := 0;
FPU Flags Affected ¶

The PE, UE, OE, ZE, DE, IE, ES, SF, and B flags in the FPU status word are cleared. The C0, C1, C2, and C3 flags are undefined.

Floating-Point Exceptions:

None.

Protected Mode Exceptions:

#NM:
	CR0.EM[bit 2] or CR0.TS[bit 3] = 1.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as in protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as in protected mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

Same exceptions as in protected mode.