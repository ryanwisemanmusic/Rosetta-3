// LOAD/TILELOADD.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/TILELOADD.inc.
// Source contract: TILELOADD — Load Tile.

semantic = """
TILELOADD: Load data into tile register as specified by sibmem addressing.
Category: amx_tile.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/TILELOADD.inc"
x86_handler = "x86_tileloadd"
neon_lowering = "arm64_tileloadd"
lowering_kind = "neon_vector"

name = "TILELOADD"
aliases = []
category = "amx_tile"
feature = "AMX-TILE"
element_type = "integer"
element_size = 0

encodings = [
  { opcode = "VEX.128.F2.0F38.W0 4B", form = "TILELOADD tmm1, sibmem", op_en = "A", feature = "AMX-TILE", vector_length = 128, encoding = "vex" }
]

operand_encoding = {
  A = ["ModRM:reg (w)", "ModRM:r/m (r)"]
}

lanes = { tmm = 1 }
flags_written = []
simd_fp_exceptions = []
other_exceptions = ["AMX-E3; see Section 2.10 for details"]

semantic_tile = """
Load data into tmm1 tile register as specified by sibmem.
start := tilecfg.start_row
zero_upper_rows(tdest, start)
membegin := tsib.base + displacement
stride := tsib.index << tsib.scale
nbytes := tdest.colsb
while start < tdest.rows:
    memptr := membegin + start * stride
    write_row_and_zero(tdest, start, read_memory(memptr, nbytes), nbytes)
    start := start + 1
zero_tilecfg_start()
"""

handler = "x86_tileloadd"
jit_lowering = "arm64_tileloadd"
fallback = "zig_tile_load"

neon_register_model = """
x86 tmm tile registers mapped to ARM64 tile state.
"""

neon_flag_model = """
No x86 flags are modified by TILELOADD.
"""

neon_assembly = """
// TILELOADD: ARM64 lowering via emulated tile load
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
