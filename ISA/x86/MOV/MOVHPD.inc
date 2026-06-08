// MOVHPD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVHPD/MOVHPD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVHPD.inc"
x86_handler = "x86_movhpd"
neon_lowering = "arm64_move_from_x86_mov-hpd"
lowering_kind = "arm64_simd_move"

name = "MOVHPD"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "66 0F 16 /r", form = "MOVHPD xmm1, m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movhpd_xmm_m64" },
  { opcode = "66 0F 17 /r", form = "MOVHPD m64, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movhpd_m64_xmm" },
]

operand_encoding = [
  { op_en = "RM", operand_1 = "ModRM:reg (w)", operand_2 = "ModRM:r/m (r)", operand_3 = "N/A", operand_4 = "N/A" },
  { op_en = "MR", operand_1 = "ModRM:r/m (w)", operand_2 = "ModRM:reg (r)", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["SRC"]
writes = ["DEST"]
flags_read = []
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
// MOVHPD load: xmm1[127:64] := m64;
// MOVHPD store: m64 := xmm1[127:64];
"""

mode_semantics = """
Load/store the upper 64-bit double-precision value of an XMM register from/to memory.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movhpd"
jit_lowering = "arm64_move_from_x86_mov-hpd"
fallback = "zig_movhpd_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVHPD: high quadword double-precision load/store
// ARM64 load: LD1 { v0.d[1] }, [x0]
// ARM64 store: ST1 { v0.d[1] }, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVHPD accesses the upper 64 bits of an XMM register; ARM64 LD1/ST1 with lane index 1."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]