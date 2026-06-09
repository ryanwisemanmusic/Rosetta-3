SYSCALL — Fast System Call

Opcode	Instruction	Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 05	SYSCALL	    ZO	    Valid	        Invalid	            Fast call to privilege level 0 system procedures.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

SYSCALL invokes an OS system-call handler at privilege level 0. It does so by loading RIP from the IA32_LSTAR MSR (after saving the address of the instruction following SYSCALL into RCX). (The WRMSR instruction ensures that the IA32_LSTAR MSR always contain a canonical address.)

SYSCALL also saves RFLAGS into R11 and then masks RFLAGS using the IA32_FMASK MSR (MSR address C0000084H); specifically, the processor clears in RFLAGS every bit corresponding to a bit that is set in the IA32_FMASK MSR.

SYSCALL loads the CS and SS selectors with values derived from bits 47:32 of the IA32_STAR MSR. However, the CS and SS descriptor caches are not loaded from the descriptors (in GDT or LDT) referenced by those selectors. Instead, the descriptor caches are loaded with fixed values. See the Operation section for details. It is the responsibility of OS software to ensure that the descriptors (in GDT or LDT) referenced by those selector values correspond to the fixed values loaded into the descriptor caches; the SYSCALL instruction does not ensure this correspondence.

The SYSCALL instruction does not save the stack pointer (RSP). If the OS system-call handler will change the stack pointer, it is the responsibility of software to save the previous value of the stack pointer. This might be done prior to executing SYSCALL, with software restoring the stack pointer with the instruction following SYSCALL (which will be executed after SYSRET). Alternatively, the OS system-call handler may save the stack pointer and restore it before executing SYSRET.

When shadow stacks are enabled at a privilege level where the SYSCALL instruction is invoked, the SSP is saved to the IA32_PL3_SSP MSR. If shadow stacks are enabled at privilege level 0, the SSP is loaded with 0. Refer to Chapter 6, “Procedure Calls, Interrupts, and Exceptions‚” and Chapter 17, “Control-flow Enforcement Technology (CET)‚” in the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1, for additional CET details.

Instruction ordering. Instructions following a SYSCALL may be fetched from memory before earlier instructions complete execution, but they will not execute (even speculatively) until all instructions prior to the SYSCALL have completed execution (the later instructions may execute before data stored by the earlier instructions have become globally visible).

Operation:

IF (CS.L ≠ 1 ) or (IA32_EFER.LMA ≠ 1) or (IA32_EFER.SCE ≠ 1)
(* Not in 64-Bit Mode or SYSCALL/SYSRET not enabled in IA32_EFER *)
    THEN #UD;
FI;
RCX := RIP; (* Will contain address of next instruction *)
RIP := IA32_LSTAR;
R11 := RFLAGS;
RFLAGS := RFLAGS AND NOT(IA32_FMASK);
CS.Selector := IA32_STAR[47:32] AND FFFCH (* Operating system provides CS; RPL forced to 0 *)
(* Set rest of CS to a fixed value *)
CS.Base := 0;
                (* Flat segment *)
CS.Limit := FFFFFH;
                (* With 4-KByte granularity, implies a 4-GByte limit *)
CS.Type := 11;
                (* Execute/read code, accessed *)
CS.S := 1;
CS.DPL := 0;
CS.P := 1;
CS.L := 1;
                (* Entry is to 64-bit mode *)
CS.D := 0;
                (* Required if CS.L = 1 *)
CS.G := 1;
                (* 4-KByte granularity *)
IF ShadowStackEnabled(CPL)
    THEN (* adjust so bits 63:N get the value of bit N–1, where N is the CPU’s maximum linear-address width *)
        IA32_PL3_SSP := LA_adjust(SSP);
            (* With shadow stacks enabled the system call is supported from Ring 3 to Ring 0 *)
            (* OS supporting Ring 0 to Ring 0 system calls or Ring 1/2 to ring 0 system call *)
            (* Must preserve the contents of IA32_PL3_SSP to avoid losing ring 3 state *)
FI;
CPL := 0;
IF ShadowStackEnabled(CPL)
    SSP := 0;
FI;
IF EndbranchEnabled(CPL)
    IA32_S_CET.TRACKER = WAIT_FOR_ENDBRANCH
    IA32_S_CET.SUPPRESS = 0
FI;
SS.Selector := IA32_STAR[47:32] + 8;
                (* SS just above CS *)
