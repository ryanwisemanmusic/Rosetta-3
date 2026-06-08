// MOV/MOVHPS.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVHPS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVHPS.inc"
x86_handler = "x86_movhps"
neon_lowering = "arm64_move_from_x86_mov-hps"
lowering_kind = "arm64_documented_contract"

// MOVHPS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVHPS/MOVHPS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVHPS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = ""

encodings = [
  { opcode = "0F 16 /r", form = "MOVHPS xmm1, m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movhps_xmm_m64" },
  { opcode = "0F 17 /r", form = "MOVHPS m64, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movhps_m64_xmm" },
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
// MOVHPS load: xmm1[127:64] := m64;
xmm1[63:0] unchanged;
// MOVHPS store: m64 := xmm1[127:64];
"""

mode_semantics = """
Load/store the upper 64-bit single-precision values of an XMM register from/to memory.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movhps"
jit_lowering = "arm64_move_from_x86_mov-hps"
fallback = "zig_movhps_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVHPS: high quadword single-precision load/store
// ARM64 load: LD1 { v0.s[2], v0.s[3] }, [x0]
// ARM64 store: ST1 { v0.s[2], v0.s[3] }, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVHPS accesses the upper 64 bits (2 single-precision floats) of XMM."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
