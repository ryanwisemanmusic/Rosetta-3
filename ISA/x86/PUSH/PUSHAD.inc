// PUSHAD.inc
// Auto-generated from: PUSH Instructions.md
// Instruction: PUSHAD — Push All 32-bit General-Purpose Registers

#ifndef X86_PUSHAD_INC
#define X86_PUSHAD_INC

// Table schema:
// X86_INST(opcode, mnemonic, operands, op_en, valid_64, valid_compat_legacy, description, operand_encoding, operation, flags, exceptions)

X86_INST(
    "60",
    "PUSHAD",
    "EAX, ECX, EDX, EBX, original ESP, EBP, ESI, EDI",
    "ZO",
    "Invalid",
    "Valid",
    "Push EAX, ECX, EDX, EBX, original ESP, EBP, ESI, and EDI.",
    "Operands: N/A",
    "IF 64-bit Mode THEN #UD; Temp := ESP; Push(EAX); Push(ECX); Push(EDX); Push(EBX); Push(Temp); Push(EBP); Push(ESI); Push(EDI).",
    "None",
    "Protected/compat: #SS if starting or ending stack address is outside stack segment; #PF; #AC at CPL3 if unaligned and alignment checking enabled; #UD on LOCK prefix. Real/v8086: #GP if SP/ESP contains 7,9,11,13,15; #UD on LOCK prefix. 64-bit: #UD."
)

#endif // X86_PUSHAD_INC
