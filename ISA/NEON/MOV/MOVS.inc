// MOV/MOVS.inc
// ARM64/NEON mirror generated from ISA/x86/MOV/MOVS.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOVS.inc"
x86_handler = "x86_movs"
neon_lowering = "arm64_move_from_x86_mov-s"
lowering_kind = "arm64_documented_contract"

// MOVS.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOVS/MOVS.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.


name = "MOVS"
category = "string_data_transfer"
instruction_family = "MOV"
alias_info = "MOVSB/MOVSW/MOVSD/MOVSQ"

encodings = [
  { opcode = "A4", form = "MOVSB", op_en = "ZO", mode64 = "valid", compat = "valid", handler = "x86_movsb" },
  { opcode = "A5", form = "MOVSW", op_en = "ZO", mode64 = "valid", compat = "valid", handler = "x86_movsw" },
  { opcode = "A5", form = "MOVSD", op_en = "ZO", mode64 = "valid", compat = "valid", handler = "x86_movsd_string" },
  { opcode = "REX.W + A5", form = "MOVSQ", op_en = "ZO", mode64 = "valid", compat = "n.e.", handler = "x86_movsq" },
]

operand_encoding = [
  { op_en = "ZO", operand_1 = "N/A (implicit ES:DI/RDI, DS:SI/RSI)", operand_2 = "N/A", operand_3 = "N/A", operand_4 = "N/A" },
]

reads = ["DS:(E)SI_or_(R)SI", "ES:(E)DI_or_(R)DI", "DF"]
writes = ["ES:(E)DI_or_(R)DI", "(E)SI_or_(R)SI", "(E)DI_or_(R)DI"]
flags_read = ["DF"]
flags_written = []
flags_affected = []
lock_allowed = false

semantic = """
// MOVSB: byte string move
  ES:[DI] := DS:[SI];
  IF DF == 0 THEN SI := SI + 1; DI := DI + 1;
           ELSE SI := SI - 1; DI := DI - 1;
// MOVSW: word string move (operand_size 16)
// MOVSD (string): dword string move (operand_size 32)
// MOVSQ: qword string move (operand_size 64)
"""

mode_semantics = """
In 64-bit mode, address size determines SI/DI as RSI/RDI (64-bit) or ESI/EDI (32-bit). The REP prefix repeats ECX times.
"""

exceptions = {
general = ["#GP", "#PF", "#AC", "#UD"]
}

handler = "x86_movs"
jit_lowering = "arm64_move_from_x86_mov-s"
fallback = "zig_movs_fallback"

neon_register_model = """
The x86 register and memory operands are read from the Rosette register file. The ARM64 lowering performs the move operation with appropriate data-size handling.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural state exactly as listed in reads/flags_read. No ARM64 NZCV flags are modified unless this instruction explicitly writes x86 flags.
"""

neon_assembly = """
// MOVS: string move instruction
// ARM64: LDRB/STRB or LDR/STR with post-index; loop with REP emulation
// MOVS with REP: emulated via loop using LDR/STR with post-increment
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 data-size behavior, alignment behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape.",
  "MOVS string operations with REP prefix require loop emulation on ARM64."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
