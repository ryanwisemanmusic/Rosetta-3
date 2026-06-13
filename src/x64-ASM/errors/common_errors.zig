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
    invalid_addressing_mode,
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
    canonical_address_violation,
    non_canonical_address,
    invalid_64bit_immediate,
    missing_rip_relative_override,
};

pub fn describe(err: AssemblyError) []const u8 {
    return switch (err) {
        error.operand_size_mismatch =>
        \\Operand size mismatch: source and destination must be the same width.
        \\  Example: MOV RAX, EBX  →  RAX is 64-bit, EBX is 32-bit
        \\  Fix:    MOV RAX, RBX  (both 64-bit)  or  MOV EAX, EBX  (both 32-bit)
        \\  Tip: 64-bit: RAX, RBX, RCX, RDX, RSI, RDI, RBP, RSP, R8..R15
        \\       32-bit: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP, R8D..R15D
        \\       16-bit: AX,  BX,  CX,  DX,  SI,  DI,  BP,  SP,  R8W..R15W
        \\        8-bit: AL, BL, CL, DL, SIL, DIL, BPL, SPL, R8B..R15B
        ,

        error.register_size_mismatch =>
        \\Register size mismatch: the register does not match the expected width for this operation.
        \\  Example: MOV RAX, AX  →  mixing 64-bit destination with 16-bit source (invalid)
        \\  Fix: Use MOVZX or MOVSX if you need to move a smaller value into a larger register:
        \\        MOVZX RAX, AX  (zero-extend AX into RAX)
        \\  Tip: In x86-64, direct MOV requires both operands to be the same size.
        ,

        error.memory_to_memory_invalid_move =>
        \\Memory-to-memory move: x86-64 does not allow MOV with two memory operands.
        \\  Example: MOV [var1], [var2]  →  illegal, both reference memory
        \\  Fix: Use a register as a temporary:
        \\        MOV RAX, [var2]
        \\        MOV [var1], RAX
        \\  Tip: Only string instructions (MOVSB/MOVSW/MOVSD/MOVSQ) do memory-to-memory.
        ,

        error.undefined_symbol =>
        \\Undefined symbol: the assembler cannot find a label or variable you referenced.
        \\  Example: MOV RAX, myVar  →  'myVar' was never declared
        \\  Fix: Check for typos — assembly is case-sensitive about symbol names.
        \\  Fix: Declare the symbol:  myVar: dq 0
        \\  Fix: If defined in another file, use EXTERN myVar to import it.
        ,

        error.invalid_syscall_number =>
        \\Invalid syscall number: the value in RAX does not match any Linux x86-64 syscall.
        \\  Example: MOV RAX, 999; SYSCALL  →  999 is not a valid syscall
        \\  Fix: Common Linux x86-64 syscalls:
        \\         0  = read       1  = write       60 = exit
        \\         2  = open       3  = close       9  = mmap
        \\  Tip: Arguments go in RDI, RSI, RDX, R10, R8, R9 (not RBX/RCX like x86).
        \\  Tip: Check /usr/include/x86_64-linux-gnu/asm/unistd_64.h for the full list.
        ,

        error.register_overflow =>
        \\Register overflow: the operation would exceed the register's capacity.
        \\  Example: SHL RAX, 64  →  shifting a 64-bit register by 64 is undefined
        \\  Fix: Shift amount must be less than the register width (mod 64 for 64-bit).
        \\  Tip: The CPU uses only the lower 6 bits of the shift count (0-63).
        ,

        error.invalid_instruction =>
        \\Invalid instruction: the mnemonic does not exist in x86-64 or is misused.
        \\  Example: MOVSB RAX, RBX  →  MOVSB does not take explicit operands
        \\  Fix: MOVSB uses [RSI]→[RDI] implicitly with DF controlling direction.
        \\  Tip: Some x86 instructions (like AAA/DAA) are invalid in 64-bit mode.
        ,

        error.segmentation_fault =>
        \\Segmentation fault: your program accessed memory it does not own.
        \\  Example: MOV RAX, [0x0]  →  dereferencing a null pointer
        \\  Fix: Check that all pointers are initialized before dereferencing.
        \\  Fix: Ensure buffers are large enough — out-of-bounds access causes SIGSEGV.
        \\  Tip: Use a debugger (gdb, lldb) to find the exact faulting instruction.
        ,

        error.stack_overflow =>
        \\Stack overflow: the stack has grown beyond its allocated region.
        \\  Example: Unbounded recursion without a base case.
        \\  Fix: Check for infinite recursion or runaway PUSH/CALL instructions.
        \\  Tip: The stack grows downward in x86-64. RSP decreases on PUSH/CALL.
        \\  Tip: The default Linux stack limit is often 8 MB (ulimit -s).
        ,

        error.stack_underflow =>
        \\Stack underflow: more values were popped than pushed.
        \\  Example: Two POPs but only one PUSH earlier in execution
        \\  Fix: Make sure every POP has a corresponding PUSH.
        \\  Fix: Ensure function prologue and epilogue are balanced:
        \\        push rbp
        \\        mov  rbp, rsp
        \\        ... your code ...
        \\        pop  rbp
        \\        ret
        ,

        error.invalid_addressing_mode =>
        \\Invalid addressing mode: the memory addressing form is not valid.
        \\  Example: MOV RAX, [RAX*3]  →  scale factor must be 1, 2, 4, or 8
        \\  Fix: Format: [base + index*scale + displacement]
        \\  Fix: Scale can only be 1, 2, 4, or 8.
        \\  Tip: Valid examples:
        \\        [RAX], [RAX+RBX], [RAX+RBX*8], [RDI+0x100], [rel myVar]
        ,

        error.division_by_zero =>
        \\Division by zero: the divisor was zero when executing DIV or IDIV.
        \\  Example: DIV RCX where RCX = 0
        \\  Fix: Always check the divisor before dividing:
        \\        CMP RCX, 0
        \\        JE   skip_division
        \\        DIV RBX
        \\  skip_division:
        \\  Tip: DIV is unsigned (RDX:RAX / operand). IDIV is signed.
        ,

        error.invalid_immediate_value =>
        \\Invalid immediate value: the constant is too large for this instruction.
        \\  Example: ADD RAX, 0x123456789ABC  →  exceeds sign-extended 32-bit limit
        \\  Fix: Most x86-64 ALU instructions only accept 32-bit sign-extended immediates.
        \\  Fix: Use MOV RAX, 0x123456789ABC first, then ADD RAX, RBX.
        \\  Tip: MOV is the only instruction that can take a full 64-bit immediate.
        ,

        error.alignment_error =>
        \\Alignment error: a memory address does not meet the alignment requirement.
        \\  Example: MOVAPS [RAX], XMM0  →  RAX must be 16-byte aligned
        \\  Fix: Use MOVUPS for unaligned SSE access, or align your data.
        \\  Fix: Declare with ALIGN 16:  .align 16  myVar: dq 0
        \\  Tip: ALIGN directive in NASM:  ALIGN 16
        ,

        error.invalid_effective_address =>
        \\Invalid effective address: the computed address is out of valid range.
        \\  Example: MOV RAX, [RSP-100] where RSP < 100  →  underflow
        \\  Fix: Check your base/index register values before dereferencing.
        \\  Tip: In 64-bit mode, addresses must be canonical (bits 48-63 match bit 47).
        ,

        error.invalid_operand_type =>
        \\Invalid operand type: the operand does not match what the instruction expects.
        \\  Example: IDIV 5  →  IDIV requires a register or memory operand, not an immediate
        \\  Fix: Use IDIV RCX (register) or IDIV [var] (memory).
        \\  Tip: Check the Intel manual for the instruction's operand requirements.
        ,

        error.invalid_register_name =>
        \\Invalid register name: the specified register does not exist in x86-64.
        \\  Example: MOV RAX, XX0  →  'XX0' is not a register
        \\  Fix: Valid GPRs: RAX, RBX, RCX, RDX, RSI, RDI, RBP, RSP, R8..R15
        \\  Sub-registers: EAX, AX, AL, AH, EBX, BX, BL, BH, ECX, CX, CL, CH, etc.
        \\  R8..R15 extended: R8D (32-bit), R8W (16-bit), R8B (8-bit)
        \\  Tip: Register names are case-insensitive in most assemblers.
        ,

        error.invalid_mnemonic =>
        \\Invalid mnemonic: the instruction name is not a valid x86-64 instruction.
        \\  Example: MUV RAX, RBX  →  'MUV' is not an instruction
        \\  Fix: Check for typos: MUV→MOV, AD→ADD, SB→SUB, CMP→CMP
        \\  Fix: Some x86 instructions (AAA, DAA, BOUND) are not available in 64-bit mode.
        \\  Tip: Use 'nasm -e' to verify mnemonic recognition.
        ,

        error.label_already_defined =>
        \\Label already defined: you used the same label name twice.
        \\  Example:
        \\        loop:
        \\            ...
        \\        loop:  ← error: 'loop' already defined
        \\  Fix: Use unique label names. In NASM, use local labels (.label) inside procedures.
        \\  Tip: NASM local labels:  proc_name: ... .loop: ...  (resets with each global label)
        ,

        error.undefined_label =>
        \\Undefined label: you referenced a jump/call target that does not exist.
        \\  Example: JNE not_found  →  no 'not_found' label anywhere in your code
        \\  Fix: Check spelling and case. Labels are case-sensitive.
        \\  Fix: If the label is forward-referenced, it must still be defined somewhere.
        \\  Tip: Use 'nasm -l listing.txt' to see if labels resolve correctly.
        ,

        error.duplicate_symbol =>
        \\Duplicate symbol: a symbol name (constant or variable) is defined twice.
        \\  Example:
        \\        count: dq 0
        \\        ...
        \\        count: dq 1  ← error: 'count' redefined
        \\  Fix: Remove the duplicate, or rename one of them.
        ,

        error.canonical_address_violation =>
        \\Canonical address violation: bits 48-63 of the address must match bit 47.
        \\  Example: MOV RAX, 0xFF80000000000000  →  valid kernel-space address
        \\  Example: MOV RAX, 0x0000800000000000  →  invalid (non-canonical)
        \\  Fix: User-space addresses:  0x0000000000000000 - 0x00007FFFFFFFFFFF
        \\  Fix: Kernel addresses:       0xFFFF800000000000 - 0xFFFFFFFFFFFFFFFF
        \\  Tip: The gap between these ranges is non-canonical and cannot be used.
        ,

        error.non_canonical_address =>
        \\Non-canonical address: the address falls in the canonical hole of x86-64.
        \\  Example: MOV RAX, [0x0000800000000000]  →  in the non-canonical gap
        \\  Fix: Ensure addresses are in valid user space (0x0 - 0x7FFFFFFFFFFF).
        \\  Tip: x86-64 implements 48-bit virtual addresses, sign-extended to 64 bits.
        \\  Tip: User addresses must have bit 47 = 0. Kernel addresses have bit 47 = 1.
        ,

        error.invalid_64bit_immediate =>
        \\Invalid 64-bit immediate: most x86-64 instructions cannot take a full 64-bit immediate.
        \\  Example: ADD RAX, 0x123456789ABC  →  only 32-bit sign-extended immediates allowed
        \\  Fix: Only MOV RAX, imm64 accepts a full 64-bit immediate.
        \\  Fix: For other operations:
        \\        MOV RAX, 0x123456789ABC
        \\        ADD RAX, RBX   (if that was the intended operation)
        \\  Tip: MOV is the only instruction with a 64-bit immediate encoding.
        ,

        error.missing_rip_relative_override =>
        \\Missing RIP-relative override: in x86-64, global data access should use RIP-relative.
        \\  Example: MOV EAX, [myVar]  →  defaults to absolute addressing (may fail)
        \\  Fix: MOV EAX, [rel myVar]  →  uses RIP-relative addressing
        \\  Fix: Add 'default rel' at the top of your NASM file to set RIP-relative as default.
        \\  Tip: RIP-relative is required for position-independent code (PIC/PIE).
        ,
    };
}
