// LOAD/LDMXCSR.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LDMXCSR.inc.
// Source document: LOAD Instructions(1).md
// Family section: LDMXCSR — Load MXCSR Register
// This file preserves the full x86 source contract for LDMXCSR, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LDMXCSR.inc"
x86_handler = "x86_ldmxcsr"
neon_lowering = "mxcsr_state_write"
lowering_kind = "simd_control_status_load"

name = "LDMXCSR"
family = "LDMXCSR"
category = "simd_control_status_load"
operation = "Load MXCSR Register"

source_section_title = "LDMXCSR — Load MXCSR Register"
source_mnemonics_in_section = ["LDMXCSR"]

implicit_reads = []
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LDMXCSR — Load MXCSR Register

Opcode/Instruction	                Op/En	64/32-bit Mode	    CPUID Feature Flag	    Description
NP 0F AE /2 LDMXCSR m32	            M	    V/V	                SSE	                    Load MXCSR register from m32.
VEX.LZ.0F.WIG AE /2 VLDMXCSR m32	M	    V/V	                AVX	                    Load MXCSR register from m32.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	Operand 3	Operand 4
M	    ModRM:r/m (r)	N/A	        N/A	        N/A

Description:

Loads the source operand into the MXCSR control/status register. The source operand is a 32-bit memory location. See “MXCSR Control and Status Register” in Chapter 10, of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1, for a description of the MXCSR register and its contents.

The LDMXCSR instruction is typically used in conjunction with the (V)STMXCSR instruction, which stores the contents of the MXCSR register in memory.

The default MXCSR value at reset is 1F80H.

If a (V)LDMXCSR instruction clears a SIMD floating-point exception mask bit and sets the corresponding exception flag bit, a SIMD floating-point exception will not be immediately generated. The exception will be generated only upon the execution of the next instruction that meets both conditions below:

the instruction must operate on an XMM or YMM register operand,
the instruction causes that particular SIMD floating-point exception to be reported.
This instruction’s operation is the same in non-64-bit modes and 64-bit mode.

If VLDMXCSR is encoded with VEX.L= 1, an attempt to execute the instruction encoded with VEX.L= 1 will cause an #UD exception.

Note: In VEX-encoded versions, VEX.vvvv is reserved and must be 1111b, otherwise instructions will #UD.

Operation:

MXCSR := m32;

C/C++ Compiler Intrinsic Equivalent:

_mm_setcsr(unsigned int i)

Numeric Exceptions:

None.

Other Exceptions:

See Table 2-22, “Type 5 Class Exception Conditions,” additionally:

#GP:
	For an attempt to set reserved bits in MXCSR.
#UD:
	If VEX.vvvv ≠ 1111B.
"""

semantic = """
Implement LDMXCSR according to source_contract.
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
