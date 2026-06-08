# LEAVE.inc
# Auto-generated instruction table for Rosette/Rosetta 3 ISA mapping.
# Source: LEAVE — High Level Procedure Exit
# Instruction: LEAVE
# Category: Control Flow / Stack Frame / Procedure Exit

instruction "LEAVE" {
    isa              = "x86"
    mnemonic         = "LEAVE"
    family           = "procedure_exit"
    category         = "stack_frame"
    summary          = "Release current stack frame by setting stack pointer to frame pointer, then popping previous frame pointer."

    encodings = [
        {
            opcode          = "C9"
            instruction     = "LEAVE"
            op_en           = "ZO"
            operands        = []
            mode_64         = "Valid"
            mode_compat_leg = "Valid"
            description     = "Set SP to BP, then pop BP."
            stack_address_size = 16
            operand_size       = 16
            action          = "SP := BP; BP := Pop16();"
        },
        {
            opcode          = "C9"
            instruction     = "LEAVE"
            op_en           = "ZO"
            operands        = []
            mode_64         = "N.E."
            mode_compat_leg = "Valid"
            description     = "Set ESP to EBP, then pop EBP."
            stack_address_size = 32
            operand_size       = 32
            action          = "ESP := EBP; EBP := Pop32();"
        },
        {
            opcode          = "C9"
            instruction     = "LEAVE"
            op_en           = "ZO"
            operands        = []
            mode_64         = "Valid"
            mode_compat_leg = "N.E."
            description     = "Set RSP to RBP, then pop RBP."
            stack_address_size = 64
            operand_size       = 64
            action          = "RSP := RBP; RBP := Pop64();"
        }
    ]

    operand_encoding = [
        {
            op_en     = "ZO"
            operand_1 = "N/A"
            operand_2 = "N/A"
            operand_3 = "N/A"
            operand_4 = "N/A"
        }
    ]

    inputs = [
        "BP/EBP/RBP",
        "SS:SP/SS:ESP/RSP memory stack top",
        "StackAddressSize",
        "OperandSize"
    ]

    outputs = [
        "SP/ESP/RSP",
        "BP/EBP/RBP"
    ]

    flags_read = []
    flags_written = []
    flags_affected = "None"

    semantics = {
        description = """
LEAVE releases the stack frame created by ENTER or an equivalent function prologue.
It first copies the frame pointer into the stack pointer, discarding local stack-frame
allocation. It then pops the saved caller frame pointer from the stack.
A RET commonly follows LEAVE.
"""

        pseudocode = """
if StackAddressSize == 32:
    ESP = EBP
elif StackAddressSize == 64:
    RSP = RBP
elif StackAddressSize == 16:
    SP = BP

if OperandSize == 32:
    EBP = Pop32()
elif OperandSize == 64:
    RBP = Pop64()
elif OperandSize == 16:
    BP = Pop16()
"""

        notes = [
            "In 64-bit mode, default operation size is 64 bits.",
            "In 64-bit mode, 32-bit operation cannot be encoded.",
            "LEAVE itself does not return; RET performs the actual control transfer.",
            "The stack pop width is controlled by operand size.",
            "The stack pointer assignment is controlled by stack-address size."
        ]
    }

    lowering = {
        arm64_strategy = "stack_frame_teardown"
        preferred_sequence = """
// 64-bit canonical lowering:
SP = RBP
RBP = load64(SP)
SP = SP + 8

// 32-bit compatibility lowering:
ESP = EBP
EBP = load32(SS:ESP)
ESP = ESP + 4

// 16-bit compatibility lowering:
SP = BP
BP = load16(SS:SP)
SP = SP + 2
"""
        hazards = [
            "Preserve exact x86 stack width behavior.",
            "Do not treat LEAVE as RET.",
            "Validate stack/canonical faults before architectural update when modeling precise exceptions.",
            "Use SS segment rules for legacy/compatibility stack references."
        ]
    }

    mode_behavior = {
        real_address_mode = {
            valid = true
            faults = [
                "#GP if EBP/BP points outside effective address space 0..FFFFH",
                "#UD if LOCK prefix is used"
            ]
        }

        protected_mode = {
            valid = true
            faults = [
                "#SS(0) if EBP points outside current stack segment limit",
                "#PF(fault-code) if page fault occurs",
                "#AC(0) if alignment checking enabled and CPL = 3 with unaligned memory reference",
                "#UD if LOCK prefix is used"
            ]
        }

        virtual_8086_mode = {
            valid = true
            faults = [
                "#GP(0) if EBP/BP points outside effective address space 0..FFFFH",
                "#PF(fault-code) if page fault occurs",
                "#AC(0) if alignment checking enabled and unaligned memory reference occurs",
                "#UD if LOCK prefix is used"
            ]
        }

        compatibility_mode = {
            valid = true
            faults = [
                "Same exceptions as protected mode"
            ]
        }

        mode_64bit = {
            valid = true
            default_operand_size = 64
            cannot_encode_32bit_operation = true
            faults = [
                "#SS(0) if stack address is non-canonical",
                "#AC(0) if alignment checking enabled and CPL = 3 with unaligned memory reference",
                "#UD if LOCK prefix is used"
            ]
        }
    }

    exceptions = {
        protected_mode = [
            "#SS(0): EBP points to a location not within current stack segment limits.",
            "#PF(fault-code): Page fault occurs.",
            "#AC(0): Alignment checking enabled and unaligned memory reference at CPL 3.",
            "#UD: LOCK prefix used."
        ]

        real_address_mode = [
            "#GP: EBP/BP points outside effective address space 0..FFFFH.",
            "#UD: LOCK prefix used."
        ]

        virtual_8086_mode = [
            "#GP(0): EBP/BP points outside effective address space 0..FFFFH.",
            "#PF(fault-code): Page fault occurs.",
            "#AC(0): Alignment checking enabled and unaligned memory reference occurs.",
            "#UD: LOCK prefix used."
        ]

        compatibility_mode = [
            "Same exceptions as protected mode."
        ]

        mode_64bit = [
            "#SS(0): Stack address is non-canonical.",
            "#AC(0): Alignment checking enabled and unaligned memory reference at CPL 3.",
            "#UD: LOCK prefix used."
        ]
    }

    tests = [
        {
            name = "leave_16"
            initial = "BP=0x1000; [SS:0x1000]=0x2222"
            expected = "SP=0x1002; BP=0x2222"
        },
        {
            name = "leave_32"
            initial = "EBP=0x1000; [SS:0x1000]=0x22222222"
            expected = "ESP=0x1004; EBP=0x22222222"
        },
        {
            name = "leave_64"
            initial = "RBP=0x1000; [0x1000]=0x2222222222222222"
            expected = "RSP=0x1008; RBP=0x2222222222222222"
        }
    ]
}
