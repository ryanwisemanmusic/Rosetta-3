// MOVSD.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVSD/MOVSD.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVSD.inc"
x86_handler = "x86_movsd"
neon_lowering = "arm64_move_from_x86_mov-sd"
lowering_kind = "arm64_simd_scalar_move"

name = "MOVSD"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVSD"

encodings = [
  { opcode = "F2 0F 10 /r", form = "MOVSD xmm1, xmm2/m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movsd_xmm_xmmm64" },
  { opcode = "F2 0F 11 /r", form = "MOVSD xmm2/m64, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movsd_xmmm64_xmm" },
  { opcode = "F2 0F 10 /r", form = "MOVSD xmm1, xmm2", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movsd_xmm_xmm" },
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
// MOVSD load: xmm1[63:0] := m64; xmm1[127:64] := 0;
// MOVSD store: m64 := xmm1[63:0];
// MOVSD reg-reg: xmm1[63:0] := xmm2[63:0]; xmm1[127:64] unchanged;
"""

mode_semantics = """
Scalar double-precision floating-point move. When loading from memory, upper quadword is zeroed.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movsd"
jit_lowering = "arm64_move_from_x86_mov-sd"
fallback = "zig_movsd_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVSD: scalar double-precision move
// ARM64: LD1 { v0.d[0] }, [x0]  or  FMOV D0, D1  or  STR D0, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVSD scalar double move; distinguishes from MOVSD string variant by prefix (F2 vs no prefix)."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]