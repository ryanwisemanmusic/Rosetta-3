// Jcc/JBE.inc
// ARM64/NEON translation mirror generated from ISA/x86/Jcc/JBE.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "Jcc/JBE.inc"
x86_handler = "x86_jbe"
neon_lowering = "arm64_conditional_branch_from_x86_below_or_equal"
lowering_kind = "arm64_control_flow"

name = "JBE"
category = "control_flow_conditional"
instruction_family = "Jcc"
condition_name = "below_or_equal"
condition_expression = "CF == 1 or ZF == 1"
comparison_domain = "unsigned"
aliases = "JNA"

encodings = [
  { opcode = "76 cb", form = "JBE rel8", op_en = "D", mode_64 = "valid", compat_legacy = "valid", displacement = "rel8", condition = "CF == 1 or ZF == 1" },
  { opcode = "0F 86 cw", form = "JBE rel16", op_en = "D", mode_64 = "not_supported", compat_legacy = "valid", displacement = "rel16", condition = "CF == 1 or ZF == 1" },
  { opcode = "0F 86 cd", form = "JBE rel32", op_en = "D", mode_64 = "valid", compat_legacy = "valid", displacement = "rel32", condition = "CF == 1 or ZF == 1" }
]

operand_encoding = [
  { op_en = "D", operand_1 = "Offset", operand_2 = "N/A", operand_3 = "N/A", operand_4 = "N/A" }
]

reads = ["RIP", "CF", "ZF"]
writes = ["RIP"]
flags_read = ["CF", "ZF"]
flags_written = []
flags_affected = []
lock_allowed = false
far_jump_supported = false
condition_source = "EFLAGS/RFLAGS status flags"

semantic = """
next_ip = instruction_pointer_after_JBE;
if (CF == 1 or ZF == 1) {
    target = next_ip + sign_extend(DEST);
    if operand_size == 16 {
        target = target & 0x0000_FFFF;
    }
    if target_outside_code_segment_limit {
        raise #GP(0);
    } else {
        IP = target;
    }
} else {
    IP = next_ip;
}
"""

mode_semantics = """
Protected/compatibility mode: if the target offset is outside the CS segment limit, raise #GP(0).
Real-address/virtual-8086 mode: if the target offset is beyond CS limit or outside effective address space 0..FFFFH due to address-size override, raise #GP.
64-bit mode: operand size is fixed at 64 bits; rel8 is sign-extended to 64 bits for short form, rel32 is sign-extended to 64 bits for near form; non-canonical target raises #GP(0).
LOCK prefix is invalid and raises #UD.
No flags are modified.
"""

jcc_family_notes = [
  "The destination is always relative; machine encoding stores rel8, rel16, or rel32 displacement depending on form.",
  "Short form is most efficient for -128..+127 byte range.",
  "rel16 near form is not supported in 64-bit mode.",
  "Jcc does not support far conditional jumps; synthesize by inverting the condition and following with an unconditional far JMP.",
  "Conditional branch miss/not-taken behavior must preserve fallthrough to the instruction following this Jcc."
]

exceptions = {
  protected_mode = ["#GP(0) if target offset beyond CS segment limit", "#UD if LOCK prefix is used"],
  real_address_mode = ["#GP if target beyond CS limit or outside 0..FFFFH effective address space", "#UD if LOCK prefix is used"],
  virtual_8086_mode = ["same as real-address mode"],
  compatibility_mode = ["same as protected mode"],
  mode_64 = ["#GP(0) if target is non-canonical", "#UD if LOCK prefix is used"]
}

handler = "x86_jbe"
jit_lowering = "arm64_conditional_branch_from_x86_below_or_equal"
fallback = "zig_relative_branch_condition_eval"

neon_register_model = """
The x86 instruction pointer and flags/counter register are read from the Rosette register file. The ARM64 lowering must either branch to the translated target block or continue at the translated fallthrough block.
"""

neon_flag_model = """
This lowering reads the preserved x86 architectural condition source exactly as listed in flags_read/reads. ARM64 NZCV may be used as an optimization only when it is known to mirror the required x86 flags without loss.
"""

neon_assembly = """
// Pseudocode lowering; exact ARM64 condition may be direct or synthesized.
bl rosette_eval_jbe_condition
cbnz xCOND, translated_target
b translated_fallthrough
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken x86 condition-code behavior, displacement sign-extension, fallthrough behavior, or exception behavior.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
