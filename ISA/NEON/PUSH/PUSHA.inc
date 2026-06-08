// PUSH/PUSHA.inc
// ARM64/NEON mirror generated from ISA/x86/PUSH/PUSHA.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

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

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "PUSH/PUSHA.inc"
x86_handler = "x86_pusha"
neon_lowering = "arm64_documented_contract_from_x86_pusha"
lowering_kind = "arm64_documented_contract"

// PUSHA.inc
// Auto-generated from: PUSH Instructions.md
// Instruction: PUSHA — Push All 16-bit General-Purpose Registers

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

neon_register_model = """
The x86 architectural operands, implicit state, and memory effects are read from the Rosette register file and emulated system state. ARM64 lowering must preserve the documented source contract before using native scalar or NEON instructions.
"""

neon_flag_model = """
The ARM64 lowering preserves the x86 flag behavior listed in flags_read, flags_written, flags_affected, flags_model, or source_contract. NZCV may be used internally only when repacked into x86 architectural flags.
"""

neon_assembly = """
// PUSHA: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