(* Set rest of SS to a fixed value *)
SS.Base := 0;
                (* Flat segment *)
SS.Limit := FFFFFH;
                (* With 4-KByte granularity, implies a 4-GByte limit *)
SS.Type := 3;
                (* Read/write data, accessed *)
SS.S := 1;
SS.DPL := 0;
SS.P := 1;
SS.B := 1;
                (* 32-bit stack segment *)
SS.G := 1;
                (* 4-KByte granularity *)

Flags Affected:

All.

Protected Mode Exceptions:

#UD:
	The SYSCALL instruction is not recognized in protected mode.

Real-Address Mode Exceptions:

#UD:
	The SYSCALL instruction is not recognized in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The SYSCALL instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

#UD:
	The SYSCALL instruction is not recognized in compatibility mode.

64-Bit Mode Exceptions:

#UD:
	If IA32_EFER.SCE = 0.
If the LOCK prefix is used.





SYSENTER — Fast System Call

Opcode	Instruction	Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 34	SYSENTER	ZO	    Valid	        Valid	            Fast call to privilege level 0 system procedures.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Executes a fast call to a level 0 system procedure or routine. SYSENTER is a companion instruction to SYSEXIT. The instruction is optimized to provide the maximum performance for system calls from user code running at privilege level 3 to operating system or executive procedures running at privilege level 0.

When executed in IA-32e mode, the SYSENTER instruction transitions the logical processor to 64-bit mode; otherwise, the logical processor remains in protected mode.

Prior to executing the SYSENTER instruction, software must specify the privilege level 0 code segment and code entry point, and the privilege level 0 stack segment and stack pointer by writing values to the following MSRs:

IA32_SYSENTER_CS (MSR address 174H) — The lower 16 bits of this MSR are the segment selector for the privilege level 0 code segment. This value is also used to determine the segment selector of the privilege level 0 stack segment (see the Operation section). This value cannot indicate a null selector.
IA32_SYSENTER_EIP (MSR address 176H) — The value of this MSR is loaded into RIP (thus, this value references the first instruction of the selected operating procedure or routine). In protected mode, only bits 31:0 are loaded.
IA32_SYSENTER_ESP (MSR address 175H) — The value of this MSR is loaded into RSP (thus, this value contains the stack pointer for the privilege level 0 stack). This value cannot represent a non-canonical address. In protected mode, only bits 31:0 are loaded.
These MSRs can be read from and written to using RDMSR/WRMSR. The WRMSR instruction ensures that the IA32_SYSENTER_EIP and IA32_SYSENTER_ESP MSRs always contain canonical addresses.

While SYSENTER loads the CS and SS selectors with values derived from the IA32_SYSENTER_CS MSR, the CS and SS descriptor caches are not loaded from the descriptors (in GDT or LDT) referenced by those selectors. Instead, the descriptor caches are loaded with fixed values. See the Operation section for details. It is the responsibility of OS software to ensure that the descriptors (in GDT or LDT) referenced by those selector values correspond to the fixed values loaded into the descriptor caches; the SYSENTER instruction does not ensure this correspondence.

The SYSENTER instruction can be invoked from all operating modes except real-address mode.

The SYSENTER and SYSEXIT instructions are companion instructions, but they do not constitute a call/return pair. When executing a SYSENTER instruction, the processor does not save state information for the user code (e.g., the instruction pointer), and neither the SYSENTER nor the SYSEXIT instruction supports passing parameters on the stack.

To use the SYSENTER and SYSEXIT instructions as companion instructions for transitions between privilege level 3 code and privilege level 0 operating system procedures, the following conventions must be followed:

The segment descriptors for the privilege level 0 code and stack segments and for the privilege level 3 code and stack segments must be contiguous in a descriptor table. This convention allows the processor to compute the segment selectors from the value entered in the SYSENTER_CS_MSR MSR.
The fast system call “stub” routines executed by user code (typically in shared libraries or DLLs) must save the required return IP and processor state information if a return to the calling procedure is required. Likewise, the operating system or executive procedures called with SYSENTER instructions must have access to and use this saved return and state information when returning to the user code.
The SYSENTER and SYSEXIT instructions were introduced into the IA-32 architecture in the Pentium II processor. The availability of these instructions on a processor is indicated with the SYSENTER/SYSEXIT present (SEP) feature

