// MOV/MOV.inc
// ARM64/NEON translation mirror generated from ISA/x86/MOV/MOV.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "MOV/MOV.inc"
x86_handler = "x86_mov"
neon_lowering = "arm64_mov_or_system_register_dispatch"
lowering_kind = "system_dispatch"


name = "MOV"
category = "data_transfer"
feature = "BASE"
operation_class = "move"
flags_affected = []
lock_prefix = "invalid"

encodings = [
  // General-purpose register/memory moves: register -> r/m
  { opcode = "88 /r", form = "MOV r/m8, r8", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_mov_rm8_r8" },
  { opcode = "REX + 88 /r", form = "MOV r/m8, r8", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_mov_rm8_r8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "89 /r", form = "MOV r/m16, r16", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_mov_rm16_r16" },
  { opcode = "89 /r", form = "MOV r/m32, r32", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_mov_rm32_r32" },
  { opcode = "REX.W + 89 /r", form = "MOV r/m64, r64", op_en = "MR", mode64 = "valid", compat = "n.e.", handler = "x86_mov_rm64_r64" },

  // General-purpose register/memory moves: r/m -> register
  { opcode = "8A /r", form = "MOV r8, r/m8", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_mov_r8_rm8" },
  { opcode = "REX + 8A /r", form = "MOV r8, r/m8", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_mov_r8_rm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "8B /r", form = "MOV r16, r/m16", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_mov_r16_rm16" },
  { opcode = "8B /r", form = "MOV r32, r/m32", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_mov_r32_rm32" },
  { opcode = "REX.W + 8B /r", form = "MOV r64, r/m64", op_en = "RM", mode64 = "valid", compat = "n.e.", handler = "x86_mov_r64_rm64" },

  // Segment register moves
  { opcode = "8C /r", form = "MOV r/m16, Sreg", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_mov_rm16_sreg" },
  { opcode = "8C /r", form = "MOV r16/r32/m16, Sreg", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_mov_reg_or_m16_sreg", notes = ["Segment value copied from low 16 bits; register destination is zero-extended on most IA-32 and all Intel 64 CPUs"] },
  { opcode = "REX.W + 8C /r", form = "MOV r64/m16, Sreg", op_en = "MR", mode64 = "valid", compat = "valid", handler = "x86_mov_r64_or_m16_sreg" },
  { opcode = "8E /r", form = "MOV Sreg, r/m16", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_mov_sreg_rm16", notes = ["Cannot load CS; loading SS inhibits interrupts/debug exceptions through next instruction boundary"] },
  { opcode = "REX.W + 8E /r", form = "MOV Sreg, r/m64", op_en = "RM", mode64 = "valid", compat = "valid", handler = "x86_mov_sreg_rm64_low16", notes = ["Only low 16 bits are loaded into the segment register"] },

  // Moffs accumulator moves
  { opcode = "A0", form = "MOV AL, moffs8", op_en = "FD", mode64 = "valid", compat = "valid", handler = "x86_mov_al_moffs8" },
  { opcode = "REX.W + A0", form = "MOV AL, moffs8", op_en = "FD", mode64 = "valid", compat = "n.e.", handler = "x86_mov_al_moffs8_64" },
  { opcode = "A1", form = "MOV AX, moffs16", op_en = "FD", mode64 = "valid", compat = "valid", handler = "x86_mov_ax_moffs16" },
  { opcode = "A1", form = "MOV EAX, moffs32", op_en = "FD", mode64 = "valid", compat = "valid", handler = "x86_mov_eax_moffs32" },
  { opcode = "REX.W + A1", form = "MOV RAX, moffs64", op_en = "FD", mode64 = "valid", compat = "n.e.", handler = "x86_mov_rax_moffs64" },
  { opcode = "A2", form = "MOV moffs8, AL", op_en = "TD", mode64 = "valid", compat = "valid", handler = "x86_mov_moffs8_al" },
  { opcode = "REX.W + A2", form = "MOV moffs8, AL", op_en = "TD", mode64 = "valid", compat = "n.e.", handler = "x86_mov_moffs8_al_64" },
  { opcode = "A3", form = "MOV moffs16, AX", op_en = "TD", mode64 = "valid", compat = "valid", handler = "x86_mov_moffs16_ax" },
  { opcode = "A3", form = "MOV moffs32, EAX", op_en = "TD", mode64 = "valid", compat = "valid", handler = "x86_mov_moffs32_eax" },
  { opcode = "REX.W + A3", form = "MOV moffs64, RAX", op_en = "TD", mode64 = "valid", compat = "n.e.", handler = "x86_mov_moffs64_rax" },

  // Immediate -> register
  { opcode = "B0+ rb ib", form = "MOV r8, imm8", op_en = "OI", mode64 = "valid", compat = "valid", handler = "x86_mov_r8_imm8" },
  { opcode = "REX + B0+ rb ib", form = "MOV r8, imm8", op_en = "OI", mode64 = "valid", compat = "n.e.", handler = "x86_mov_r8_imm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "B8+ rw iw", form = "MOV r16, imm16", op_en = "OI", mode64 = "valid", compat = "valid", handler = "x86_mov_r16_imm16" },
  { opcode = "B8+ rd id", form = "MOV r32, imm32", op_en = "OI", mode64 = "valid", compat = "valid", handler = "x86_mov_r32_imm32" },
  { opcode = "REX.W + B8+ rd io", form = "MOV r64, imm64", op_en = "OI", mode64 = "valid", compat = "n.e.", handler = "x86_mov_r64_imm64" },

  // Immediate -> r/m
  { opcode = "C6 /0 ib", form = "MOV r/m8, imm8", op_en = "MI", mode64 = "valid", compat = "valid", handler = "x86_mov_rm8_imm8" },
  { opcode = "REX + C6 /0 ib", form = "MOV r/m8, imm8", op_en = "MI", mode64 = "valid", compat = "n.e.", handler = "x86_mov_rm8_imm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "C7 /0 iw", form = "MOV r/m16, imm16", op_en = "MI", mode64 = "valid", compat = "valid", handler = "x86_mov_rm16_imm16" },
  { opcode = "C7 /0 id", form = "MOV r/m32, imm32", op_en = "MI", mode64 = "valid", compat = "valid", handler = "x86_mov_rm32_imm32" },
  { opcode = "REX.W + C7 /0 id", form = "MOV r/m64, imm32", op_en = "MI", mode64 = "valid", compat = "n.e.", handler = "x86_mov_rm64_imm32_sext" },

  // Control register moves
  { opcode = "0F 20 /r", form = "MOV r32, CR0-CR7", op_en = "MR", mode64 = "n.e.", compat = "valid", feature = "system", privilege = 0, serializing = true, handler = "x86_mov_r32_cr" },
  { opcode = "0F 20 /r", form = "MOV r64, CR0-CR7", op_en = "MR", mode64 = "valid", compat = "n.e.", feature = "system", privilege = 0, serializing = true, handler = "x86_mov_r64_cr" },
  { opcode = "REX.R + 0F 20 /0", form = "MOV r64, CR8", op_en = "MR", mode64 = "valid", compat = "n.e.", feature = "system", privilege = 0, serializing = false, handler = "x86_mov_r64_cr8" },
  { opcode = "0F 22 /r", form = "MOV CR0-CR7, r32", op_en = "RM", mode64 = "n.e.", compat = "valid", feature = "system", privilege = 0, serializing = true, handler = "x86_mov_cr_r32" },
  { opcode = "0F 22 /r", form = "MOV CR0-CR7, r64", op_en = "RM", mode64 = "valid", compat = "n.e.", feature = "system", privilege = 0, serializing = true, handler = "x86_mov_cr_r64" },
  { opcode = "REX.R + 0F 22 /0", form = "MOV CR8, r64", op_en = "RM", mode64 = "valid", compat = "n.e.", feature = "system", privilege = 0, serializing = false, handler = "x86_mov_cr8_r64" },

  // Debug register moves
  { opcode = "0F 21 /r", form = "MOV r32, DR0-DR7", op_en = "MR", mode64 = "n.e.", compat = "valid", feature = "debug", privilege = 0, handler = "x86_mov_r32_dr" },
  { opcode = "0F 21 /r", form = "MOV r64, DR0-DR7", op_en = "MR", mode64 = "valid", compat = "n.e.", feature = "debug", privilege = 0, handler = "x86_mov_r64_dr" },
  { opcode = "0F 23 /r", form = "MOV DR0-DR7, r32", op_en = "RM", mode64 = "n.e.", compat = "valid", feature = "debug", privilege = 0, handler = "x86_mov_dr_r32" },
  { opcode = "0F 23 /r", form = "MOV DR0-DR7, r64", op_en = "RM", mode64 = "valid", compat = "n.e.", feature = "debug", privilege = 0, handler = "x86_mov_dr_r64" }
]

operand_encodings = [
  { op_en = "MR", operand1 = "ModRM:r/m (w)", operand2 = "ModRM:reg (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "RM", operand1 = "ModRM:reg (w)", operand2 = "ModRM:r/m (r)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "FD", operand1 = "AL/AX/EAX/RAX", operand2 = "Moffs", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "TD", operand1 = "Moffs (w)", operand2 = "AL/AX/EAX/RAX", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "OI", operand1 = "opcode + rd (w)", operand2 = "imm8/16/32/64", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "MI", operand1 = "ModRM:r/m (w)", operand2 = "imm8/16/32/64", operand3 = "N/A", operand4 = "N/A" }
]

semantic_general = """
DEST := SRC;
"""

semantic_general_notes = [
  "Source may be immediate, general-purpose register, segment register, or memory.",
  "Destination may be general-purpose register, segment register, or memory.",
  "Memory-to-memory MOV is not encoded by the normal two-operand MOV forms.",
  "Both operands must be the same effective data size except documented segment-register and sign-extension forms.",
  "MOV r/m64, imm32 sign-extends the imm32 into the 64-bit destination.",
  "In 64-bit mode, default operation size is 32 bits; REX.W promotes many forms to 64 bits.",
  "moffs operands use a simple offset relative to segment base; address-size selects 16/32/64-bit offset size."
]

semantic_segment_load = """
if DEST == CS:
    raise #UD;

if DEST == SS:
    if selector_is_null(SRC): raise #GP(0);
    validate_ss_selector_and_descriptor(SRC);
    SS.selector = SRC;
    SS.descriptor = descriptor_for(SRC);
    inhibit_interrupts_and_debug_exceptions_until_after_next_instruction();

if DEST in [DS, ES, FS, GS]:
    if selector_is_null(SRC):
        DEST.selector = SRC;
        DEST.descriptor = null_descriptor;
    else:
        validate_data_or_readable_code_selector_and_descriptor(SRC);
        DEST.selector = SRC;
        DEST.descriptor = descriptor_for(SRC);
"""

semantic_control_register = """
require CPL == 0;
reject LOCK prefix;
reject CR1, CR5, CR6, CR7, and CR9-CR15;
if REX.R selects a control register other than CR8 in 64-bit mode: raise #UD;
DEST := SRC;
validate_reserved_control_register_bits_and_mode_transitions();
apply_required_tlb_and_paging_structure_cache_side_effects();
"""

semantic_debug_register = """
require CPL == 0 or real_address_mode;
reject LOCK prefix;
if CR4.DE == 1 and (SRC_OR_DEST in [DR4, DR5]): raise #UD;
if DR7.GD == 1: raise #DB;
if 64_bit_mode and REX.R is used: raise #UD;
DEST := SRC;
"""

exceptions = {
  general = ["#GP", "#SS", "#PF", "#AC", "#UD"],
  control_register = ["#GP", "#UD"],
  debug_register = ["#GP", "#UD", "#DB"]
}

jit_lowering = "arm64_mov_or_system_register_dispatch"
handler = "x86_mov"


neon_register_model = """
x86 general, segment, control, and debug register moves dispatch through register-class aware ARM64 handlers.
"""

neon_flag_model = """
Flag behavior follows the x86 source table and is validated by the runtime ABI handshake.
"""

neon_assembly = """
ldr xTMP, [xSRC]
str xTMP, [xDST]
bl rosette_dispatch_system_register_move_if_needed
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
