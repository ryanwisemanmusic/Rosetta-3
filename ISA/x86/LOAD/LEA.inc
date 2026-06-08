// LOAD/LEA.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LEA.inc.
// Source document: LOAD Instructions(1).md
// Family section: LEA — Load Effective Address
// This file preserves the full x86 source contract for LEA, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LEA.inc"
x86_handler = "x86_lea"
neon_lowering = "arm64_address_calculation_no_memory_load"
lowering_kind = "address_generation"

name = "LEA"
family = "LEA"
category = "address_generation"
operation = "Load Effective Address"

source_section_title = "LEA — Load Effective Address"
source_mnemonics_in_section = ["LEA"]

implicit_reads = []
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LEA — Load Effective Address

Opcode	        Instruction	    Op/En	64-Bit Mode	    Compat/Leg Mode	    Description
8D /r	        LEA r16,m	    RM	    Valid	        Valid	            Store effective address for m in register r16.
8D /r	        LEA r32,m	    RM	    Valid	        Valid	            Store effective address for m in register r32.
REX.W + 8D /r	LEA r64,m	    RM	    Valid	        N.E.	            Store effective address for m in register r64.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A	        N/A

Description:

Computes the effective address of the second operand (the source operand) and stores it in the first operand (destination operand). The source operand is a memory address (offset part) specified with one of the processors addressing modes; the destination operand is a general-purpose register. The address-size and operand-size attributes affect the action performed by this instruction, as shown in the following table. The operand-size attribute of the instruction is determined by the chosen register; the address-size attribute is determined by the attribute of the code segment.

Operand Size	Address Size	Action Performed
16	            16	            16-bit effective address is calculated and stored in requested 16-bit register destination.
16	            32	            32-bit effective address is calculated. The lower 16 bits of the address are stored in the requested 16-bit register destination.
32	            16	            16-bit effective address is calculated. The 16-bit address is zero-extended and stored in the requested 32-bit register destination.
32	            32	            32-bit effective address is calculated and stored in the requested 32-bit register destination.
Table 3-54. Non-64-bit Mode LEA Operation with Address and Operand Size Attributes

Different assemblers may use different algorithms based on the size attribute and symbolic reference of the source operand.

In 64-bit mode, the instruction’s destination operand is governed by operand size attribute, the default operand size is 32 bits. Address calculation is governed by address size attribute, the default address size is 64-bits. In 64-bit mode, address size of 16 bits is not encodable. See Table 3-55.

Operand Size	Address Size	Action Performed
16	            32	            32-bit effective address is calculated (using 67H prefix). The lower 16 bits of the address are stored in the requested 16-bit register destination (using 66H prefix).
16	            64	            64-bit effective address is calculated (default address size). The lower 16 bits of the address are stored in the requested 16-bit register destination (using 66H prefix).
32	            32	            32-bit effective address is calculated (using 67H prefix) and stored in the requested 32-bit register destination.
32	            64	            64-bit effective address is calculated (default address size) and the lower 32 bits of the address are stored in the requested 32-bit register destination.
64	            32	            32-bit effective address is calculated (using 67H prefix), zero-extended to 64-bits, and stored in the requested 64-bit register destination (using REX.W).
64	            64	            64-bit effective address is calculated (default address size) and all 64-bits of the address are stored in the requested 64-bit register destination (using REX.W).
Table 3-55. 64-bit Mode LEA Operation with Address and Operand Size Attributes

Operation:

IF OperandSize = 16 and AddressSize = 16
    THEN
        DEST := EffectiveAddress(SRC); (* 16-bit address *)
    ELSE IF OperandSize = 16 and AddressSize = 32
        THEN
            temp := EffectiveAddress(SRC); (* 32-bit address *)
            DEST := temp[0:15]; (* 16-bit address *)
        FI;
    ELSE IF OperandSize = 32 and AddressSize = 16
        THEN
            temp := EffectiveAddress(SRC); (* 16-bit address *)
            DEST := ZeroExtend(temp); (* 32-bit address *)
        FI;
    ELSE IF OperandSize = 32 and AddressSize = 32
        THEN
            DEST := EffectiveAddress(SRC); (* 32-bit address *)
        FI;
    ELSE IF OperandSize = 16 and AddressSize = 64
        THEN
            temp := EffectiveAddress(SRC); (* 64-bit address *)
            DEST := temp[0:15]; (* 16-bit address *)
        FI;
    ELSE IF OperandSize = 32 and AddressSize = 64
        THEN
            temp := EffectiveAddress(SRC); (* 64-bit address *)
            DEST := temp[0:31]; (* 16-bit address *)
        FI;
    ELSE IF OperandSize = 64 and AddressSize = 64
        THEN
            DEST := EffectiveAddress(SRC); (* 64-bit address *)
        FI;
FI;

Flags Affected:

None.

Protected Mode Exceptions:

#UD:
	If source operand is not a memory location.
    If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as in protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as in protected mode.

Compatibility Mode Exceptions:

Same exceptions as in protected mode.

64-Bit Mode Exceptions:

Same exceptions as in protected mode.
"""

semantic = """
Implement LEA according to source_contract.
Decode opcode, prefixes, ModRM, operand size, address size, CPUID feature gates, privilege gates, and mode restrictions exactly as described.
Perform architectural reads/writes exactly as the Intel-style operation section specifies.
Do not collapse this instruction into a generic load if source_contract requires descriptor validation, segment-register hidden-cache updates, MXCSR validation, AMX tile configuration, Key Locker state, string-index update, or fence ordering.
"""

arm64_lowering_contract = """
Rosette/Rosetta lowering must mirror the x86 architectural side effects, not merely emit a native load.
Where host ARM64 lacks the x86 architectural facility, route through the emulator/system-state model and raise the matching x86 exception.
For memory operands, run the x86 effective-address, segment, canonicality, alignment, paging, and access checks before host memory access.
For vector/string forms, preserve width, zeroing/unmodified upper-lane behavior, implicit operands, and DF-controlled index update.
For privileged/system forms, require CPL/feature checks before mutating emulated descriptor or control state.
"""

neon_notes = [
  "The complete source section is embedded above so no LOAD-related behavior from the Markdown is dropped.",
  "If this instruction is unsupported by the current Rosette runtime, the decoder should still recognize it and raise the documented x86 exception or unsupported-instruction path.",
  "Runtime ABI validation checks the x86 source table shape, mode restrictions, exception list, implicit operands, and ARM64 lowering shape."
]

abi_contract = ["x86_table_shape", "source_contract_preserved", "arm64_lowering_shape", "full_scope_preserved"]