flag returned to the EDX register by the CPUID instruction. An operating system that qualifies the SEP flag must also qualify the processor family and model to ensure that the SYSENTER/SYSEXIT instructions are actually present. For example:

IF CPUID SEP bit is set

THEN IF (Family = 6) and (Model < 3) and (Stepping < 3)

THEN

SYSENTER/SYSEXIT_Not_Supported; FI;

ELSE

SYSENTER/SYSEXIT_Supported; FI;

FI;

When the CPUID instruction is executed on the Pentium Pro processor (model 1), the processor returns a the SEP flag as set, but does not support the SYSENTER/SYSEXIT instructions.

When shadow stacks are enabled at privilege level where SYSENTER instruction is invoked, the SSP is saved to the IA32_PL3_SSP MSR. If shadow stacks are enabled at privilege level 0, the SSP is loaded with 0. Refer to Chapter 6, “Procedure Calls, Interrupts, and Exceptions‚” and Chapter 17, “Control-flow Enforcement Technology (CET)‚” in the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1, for additional CET details.

Instruction ordering. Instructions following a SYSENTER may be fetched from memory before earlier instructions complete execution, but they will not execute (even speculatively) until all instructions prior to the SYSENTER have completed execution (the later instructions may execute before data stored by the earlier instructions have become globally visible).

Operation:

IF CR0.PE = 0 OR IA32_SYSENTER_CS[15:2] = 0 THEN #GP(0); FI;
RFLAGS.VM := 0;
                    (* Ensures protected mode execution *)
RFLAGS.IF := 0;
                    (* Mask interrupts *)
IF in IA-32e mode
    THEN
        RSP := IA32_SYSENTER_ESP;
        RIP := IA32_SYSENTER_EIP;
ELSE
        ESP := IA32_SYSENTER_ESP[31:0];
        EIP := IA32_SYSENTER_EIP[31:0];
FI;
CS.Selector := IA32_SYSENTER_CS[15:0] AND
                    FFFCH;
                    (* Operating system provides CS; RPL forced to 0 *)
(* Set rest of CS to a fixed value *)
CS.Base := 0;
                    (* Flat segment *)
CS.Limit := FFFFFH;
                    (* With 4-KByte granularity, implies a 4-GByte limit *)
CS.Type := 11;
                    (* Execute/read code, accessed *)
CS.S := 1;
CS.DPL := 0;
CS.P := 1;
IF in IA-32e mode
    THEN
        CS.L := 1;
                    (* Entry is to 64-bit mode *)
        CS.D := 0;
                    (* Required if CS.L = 1 *)
    ELSE
        CS.L := 0;
        CS.D := 1;
                    (* 32-bit code segment*)
FI;
CS.G := 1;
                    (* 4-KByte granularity *)
IF ShadowStackEnabled(CPL)
    THEN
        IF IA32_EFER.LMA = 0
            THEN IA32_PL3_SSP := SSP;
            ELSE (* adjust so bits 63:N get the value of bit N–1, where N is the CPU’s maximum linear-address width *)
                IA32_PL3_SSP := LA_adjust(SSP);
        FI;
FI;
CPL := 0;
IF ShadowStackEnabled(CPL)
    SSP := 0;
FI;
IF EndbranchEnabled(CPL)
    IA32_S_CET.TRACKER = WAIT_FOR_ENDBRANCH
    IA32_S_CET.SUPPRESS = 0
FI;
SS.Selector := CS.Selector + 8;
                    (* SS just above CS *)
(* Set rest of SS to a fixed value *)
SS.Base := 0;
                    (* Flat segment *)
SS.Limit := FFFFFH;
                    (* With 4-KByte granularity, implies a 4-GByte limit *)
SS.Type := 3;
                    (* Read/write data, accessed *)
SS.S := 1;
SS.DPL := 0;
SS.P := 1;
SS.B := 1;
                    (* 32-bit stack segment*)
SS.G := 1;
                    (* 4-KByte granularity *)

Flags Affected:

VM, IF (see Operation above).

Protected Mode Exceptions:

#GP(0)	If IA32_SYSENTER_CS[15:2] = 0.
#UD	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#GP	The SYSENTER instruction is not recognized in real-address mode.
#UD	If the LOCK prefix is used.

Virtual-8086 Mode Exceptions:

Same exceptions as in protected mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

Same exceptions as in protected mode.






SYSEXIT — Fast Return from Fast System Call

