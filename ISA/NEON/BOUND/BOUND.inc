// BOUND/BOUND.inc
// ARM64/NEON mirror generated from ISA/x86/BOUND/BOUND.inc.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "BOUND/BOUND.inc"
x86_handler = "x86_bound"
neon_lowering = "arm64_bound"
lowering_kind = "arm64_documented_contract"

name = "BOUND"
aliases = []
category = "bounds_check"
feature = "i186"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "62 /r", form = "BOUND r16, m16&16", op_en = "RM", feature = "i186", vector_length = 0, encoding = "legacy", mode = "i286+ not 64-bit" },
  { opcode = "62 /r", form = "BOUND r32, m32&32", op_en = "RM", feature = "i386", vector_length = 0, encoding = "legacy", mode = "i386+ not 64-bit" }
]

operand_encoding = {
  RM = ["ModRM:reg (r)", "ModRM:r/m (r)"]
}

flags_written = []
simd_fp_exceptions = []

semantic_general = """
Check array index against bounds: if index < lower_bound or index > upper_bound, raises BR (bound range exceeded) exception (#BR).
"""

handler = "x86_bound"
jit_lowering = "arm64_bound"
fallback = "zig_bound"

neon_register_model = "x86 GPR registers mapped to ARM64 X registers."
neon_flag_model = "No x86 flags modified by BOUND; raises exception via ARM64 SVC or trap."
neon_assembly = "// ARM64: CMP xIDX, xLOW; CCMP xIDX, xHIGH, #1; B.LS; SVC #BR_VECTOR"
neon_notes = ["Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."]
abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
