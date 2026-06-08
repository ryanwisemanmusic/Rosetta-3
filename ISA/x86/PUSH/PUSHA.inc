// PUSHA.inc
// Auto-generated from: PUSH Instructions.md
// Instruction: PUSHA — Push All 16-bit General-Purpose Registers

// Canonical table metadata for registry-wide .inc validation.
name = "PUSHA"
encodings = [
  { opcode = "see preserved_source_contract", form = "PUSHA documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_pusha" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]
semantic = """
PUSHA: preserve the operation and form-specific semantic blocks.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
"""

#ifndef X86_PUSHA_INC
#define X86_PUSHA_INC

// Table schema:
// X86_INST(opcode, mnemonic, operands, op_en, valid_64, valid_compat_legacy, description, operand_encoding, operation, flags, exceptions)

X86_INST(
    "60",
    "PUSHA",
    "AX, CX, DX, BX, original SP, BP, SI, DI",
    "ZO",
    "Invalid",
    "Valid",
    "Push AX, CX, DX, BX, original SP, BP, SI, and DI.",
    "Operands: N/A",
    "IF 64-bit Mode THEN #UD; Temp := SP; Push(AX); Push(CX); Push(DX); Push(BX); Push(Temp); Push(BP); Push(SI); Push(DI).",
    "None",
    "Protected/compat: #SS if starting or ending stack address is outside stack segment; #PF; #AC at CPL3 if unaligned and alignment checking enabled; #UD on LOCK prefix. Real/v8086: #GP if SP/ESP contains 7,9,11,13,15; #UD on LOCK prefix. 64-bit: #UD."
)

#endif // X86_PUSHA_INC