Opcode	        Instruction	Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 35	        SYSEXIT	    ZO	    Valid	        Valid	            Fast return to privilege level 3 user code.
REX.W + 0F 35	SYSEXIT	    ZO	    Valid	        Valid	            Fast return to 64-bit mode privilege level 3 user code.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

Executes a fast return to privilege level 3 user code. SYSEXIT is a companion instruction to the SYSENTER instruction. The instruction is optimized to provide the maximum performance for returns from system procedures executing at protections levels 0 to user procedures executing at protection level 3. It must be executed from code executing at privilege level 0.

With a 64-bit operand size, SYSEXIT remains in 64-bit mode; otherwise, it either enters compatibility mode (if the logical processor is in IA-32e mode) or remains in protected mode (if it is not).

Prior to executing SYSEXIT, software must specify the privilege level 3 code segment and code entry point, and the privilege level 3 stack segment and stack pointer by writing values into the following MSR and general-purpose registers:

IA32_SYSENTER_CS (MSR address 174H) — Contains a 32-bit value that is used to determine the segment selectors for the privilege level 3 code and stack segments (see the Operation section)
RDX — The canonical address in this register is loaded into RIP (thus, this value references the first instruction to be executed in the user code). If the return is not to 64-bit mode, only bits 31:0 are loaded.
ECX — The canonical address in this register is loaded into RSP (thus, this value contains the stack pointer for the privilege level 3 stack). If the return is not to 64-bit mode, only bits 31:0 are loaded.
The IA32_SYSENTER_CS MSR can be read from and written to using RDMSR and WRMSR.

While SYSEXIT loads the CS and SS selectors with values derived from the IA32_SYSENTER_CS MSR, the CS and SS descriptor caches are not loaded from the descriptors (in GDT or LDT) referenced by those selectors. Instead, the descriptor caches are loaded with fixed values. See the Operation section for details. It is the responsibility of OS software to ensure that the descriptors (in GDT or LDT) referenced by those selector values correspond to the fixed values loaded into the descriptor caches; the SYSEXIT instruction does not ensure this correspondence.

The SYSEXIT instruction can be invoked from all operating modes except real-address mode and virtual-8086 mode.

The SYSENTER and SYSEXIT instructions were introduced into the IA-32 architecture in the Pentium II processor. The availability of these instructions on a processor is indicated with the SYSENTER/SYSEXIT present (SEP) feature flag returned to the EDX register by the CPUID instruction. An operating system that qualifies the SEP flag must also qualify the processor family and model to ensure that the SYSENTER/SYSEXIT instructions are actually present. For example:

IF CPUID SEP bit is set

THEN IF (Family = 6) and (Model < 3) and (Stepping < 3)

THEN

SYSENTER/SYSEXIT_Not_Supported; FI;

ELSE

SYSENTER/SYSEXIT_Supported; FI;

FI;

When the CPUID instruction is executed on the Pentium Pro processor (model 1), the processor returns a the SEP flag as set, but does not support the SYSENTER/SYSEXIT instructions.

When shadow stacks are enabled at privilege level 3 the instruction loads SSP with value from IA32_PL3_SSP MSR. Refer to Chapter 6, “Interrupt and Exception Handling‚” and Chapter 17, “Control-flow Enforcement Technology (CET)‚” in the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1, for additional CET details.

Instruction ordering. Instructions following a SYSEXIT may be fetched from memory before earlier instructions complete execution, but they will not execute (even speculatively) until all instructions prior to the SYSEXIT have completed execution (the later instructions may execute before data stored by the earlier instructions have become globally visible).

Operation:

IF IA32_SYSENTER_CS[15:2] = 0 OR CR0.PE = 0 OR CPL ≠ 0 THEN #GP(0); FI;
IF operand size is 64-bit
    THEN (* Return to 64-bit mode *)
        RSP := RCX;
        RIP := RDX;
    ELSE (* Return to protected mode or compatibility mode *)
        RSP := ECX;
        RIP := EDX;
FI;
IF operand size is 64-bit (* Operating system provides CS; RPL forced to 3 *)
    THEN CS.Selector := IA32_SYSENTER_CS[15:0] + 32;
    ELSE CS.Selector := IA32_SYSENTER_CS[15:0] + 16;
FI;
CS.Selector := CS.Selector OR 3;
            (* RPL forced to 3 *)
