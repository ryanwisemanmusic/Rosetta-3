// MOV/MOVHLPS.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVHLPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVHLPS.inc"
x86_handler = "x86_movhlps"
neon_lowering = "arm64_move_from_x86_mov-hlps"
lowering_kind = "arm64_documented_contract"

// MOVHLPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVHLPS/MOVHLPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVHLPS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F 12 /r", form = "MOVHLPS xmm1, xmm2", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movhlps_xmm_xmm" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["xmm1", "xmm2"]
writes = ["xmm1"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
xmm1[63:0] := xmm2[127:64];
xmm1[127:64] := xmm1[127:64];
"""

mode_semantics = """
Moves the upper 64 bits (high quadword) of xmm2 to the lower 64 bits of xmm1. Upper 64 bits of xmm1 are unchanged.
"""

exceptions = {
simd = ["#UD"]
}

handler = "x86_movhlps"
jit_lowering = "arm64_move_from_x86_mov-hlps"
fallback = "zig_movhlps_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVHLPS: high-to-low packed single
// ARM64: EXT v0.16b, v0.16b, v1.16b, #8  or  MOV v0.d[0], v1.d[1]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVHLPS copies upper half of second operand to lower half of destination; ARM64 INS or EXT."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
