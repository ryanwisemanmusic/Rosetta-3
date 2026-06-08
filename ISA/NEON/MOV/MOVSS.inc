// MOV/MOVSS.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVSS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVSS.inc"
x86_handler = "x86_movss"
neon_lowering = "arm64_move_from_x86_mov-ss"
lowering_kind = "arm64_documented_contract"

// MOVSS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVSS/MOVSS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVSS"
category = "simd_data_transfer"
instruction_family = "MOV"
alias_info = "VMOVSS"

encodings = [
  { opcode = "F3 0F 10 /r", form = "MOVSS xmm1, xmm2/m32", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movss_xmm_xmmm32" },
  { opcode = "F3 0F 11 /r", form = "MOVSS xmm2/m32, xmm1", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_movss_xmmm32_xmm" },
  { opcode = "F3 0F 10 /r", form = "MOVSS xmm1, xmm2", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_movss_xmm_xmm" },
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
// MOVSS load: xmm1[31:0] := m32; xmm1[127:32] := 0;
// MOVSS store: m32 := xmm1[31:0];
// MOVSS reg-reg: xmm1[31:0] := xmm2[31:0]; xmm1[127:32] unchanged;
"""

mode_semantics = """
Scalar single-precision floating-point move. When loading from memory, upper 96 bits are zeroed.
"""

exceptions = {
simd = ["#SS", "#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movss"
jit_lowering = "arm64_move_from_x86_mov-ss"
fallback = "zig_movss_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVSS: scalar single-precision move
// ARM64: LD1 { v0.s[0] }, [x0]  or  FMOV S0, S1  or  STR S0, [x0]
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVSS scalar single move; ARM64 FMOV Sd, Sn / LD1 / STR."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
