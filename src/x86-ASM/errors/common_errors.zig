const std = @import("std");

pub const AssemblyError = error{
    operand_size_mismatch,
    register_size_mismatch,
    memory_to_memory_invalid_move,
    bad_macro,
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
    protected_mode_violation,
    segment_register_error,
    descriptor_table_error,
    invalid_segment_override,
};

pub fn describe(err: AssemblyError) []const u8 {
    return switch (err) {
        error.operand_size_mismatch =>
        \\Operand size mismatch: source and destination must be the same width.
        \\  Example: MOV EAX, BX  →  EAX is 32-bit, BX is 16-bit
        \\  Fix:    MOV EAX, EBX  (both 32-bit)  or  MOV AX, BX  (both 16-bit)
        \\  Tip: 32-bit = EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
        \\       16-bit = AX,  BX,  CX,  DX,  SI,  DI,  BP,  SP
        \\        8-bit = AL, AH, BL, BH, CL, CH, DL, DH
        ,

        error.register_size_mismatch =>
        \\Register size mismatch: the register you used does not match the expected bit width.
        \\  Example: MOVZX EAX, BL  →  correct (zero-extends 8-bit to 32-bit)
        \\  Example: MOV EAX, BH    →  valid (BH is 8-bit high byte of BX, EAX is 32-bit? No — this is fine actually)
        \\  Fix: Only MOVZX/MOVSX allow mixing sizes. Direct MOV requires same-size operands.
        \\  Tip: MOV  EAX, EBX  →  moves 32 bits. MOV AL, BL  →  moves 8 bits.
        ,

        error.memory_to_memory_invalid_move =>
        \\Memory-to-memory move: x86 does not allow MOV with two memory operands.
        \\  Example: MOV [var1], [var2]  →  illegal, both reference memory
        \\  Fix: Use a register as a temporary:
        \\        MOV EAX, [var2]
        \\        MOV [var1], EAX
        \\  Tip: String instructions (MOVSB/MOVSW/MOVSD) are exceptions.
        ,

        error.bad_macro =>
        \\Bad macro: a macro definition or invocation is malformed.
        \\  Example: %macro myMacro  (missing parameter count)
        \\      %macro myMacro 2  →  correct
        \\  Fix: Check the macro syntax for your assembler (NASM %macro / MASM MACRO).
        \\  Fix: Ensure the number of arguments matches the definition.
        ,

        error.undefined_symbol =>
        \\Undefined symbol: you referenced a label or variable that was never defined.
        \\  Example: MOV EAX, myVar  →  'myVar' was never declared
        \\  Fix: Check spelling — 'myVar' vs 'myvar', 'my_var', etc.
        \\  Fix: Declare the symbol:  myVar: dd 0
        \\  Fix: If defined in another file, make sure it is included or declared EXTERN.
        ,

        error.invalid_syscall_number =>
        \\Invalid syscall number: the value in EAX does not match any Linux x86 system call.
        \\  Example: MOV EAX, 999; INT 0x80  →  999 is not a valid syscall
        \\  Fix: Common Linux x86 syscalls: 1=exit, 3=read, 4=write
        \\  Fix: Check /usr/include/asm/unistd_32.h for the full list.
        \\  Tip: Arguments go in EBX, ECX, EDX, ESI, EDI, EBP.
        ,

        error.register_overflow =>
        \\Register overflow: operation result exceeds the register's capacity.
        \\  Example: SHL EAX, 32  →  shifting a 32-bit register by 32 is undefined
        \\  Fix: Shift counts should be less than the register width (shift & 0x1F for 32-bit).
        \\  Tip: The carry flag (CF) captures the last bit shifted out.
        ,

        error.invalid_instruction =>
        \\Invalid instruction: the instruction mnemonic does not exist or is used incorrectly.
        \\  Example: MOVSB AL, BL  →  MOVSB does not take operands
        \\  Fix: Check the instruction format in the Intel manual.
        \\  Fix: MOVSB uses [DS:SI]→[ES:DI] implicitly, not explicit operands.
        ,

        error.segmentation_fault =>
        \\Segmentation fault: your program accessed memory it does not own.
        \\  Example: MOV EAX, [0x0]  →  null pointer dereference
        \\  Fix: Check that pointers are initialized before dereferencing them.
        \\  Fix: Use a debugger to find the exact instruction causing the fault.
        \\  Tip: In 32-bit protected mode, addresses are virtual — make sure segments are set up.
        ,

        error.stack_overflow =>
        \\Stack overflow: the stack has grown beyond its allocated memory region.
        \\  Example: Deep recursion without a base case will push until overflow.
        \\  Fix: Check for infinite recursion or runaway PUSH/CALL instructions.
        \\  Tip: The stack grows downward in x86. ESP decreases on PUSH/CALL.
        ,

        error.stack_underflow =>
        \\Stack underflow: more POP/RET instructions executed than PUSH/CALL.
        \\  Example: POP EAX without a matching PUSH earlier in execution
        \\  Fix: Make sure each procedure has a balanced prologue and epilogue.
        \\  Fix: PUSH EBP / MOV EBP, ESP / ... / POP EBP / RET  is the standard frame.
        ,

        error.invalid_addressing_mode_for_mode =>
        \\Invalid addressing mode: the addressing form is not valid in 32-bit protected mode.
        \\  Example: MOV EAX, [EBX*3]  →  scale must be 1, 2, 4, or 8
        \\  Fix: Format: [base + index*scale + displacement]
        \\  Fix: Scale can only be 1, 2, 4, or 8. Base and index must be valid registers.
        \\  Tip: Allowed: [EAX], [EAX+EBX], [EAX+EBX*4], [EDI+0x100]
        ,

        error.division_by_zero =>
        \\Division by zero: the divisor was zero when executing DIV or IDIV.
        \\  Example: DIV ECX where ECX = 0
        \\  Fix: Always check the divisor before division:
        \\        CMP ECX, 0
        \\        JE   skip
        \\        DIV EBX
        \\  skip:
        \\  Tip: DIV is unsigned, IDIV is signed. Both trigger #DE on zero.
        ,

        error.invalid_immediate_value =>
        \\Invalid immediate value: the constant is too large or not valid for this instruction.
        \\  Example: ADD EAX, 0x123456789  →  exceeds 32 bits
        \\  Fix: 32-bit immediates are limited to 32 bits (0x00000000 - 0xFFFFFFFF).
        \\  Tip: Most instructions accept a sign-extended 8-bit or 32-bit immediate.
        ,

        error.alignment_error =>
        \\Alignment error: a memory access requires specific alignment not met by the address.
        \\  Example: MOVAPS [EAX], XMM0  →  EAX must be 16-byte aligned
        \\  Fix: Use MOVUPS for unaligned SSE access, or ensure proper alignment.
        \\  Tip: MOVDQA requires 16-byte alignment. Use MOVDQU for unaligned.
        ,

        error.invalid_effective_address =>
        \\Invalid effective address: the computed address is outside the valid range.
        \\  Example: MOV EAX, [ESP-100] where ESP < 100  →  underflow
        \\  Fix: Check your base/index register values before dereferencing.
        \\  Fix: Ensure DS segment limit is not exceeded.
        ,

        error.invalid_operand_type =>
        \\Invalid operand type: the operand does not match what the instruction expects.
        \\  Example: IDIV 5  →  IDIV needs a register or memory operand, not an immediate
        \\  Fix: Use IDIV ECX (register) or IDIV [var] (memory).
        \\  Tip: Check the instruction reference for allowed operand types.
        ,

        error.invalid_register_name =>
        \\Invalid register name: the register does not exist in x86.
        \\  Example: MOV EAX, XX0  →  'XX0' is not a register
        \\  Fix: Check spelling. Valid: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
        \\  Tip: Register names are case-insensitive in most assemblers.
        ,

        error.invalid_mnemonic =>
        \\Invalid mnemonic: the instruction name is not recognized.
        \\  Example: MUV EAX, EBX  →  'MUV' is not an instruction
        \\  Fix: Check for typos: MUV→MOV, AD→ADD, SB→SUB, CMP→CMP
        \\  Tip: Use 'nasm -e' to check if your assembler recognizes mnemonic.
        ,

        error.label_already_defined =>
        \\Label already defined: you used the same label name more than once.
        \\  Example:
        \\        loop:
        \\            ...
        \\        loop:  ← error: 'loop' already defined
        \\  Fix: Use unique label names throughout your program.
        \\  Fix: In NASM, use .local labels inside procedures to reuse common names.
        ,

        error.undefined_label =>
        \\Undefined label: a jump or call target label does not exist in your program.
        \\  Example: JNE not_found  →  no 'not_found' label exists
        \\  Fix: Check spelling of the label.
        \\  Fix: Make sure the target label exists in the source.
        \\  Tip: Forward references are allowed in NASM, but the label must exist.
        ,

        error.duplicate_symbol =>
        \\Duplicate symbol: a symbol name (variable or constant) is defined twice.
        \\  Example:
        \\        count: dd 0
        \\        ...
        \\        count: dd 1  ← error: 'count' redefined
        \\  Fix: Remove the duplicate, or use unique names.
        ,

        error.protected_mode_violation =>
        \\Protected mode violation: an operation is not allowed in 32-bit protected mode.
        \\  Example: MOV CR0, EAX without sufficient privilege level
        \\  Fix: Privileged instructions (LGDT, LIDT, MOV to CRx) require ring 0.
        \\  Tip: Most student code runs in ring 3 (user mode).
        ,

        error.segment_register_error =>
        \\Segment register error: an invalid segment register value or operation.
        \\  Example: MOV DS, 0  →  loading a null selector causes #GP in protected mode
        \\  Fix: Only load valid segment selectors into CS, DS, ES, FS, GS, SS.
        \\  Tip: In 32-bit protected mode, segments use selectors, not real-mode segment values.
        ,

        error.descriptor_table_error =>
        \\Descriptor table error: a segment descriptor or gate descriptor is invalid.
        \\  Example: A segment limit exceeded, or a descriptor with the wrong type was loaded.
        \\  Fix: Check GDT/LDT entries for proper base, limit, and access byte values.
        \\  Tip: The DPL (Descriptor Privilege Level) must match the CPL for data segment access.
        ,

        error.invalid_segment_override =>
        \\Invalid segment override: the segment override prefix is not valid in this context.
        \\  Example: CS segment override on a stack operation
        \\  Fix: Not all segment overrides are valid for all instructions.
        \\  Tip: Valid overrides: CS, DS, ES, FS, GS, SS. Some instructions ignore overrides.
        ,
    };
}
