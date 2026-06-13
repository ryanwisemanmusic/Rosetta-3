// LOAD/TILELOADDT1.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/TILELOADDT1.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

semantic = """
TILELOADDT1: Load data into tile register with streaming cache hint.
Category: amx_tile.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/TILELOADDT1.inc"
x86_handler = "x86_tileloaddt1"
neon_lowering = "arm64_tileloaddt1"
lowering_kind = "arm64_documented_contract"

name = "TILELOADDT1"
aliases = []
category = "amx_tile"
feature = "AMX-TILE"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "VEX.128.66.0F38.W0 4B", form = "TILELOADDT1 tmm1, sibmem", op_en = "A", feature = "AMX-TILE", vector_length = 128, encoding = "vex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { tmm = 1 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = ["AMX-E3; see Section 2.10 for details"]

semantic_tile = """
Same as TILELOADD but with streaming cache hint.
Data is expected to be reused but does not need to be resident in the nearest cache levels.
"""

handler = "x86_tileloaddt1"
jit_lowering = "arm64_tileloaddt1"
fallback = "zig_tile_load"

neon_register_model = """
x86 tmm tile registers mapped to ARM64 tile state.
"""

neon_flag_model = """
No x86 flags are modified by TILELOADDT1.
"""

neon_assembly = """
// TILELOADDT1: ARM64 lowering via emulated tile load
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
