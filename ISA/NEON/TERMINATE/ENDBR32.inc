// TERMINATE/ENDBR32.inc
// ARM64/NEON mirror generated from ISA/x86/TERMINATE/ENDBR32.inc.

semantic = """
ENDBR32: preserve the operation and form-specific semantic blocks.
Category: terminate_branch.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "TERMINATE/ENDBR32.inc"
x86_handler = "x86_endbr32"
neon_lowering = "arm64_endbr32"
lowering_kind = "arm64_documented_contract"

name = "ENDBR32"
aliases = []
category = "terminate_branch"
feature = "CET_IBT"
element_type = "control_flow"
element_size = 32

encodings = [
  { opcode = "F3 0F 1E FB", form = "ENDBR32", op_en = "ZO", feature = "CET_IBT", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

lanes = { xmm = 0, ymm = 0 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = [
  "#UD if LOCK prefix, #UD if CET not enabled"
]

semantic_general = """
IF EndbranchEnabled(CPL) & (IA32_EFER.LMA = 0 | (IA32_EFER.LMA=1 & CS.L = 0)
    IF CPL = 3
        THEN
            IA32_U_CET.TRACKER = IDLE
            IA32_U_CET.SUPPRESS = 0
        ELSE
            IA32_S_CET.TRACKER = IDLE
            IA32_S_CET.SUPPRESS = 0
    FI;
FI;
"""

handler = "x86_endbr32"
jit_lowering = "arm64_endbr32"
fallback = "zig_endbr32"

neon_register_model = """
ENDBR32 is a CET tracking instruction with no ARM64 equivalent. Stubbed as documented contract; no register modification.
"""

neon_flag_model = """
No x86 flags modified by ENDBR32.
"""

neon_assembly = """
// NEON lowering: nop (CET tracking not available on ARM64; stubbed)
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
