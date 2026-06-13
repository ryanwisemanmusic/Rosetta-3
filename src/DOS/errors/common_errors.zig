const std = @import("std");

pub const AssemblyError = error{
    operand_size_mismatch,
    register_size_mismatch,
    memory_to_memory_invalid_move,
    undefined_symbol,
    invalid_syscall_number,
    register_overflow,
    invalid_instruction,
    segmentation_fault,
    stack_overflow,
    stack_underflow,
    invalid_addressing_mode_for_mode,
    division_by_zero,
    invalid_immediate_value,
    alignment_error,
    invalid_effective_address,
    invalid_operand_type,
    invalid_register_name,
    invalid_mnemonic,
    label_already_defined,
    undefined_label,
    duplicate_symbol,
    invalid_port_access,
    invalid_interrupt_vector,
    real_mode_limit_violation,
    conventional_memory_violation,
    invalid_mcb_chain,
    a20_gate_error,
    invalid_far_call_target,
};

pub fn describe(err: AssemblyError) []const u8 {
    return switch (err) {
        error.operand_size_mismatch =>
        \\Operand size mismatch: source and destination must be the same width.
        \\  Example: MOV AX, BL  →  AX is 16-bit, BL is 8-bit
        \\  Fix:    MOV AX, BX  (both 16-bit)  or  MOV AL, BL  (both 8-bit)
        \\  Tip: 16-bit: AX, BX, CX, DX, SI, DI, BP, SP
        \\        8-bit:  AL, AH, BL, BH, CL, CH, DL, DH
        ,

        error.register_size_mismatch =>
        \\Register size mismatch: the register does not match the expected width.
        \\  Example: MOV AX, DH  →  AX is 16-bit, DH is 8-bit (invalid)
        \\  Fix: Match register sizes — 16-bit to 16-bit, 8-bit to 8-bit.
        \\  Tip: In DOS real mode, you mostly work with 16-bit and 8-bit registers.
        \\  Tip: Use MOVZX for zero-extension (386+), but many DOS programs target 8086.
        ,

        error.memory_to_memory_invalid_move =>
        \\Memory-to-memory move: MOV cannot have two memory operands.
        \\  Example: MOV [var1], [var2]  →  illegal
        \\  Fix: Use a register as intermediary:
        \\        MOV AX, [var2]
        \\        MOV [var1], AX
        \\  Tip: MOVSB/MOVSW use [DS:SI]→[ES:DI] for memory-to-memory block moves.
        ,

        error.undefined_symbol =>
        \\Undefined symbol: a label or variable reference was never defined.
        \\  Example: MOV AX, myVar  →  'myVar' is not declared
        \\  Fix: Declare the variable:  myVar dw 0
        \\  Fix: Check for typos. In DOS, many assemblers are case-insensitive but symbols must match.
        ,

        error.invalid_syscall_number =>
        \\Invalid interrupt service: the function number in AH/AX does not match a valid DOS/BIOS service.
        \\  Example: MOV AH, 0xFF; INT 21h  →  0xFF is not a valid DOS function
        \\  Fix: Common DOS services (INT 21h): 09h=print string, 4Ch=exit, 3Fh=read, 40h=write
        \\  Fix: Common BIOS services:
        \\        INT 10h / AH=00h: set video mode
        \\        INT 10h / AH=0Eh: write character (teletype)
        \\        INT 16h / AH=00h: read key
        \\  Tip: Always check AH before INT — it selects the specific service within the interrupt.
        ,

        error.register_overflow =>
        \\Register overflow: the result exceeds the register's capacity.
        \\  Example: SHL AX, 16  →  shifting a 16-bit register by 16 is undefined
        \\  Fix: Shift counts should be less than the register width (0-15 for 16-bit).
        \\  Tip: On 8086, shift count is taken from CL, not an immediate.
        ,

        error.invalid_instruction =>
        \\Invalid instruction: the mnemonic does not exist or is used incorrectly.
        \\  Example: MOVSB AX, BX  →  MOVSB takes no operands
        \\  Fix: MOVSB uses [DS:SI]→[ES:DI] implicitly with DF for direction.
        \\  Tip: Some 386+ instructions (MOVZX, MOVSX) are not available on 8086/8088.
        ,

        error.segmentation_fault =>
        \\General protection fault: the program accessed memory beyond segment limits or with wrong privileges.
        \\  Example: MOV AX, [BX] where DS:BX points beyond available RAM
        \\  Fix: Check that segment registers (DS, ES, SS) are set correctly.
        \\  Fix: In real mode, ensure addresses don't exceed 1 MB (0xFFFF:0xFFFF = 0x10FFEF, wraps on 8086).
        \\  Tip: DOS programs run in real mode — addresses are physical (segment:offset).
        ,

        error.stack_overflow =>
        \\Stack overflow: the stack segment has grown beyond its 64 KB limit or overlaps other data.
        \\  Example: Deep recursion in a DOS program with limited stack
        \\  Fix: Increase stack size in your linker script or use .STACK directive.
        \\  Tip: In real mode, SP is 16-bit, limiting the stack to 64 KB (SS segment).
        \\  Tip: Default DOS stack is typically 512-2048 bytes. It's easy to overflow!
        ,

        error.stack_underflow =>
        \\Stack underflow: more POP/RET than PUSH/CALL executed.
        \\  Example: POP AX without a matching PUSH earlier
        \\  Fix: Balance your stack operations:
        \\        PUSH BP
        \\        MOV  BP, SP
        \\        ... your code ...
        \\        POP  BP
        \\        RET
        \\  Tip: Mismatched stack operations are a common source of DOS crashes.
        ,

        error.invalid_addressing_mode_for_mode =>
        \\Invalid addressing mode: the addressing form is not valid in 16-bit real mode.
        \\  Example: MOV AX, [BX+SI*4]  →  16-bit mode does not support scaled index
        \\  Fix: In 16-bit real mode, valid forms are:
        \\        [BX+SI], [BX+DI], [BP+SI], [BP+DI]
        \\        [SI], [DI], [BX], [BP]
        \\  Tip: Scaled index ([index*scale]) is a 386+ protected mode feature.
        ,

        error.division_by_zero =>
        \\Division by zero: the divisor was zero when executing DIV or IDIV.
        \\  Example: DIV CX where CX = 0  →  triggers INT 0h (divide error)
        \\  Fix: Always check the divisor before division:
        \\        CMP CX, 0
        \\        JE   skip
        \\        DIV BX
        \\  skip:
        \\  Tip: In DOS, divide by zero triggers interrupt 0h, which typically crashes the program.
        ,

        error.invalid_immediate_value =>
        \\Invalid immediate value: the constant is too large for the instruction.
        \\  Example: ADD AX, 0x123456  →  exceeds 16-bit limit
        \\  Fix: 16-bit operations accept 16-bit immediates (0x0000 - 0xFFFF).
        \\  Tip: For larger values, load into a register first then operate.
        ,

        error.alignment_error =>
        \\Alignment error: a memory access requires alignment that the address does not meet.
        \\  Example: Moving a word to an odd address on 286+ (alignment check)
        \\  Fix: Word values should be at even addresses. Dword values at 4-byte boundaries.
        \\  Tip: On 8086, unaligned access works but is slower. On 286+, it causes a fault if AC flag is set.
        ,

        error.invalid_effective_address =>
        \\Invalid effective address: the computed address exceeds segment limits.
        \\  Example: MOV AX, [BX+0x10000] where BX is large  →  offset exceeds 64 KB segment
        \\  Fix: Ensure offsets stay within the 64 KB segment limit (0x0000 - 0xFFFF).
        \\  Tip: Use multiple segments if you need more than 64 KB of data.
        ,

        error.invalid_operand_type =>
        \\Invalid operand type: the operand does not match what the instruction expects.
        \\  Example: IDIV 5  →  IDIV requires a register or memory operand, not an immediate
        \\  Fix: Use IDIV CX (register) or IDIV [var] (memory).
        \\  Tip: Check the instruction reference for valid operand types.
        ,

        error.invalid_register_name =>
        \\Invalid register name: the register does not exist in 16-bit x86.
        \\  Example: MOV AX, EAX  →  EAX does not exist on 8086
        \\  Fix: Valid 16-bit registers: AX, BX, CX, DX, SI, DI, BP, SP
        \\  Fix: Valid 8-bit registers: AL, AH, BL, BH, CL, CH, DL, DH
        \\  Tip: 32-bit registers (EAX, etc.) are only available on 386+ processors.
        ,

        error.invalid_mnemonic =>
        \\Invalid mnemonic: the instruction name is not a valid x86 instruction.
        \\  Example: MUV AX, BX  →  'MUV' is not recognized
        \\  Fix: Check spelling: MUV→MOV, AD→ADD, SB→SUB, CMP→CMP
        \\  Tip: Most DOS assemblers (TASM, MASM) are case-insensitive for mnemonics.
        ,

        error.label_already_defined =>
        \\Label already defined: the same label name appears twice.
        \\  Example:
        \\        start:
        \\            ...
        \\        start:  ← error: 'start' already defined
        \\  Fix: Use unique label names or local labels.
        \\  Tip: In MASM/TASM, @@ is used for local labels that can be reused.
        ,

        error.undefined_label =>
        \\Undefined label: a jump or call target does not exist.
        \\  Example: JMP skip  →  no 'skip' label exists
        \\  Fix: Check the spelling and case of the label.
        \\  Tip: Forward references are allowed in most DOS assemblers.
        ,

        error.duplicate_symbol =>
        \\Duplicate symbol: a symbol name is defined multiple times.
        \\  Example:
        \\        count dw 0
        \\        ...
        \\        count dw 1  ← error: 'count' redefined
        \\  Fix: Remove one definition or use a different name.
        ,

        error.invalid_port_access =>
        \\Invalid port access: the I/O port address or access is invalid.
        \\  Example: IN AX, 0xFFFF  →  port 0xFFFF may not exist or be accessible
        \\  Fix: Valid ports are 0x0000 - 0xFFFF, but not all are readable.
        \\  Fix: Privileged ports (below 0x400 on some systems) require IOPL or ring 0.
        \\  Tip: Common ports: 0x60=keyboard, 0x3C0=VGA, 0x378=LPT1, 0x3F8=COM1
        ,

        error.invalid_interrupt_vector =>
        \\Invalid interrupt vector: the interrupt number is not defined or not usable.
        \\  Example: INT 0xFF  →  most systems don't have a handler at vector 0xFF
        \\  Fix: DOS/BIOS reserved interrupts:
        \\        00h: divide error       10h: video services
        \\        16h: keyboard           21h: DOS services
        \\        1Ah: system timer       33h: mouse
        \\  Tip: Vectors 00h-1Fh are CPU exceptions, 20h-3Fh are DOS/BIOS, 40h-FFh are available.
        \\  Tip: Install custom handlers with INT 21h / AH=25h (set interrupt vector).
        ,

        error.real_mode_limit_violation =>
        \\Real mode limit violation: the address exceeds the 1 MB real-mode address space.
        \\  Example: MOV AX, [0xFFFF:0x0010]  →  address = 0x100000 (1 MB + 16 bytes)
        \\  Fix: On 8086/8088, addresses wrap at 1 MB (the A20 gate is involved).
        \\  Fix: On 286+, the A20 gate can be enabled for HMA access.
        \\  Tip: The 20-bit address limit means segment:offset covers 0x00000 - 0x10FFEF (1 MB + 64 KB - 16).
        \\  Tip: Enabling A20 via port 0x92 or keyboard controller allows access to HMA.
        ,

        error.conventional_memory_violation =>
        \\Conventional memory violation: access conflicts with DOS or resident programs.
        \\  Example: Writing over the interrupt vector table at 0000:0000
        \\  Fix: Reserve memory via INT 21h / AH=48h (allocate memory block).
        \\  Fix: Do not overwrite memory below 0x600 (IVT + BIOS data area).
        \\  Tip: Conventional memory is 0x00000 - 0x9FFFF (640 KB). Above that is UMA (reserved).
        \\  Tip: The IVT lives at 0000:0000 - 0000:03FF (256 vectors × 4 bytes).
        ,

        error.invalid_mcb_chain =>
        \\Invalid MCB chain: the DOS Memory Control Block chain is corrupted.
        \\  Example: An MCB with an incorrect owner ID or invalid block size.
        \\  Fix: This typically indicates memory corruption from a buffer overflow.
        \\  Fix: Check your program for out-of-bounds writes.
        \\  Tip: MCBs are structures that DOS uses to track allocated memory blocks.
        \\  Tip: Use INT 21h / AH=48h (alloc), 49h (free), 4Ah (resize) for memory management.
        ,

        error.a20_gate_error =>
        \\A20 gate error: the A20 address line is not enabled when accessing high memory.
        \\  Example: Reading from 0x100000 (1 MB) when A20 is disabled wraps to 0x000000
        \\  Fix: Enable A20 via:
        \\        IN  AL, 0x92
        \\        OR  AL, 0x02
        \\        OUT 0x92, AL
        \\  Fix: Or use the keyboard controller (slow method) or BIOS INT 15h / AX=2401h.
        \\  Tip: The A20 gate was used for compatibility with 8086 wrap-around behavior.
        \\  Tip: HMA (High Memory Area, 0xFFFF:0x0010 = 0x10FFEF) is only accessible with A20 on.
        ,

        error.invalid_far_call_target =>
        \\Invalid far call target: the segment:offset for a FAR CALL/JMP is invalid.
        \\  Example: CALL 0x0000:0x0000  →  calls the IVT (system crash)
        \\  Fix: Ensure the target segment:offset points to valid code.
        \\  Fix: For CALL FAR, the target is segment:offset, e.g.:
        \\        CALL FAR PTR [function_ptr]
        \\  Tip: FAR jumps/calls change both CS and IP. Use them for inter-segment transfers.
        \\  Tip: RETF (far return) must match a FAR CALL.
        ,
    };
}
