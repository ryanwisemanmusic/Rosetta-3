// CLEAR/FCLEX.inc
// ARM64/NEON mirror generated from ISA/x86/CLEAR/FCLEX.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CLEAR/FCLEX.inc"
x86_handler = "x86_fclex"
neon_lowering = "arm64_fclex"
lowering_kind = "arm64_documented_contract"

name = "FCLEX"
aliases = ["FNCLEX"]
category = "x87_fpu"
feature = "8086"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "9B DB E2", form = "FCLEX", op_en = "ZO", feature = "8086", vector_length = 0, encoding = "legacy" },
  { opcode = "DB E2", form = "FNCLEX", op_en = "ZO", feature = "8086", vector_length = 0, encoding = "legacy" }
]

operand_encoding = {
  ZO = []
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Clears x87 FPU exception flags (PE, UE, OE, ZE, DE, IE), ES, SF, and B in the FPU status word. FCLEX checks pending unmasked exceptions first; FNCLEX does not.
"""

handler = "x86_fclex"
jit_lowering = "arm64_fclex"
fallback = "zig_fclex"

neon_register_model = "x87 FPU status word mapped to ARM64 FPCR/FPSR."
neon_flag_model = "x87 exception flags cleared via ARM64 FPSR write."
neon_assembly = "// ARM64: MRS xTMP, FPSR; AND/BIC; MSR FPSR, xTMP"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