(* Set rest of CS to a fixed value *)
CS.Base := 0;
            (* Flat segment *)
CS.Limit := FFFFFH;
            (* With 4-KByte granularity, implies a 4-GByte limit *)
CS.Type := 11;
            (* Execute/read code, accessed *)
CS.S := 1;
CS.DPL := 3;
CS.P := 1;
IF operand size is 64-bit
    THEN (* return to 64-bit mode *)
        CS.L := 1;
            (* 64-bit code segment *)
        CS.D := 0;
    ELSE (* return to protected mode or compatibility mode *)
        CS.L := 0;
        CS.D := 1;
            (* 32-bit code segment*)
FI;
CS.G := 1;
            (* 4-KByte granularity *)
CPL := 3;
IF ShadowStackEnabled(CPL)
    THEN SSP := IA32_PL3_SSP;
FI;
SS.Selector := CS.Selector + 8;
            (* SS just above CS *)
(* Set rest of SS to a fixed value *)
SS.Base := 0;
            (* Flat segment *)
SS.Limit := FFFFFH;
            (* With 4-KByte granularity, implies a 4-GByte limit *)
SS.Type := 3;
            (* Read/write data, accessed *)
SS.S := 1;
SS.DPL := 3;
SS.P := 1;
SS.B := 1;
            (* 32-bit stack segment*)
SS.G := 1; (* 4-KByte granularity *)

Flags Affected:

None.

Protected Mode Exceptions:

#GP(0):
	If IA32_SYSENTER_CS[15:2] = 0.
    If CPL ≠ 0.
#UD:
	If the LOCK prefix is used.

Real-Address Mode Exceptions:

#GP:
	The SYSEXIT instruction is not recognized in real-address mode.
#UD:
	If the LOCK prefix is used.

Virtual-8086 Mode Exceptions:

#GP(0):
	The SYSEXIT instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

#GP(0):
	If IA32_SYSENTER_CS = 0.
    If CPL ≠ 0.
    If RCX or RDX contains a non-canonical address.
#UD:
	If the LOCK prefix is used.







SYSRET — Return From Fast System Call

Opcode	        Instruction	Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
0F 07	        SYSRET	    ZO	    Valid	        Invalid	            Return to compatibility mode from fast system call.
REX.W + 0F 07	SYSRET	    ZO	    Valid	        Invalid	            Return to 64-bit mode from fast system call.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	    N/A	        N/A	        N/A	        N/A

Description:

SYSRET is a companion instruction to the SYSCALL instruction. It returns from an OS system-call handler to user code at privilege level 3. It does so by loading RIP from RCX and loading RFLAGS from R11.1 With a 64-bit operand size, SYSRET remains in 64-bit mode; otherwise, it enters compatibility mode and only the low 32 bits of the registers are loaded.

SYSRET loads the CS and SS selectors with values derived from bits 63:48 of the IA32_STAR MSR. However, the CS and SS descriptor caches are not loaded from the descriptors (in GDT or LDT) referenced by those selectors. Instead, the descriptor caches are loaded with fixed values. See the Operation section for details. It is the responsibility of OS software to ensure that the descriptors (in GDT or LDT) referenced by those selector values correspond to the fixed values loaded into the descriptor caches; the SYSRET instruction does not ensure this correspondence.

The SYSRET instruction does not modify the stack pointer (ESP or RSP). For that reason, it is necessary for software to switch to the user stack. The OS may load the user stack pointer (if it was saved after SYSCALL) before executing SYSRET; alternatively, user code may load the stack pointer (if it was saved before SYSCALL) after receiving control from SYSRET.

If the OS loads the stack pointer before executing SYSRET, it must ensure that the handler of any interrupt or exception delivered between restoring the stack pointer and successful execution of SYSRET is not invoked with the user stack. It can do so using approaches such as the following:

External interrupts. The OS can prevent an external interrupt from being delivered by clearing EFLAGS.IF before loading the user stack pointer.
Nonmaskable interrupts (NMIs). The OS can ensure that the NMI handler is invoked with the correct stack by using the interrupt stack table (IST) mechanism for gate 2 (NMI) in the IDT (see Section 6.14.5, “Interrupt Stack Table,” in Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 3A).
General-protection exceptions (#GP). The SYSRET instruction generates #GP(0) if the value of RCX is not canonical. The OS can address this possibility using one or more of the following approaches:
Confirming that the value of RCX is canonical before executing SYSRET.
Confirming that the value of RCX is canonical before executing SYSRET.
Using paging to ensure that the SYSCALL instruction will never save a non-canonical value into RCX.
Using paging to ensure that the SYSCALL instruction will never save a non-canonical value into RCX.
Using the IST mechanism for gate 13 (#GP) in the IDT.
Using the IST mechanism for gate 13 (#GP) in the IDT.
When shadow stacks are enabled at privilege level 3 the instruction loads SSP with value from IA32_PL3_SSP MSR. Refer to Chapter 6, “Procedure Calls, Interrupts, and Exceptions‚” and Chapter 17, “Control-flow Enforcement Technology (CET)‚” in the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1, for additional CET details.

1. Regardless of the value of R11, the RF and VM flags are always 0 in RFLAGS after execution of SYSRET. In addition, all reserved bits in RFLAGS retain the fixed values.
Instruction ordering. Instructions following a SYSRET may be fetched from memory before earlier instructions complete execution, but they will not execute (even speculatively) until all instructions prior to the SYSRET have completed execution (the later instructions may execute before data stored by the earlier instructions have become globally visible).

Operation:

IF (CS.L ≠ 1 ) or (IA32_EFER.LMA ≠ 1) or (IA32_EFER.SCE ≠ 1)
(* Not in 64-Bit Mode or SYSCALL/SYSRET not enabled in IA32_EFER *)
    THEN #UD; FI;
IF (CPL ≠ 0) THEN #GP(0); FI;
IF (operand size is 64-bit)
    THEN (* Return to 64-Bit Mode *)
        IF (RCX is not canonical) THEN #GP(0);
        RIP := RCX;
    ELSE (* Return to Compatibility Mode *)
        RIP := ECX;
FI;
RFLAGS := (R11 & 3C7FD7H) | 2; (*
                Clear RF, VM, reserved bits; set bit 1 *)
IF (operand size is 64-bit)
    THEN CS.Selector := IA32_STAR[63:48]+16;
    ELSE CS.Selector := IA32_STAR[63:48];
FI;
CS.Selector := CS.Selector OR 3;
            (* RPL forced to 3 *)
(* Set rest of CS to a fixed value *)
CS.Base := 0;
            (* Flat segment *)
CS.Limit := FFFFFH;
            (* With 4-KByte granularity, implies a 4-GByte limit *)
CS.Type := 11;
            (* Execute/read code, accessed *)
CS.S := 1;
CS.DPL := 3;
CS.P := 1;
IF (operand size is 64-bit)
    THEN (* Return to 64-Bit Mode *)
        CS.L := 1;
            (* 64-bit code segment *)
        CS.D := 0;
            (* Required if CS.L = 1 *)
    ELSE (* Return to Compatibility Mode *)
        CS.L := 0;
            (* Compatibility mode *)
        CS.D := 1;
            (* 32-bit code segment *)
FI;
CS.G := 1;
            (* 4-KByte granularity *)
CPL := 3;
IF ShadowStackEnabled(CPL)
    SSP := IA32_PL3_SSP;
FI;
SS.Selector := (IA32_STAR[63:48]+8) OR 3;
            (* RPL forced to 3 *)
(* Set rest of SS to a fixed value *)
SS.Base := 0;
            (* Flat segment *)
SS.Limit := FFFFFH;
            (* With 4-KByte granularity, implies a 4-GByte limit *)
SS.Type := 3;
            (* Read/write data, accessed *)
SS.S := 1;
SS.DPL := 3;
SS.P := 1;
SS.B := 1;
            (* 32-bit stack segment*)
SS.G := 1;
            (* 4-KByte granularity *)

Flags Affected:

All.

Protected Mode Exceptions:

#UD:
	The SYSRET instruction is not recognized in protected mode.

Real-Address Mode Exceptions:

#UD:
	The SYSRET instruction is not recognized in real-address mode.

Virtual-8086 Mode Exceptions:

#UD:
	The SYSRET instruction is not recognized in virtual-8086 mode.

Compatibility Mode Exceptions:

#UD:
	The SYSRET instruction is not recognized in compatibility mode.

64-Bit Mode Exceptions:

#UD:
	If IA32_EFER.SCE = 0.
    If the LOCK prefix is used.
#GP(0):
	If CPL ≠ 0.
    If the return is to 64-bit mode and RCX contains a non-canonical address.