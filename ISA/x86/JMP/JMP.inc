// JMP/JMP.inc
// ARM64 translation mirror generated from ISA/x86/JMP/JMP.inc.
// This file preserves the full x86 JMP instruction contract, then appends the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "JMP/JMP.inc"
x86_handler = "x86_jmp"
neon_lowering = "arm64_control_transfer_jmp"
lowering_kind = "arm64_control_flow"

name = "JMP"
category = "control_flow_unconditional"
operation = "unconditional transfer of program control without recording return information"

encodings = [
  { opcode = "EB cb", form = "JMP rel8", op_en = "D", mode64 = "valid", compat = "valid", kind = "short_near_relative", displacement = 8, target = "RIP/EIP + sign_extend(rel8)" },
  { opcode = "E9 cw", form = "JMP rel16", op_en = "D", mode64 = "not_supported", compat = "valid", kind = "near_relative", displacement = 16, target = "EIP + sign_extend(rel16)" },
  { opcode = "E9 cd", form = "JMP rel32", op_en = "D", mode64 = "valid", compat = "valid", kind = "near_relative", displacement = 32, target = "RIP/EIP + sign_extend(rel32)" },

  { opcode = "FF /4", form = "JMP r/m16", op_en = "M", mode64 = "not_supported", compat = "valid", kind = "near_absolute_indirect", operand_size = 16, target = "zero_extend(r/m16)" },
  { opcode = "FF /4", form = "JMP r/m32", op_en = "M", mode64 = "not_supported", compat = "valid", kind = "near_absolute_indirect", operand_size = 32, target = "r/m32" },
  { opcode = "FF /4", form = "JMP r/m64", op_en = "M", mode64 = "valid", compat = "not_encodable", kind = "near_absolute_indirect", operand_size = 64, target = "r/m64" },

  { opcode = "EA cd", form = "JMP ptr16:16", op_en = "S", mode64 = "invalid", compat = "valid", kind = "far_absolute_direct", pointer = "ptr16:16" },
  { opcode = "EA cp", form = "JMP ptr16:32", op_en = "S", mode64 = "invalid", compat = "valid", kind = "far_absolute_direct", pointer = "ptr16:32" },
  { opcode = "FF /5", form = "JMP m16:16", op_en = "M", mode64 = "valid", compat = "valid", kind = "far_absolute_indirect", pointer = "m16:16" },
  { opcode = "FF /5", form = "JMP m16:32", op_en = "M", mode64 = "valid", compat = "valid", kind = "far_absolute_indirect", pointer = "m16:32" },
  { opcode = "REX.W FF /5", form = "JMP m16:64", op_en = "M", mode64 = "valid", compat = "not_encodable", kind = "far_absolute_indirect", pointer = "m16:64" }
]

operand_encoding = [
  { op_en = "S", operand1 = "Segment + Absolute Address", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "D", operand1 = "Offset", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "M", operand1 = "ModRM:r/m (read)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
]

jump_classes = [
  "short_near_jump",
  "near_jump",
  "far_jump",
  "task_switch"
]

reads = ["RIP/EIP", "DEST"]
writes = ["RIP/EIP", "CS_if_far_jump", "task_state_if_task_switch"]
flags_read = []
flags_written = []
flags_affected = "all_flags_affected_if_task_switch_occurs; otherwise_no_flags_affected"
lock_allowed = false

semantic_near_short = """
if mode64:
    if near_relative:
        tempRIP = RIP_after_instruction + sign_extend(DEST);
    else:
        tempRIP = DEST;
    if not is_canonical(tempRIP):
        raise #GP(0);
    RIP = tempRIP;
else:
    if near_relative:
        tempEIP = EIP_after_instruction + sign_extend(DEST);
    else:
        tempEIP = DEST;
    if protected_or_compat_mode and tempEIP outside current CS limit:
        raise #GP(0);
    if operand_size == 16:
        EIP = tempEIP & 0x0000FFFF;
    else:
        EIP = tempEIP;
"""

semantic_far_real_v8086 = """
# Applies when PE == 0, or PE == 1 and VM == 1.
tempEIP = DEST.offset;
if tempEIP beyond code_segment_limit:
    raise #GP(0);
CS = DEST.segment_selector;
if operand_size == 16:
    EIP = tempEIP & 0x0000FFFF;
else:
    EIP = tempEIP;
"""

semantic_far_protected_ia32e = """
# Applies when PE == 1 and VM == 0, including protected mode and IA-32e mode.
if effective_address_illegal or target_segment_selector_is_null:
    raise #GP(0);
if selector_index_outside_descriptor_table:
    raise #GP(selector);

descriptor = read_descriptor(DEST.segment_selector);

if IA32_EFER.LMA == 0:
    allowed_descriptor_types = ["conforming_code", "nonconforming_code", "call_gate", "task_gate", "TSS"];
else:
    allowed_descriptor_types = ["conforming_code", "nonconforming_code", "64_bit_call_gate"];

if descriptor.type not in allowed_descriptor_types:
    raise #GP(selector);

dispatch descriptor.type:
    conforming_code      -> jmp_conforming_code_segment();
    nonconforming_code   -> jmp_nonconforming_code_segment();
    call_gate            -> jmp_call_gate_no_stack_switch();
    task_gate            -> switch_tasks_via_task_gate();
    TSS                  -> switch_tasks_direct_tss();
"""

semantic_conforming_code_segment = """
if IA32_EFER.LMA == 1 and descriptor.L == 1 and descriptor.D == 1:
    raise #GP(selector);
if descriptor.DPL > CPL:
    raise #GP(selector);
if descriptor.not_present:
    raise #NP(selector);

tempEIP = DEST.offset;
if operand_size == 16:
    tempEIP = tempEIP & 0x0000FFFF;
if legacy_or_compat_target and tempEIP outside code_segment_limit:
    raise #GP(0);
if target_offset_noncanonical:
    raise #GP(0);
if shadow_stack_enabled and target_is_legacy_or_compat and SSP_not_in_low_4GB:
    raise #GP(0);

CS = DEST.segment_selector;
CS.RPL = CPL;
EIP/RIP = tempEIP;
if CET_endbranch_enabled:
    CET.tracker = WAIT_FOR_ENDBRANCH;
    CET.suppress = 0;
"""

semantic_nonconforming_code_segment = """
if IA32_EFER.LMA == 1 and descriptor.L == 1 and descriptor.D == 1:
    raise #GP(selector);
if DEST.selector.RPL > CPL or descriptor.DPL != CPL:
    raise #GP(selector);
if descriptor.not_present:
    raise #NP(selector);

tempEIP = DEST.offset;
if operand_size == 16:
    tempEIP = tempEIP & 0x0000FFFF;
if legacy_or_compat_target and tempEIP outside code_segment_limit:
    raise #GP(0);
if target_offset_noncanonical:
    raise #GP(0);
if shadow_stack_enabled and target_is_legacy_or_compat and SSP_not_in_low_4GB:
    raise #GP(0);

CS = DEST.segment_selector;
CS.RPL = CPL;
EIP/RIP = tempEIP;
if CET_endbranch_enabled:
    CET.tracker = WAIT_FOR_ENDBRANCH;
    CET.suppress = 0;
"""

semantic_call_gate = """
# JMP through a call gate performs a far control transfer but no stack switch.
if call_gate.DPL < CPL or call_gate.DPL < DEST.selector.RPL:
    raise #GP(call_gate_selector);
if call_gate.not_present:
    raise #NP(call_gate_selector);
if call_gate.code_segment_selector_is_null:
    raise #GP(0);
if code_segment_selector_outside_descriptor_table:
    raise #GP(code_segment_selector);

code_descriptor = read_descriptor(call_gate.code_segment_selector);
if code_descriptor_invalid_for_gate_target:
    raise #GP(code_segment_selector);
if IA32_EFER.LMA == 1 and target_not_valid_64_bit_code_segment:
    raise #GP(code_segment_selector);
if code_descriptor.not_present:
    raise #NP(code_segment_selector);

tempEIP = call_gate.target_offset;
if gate_size == 16:
    tempEIP = tempEIP & 0x0000FFFF;
if legacy_or_compat_target and tempEIP outside code_segment_limit:
    raise #GP(0);

CS = call_gate.code_segment_selector;
CS.RPL = CPL;
EIP/RIP = tempEIP;
if CET_endbranch_enabled:
    CET.tracker = WAIT_FOR_ENDBRANCH;
    CET.suppress = 0;
"""

semantic_task_gate = """
if task_gate.DPL < CPL or task_gate.DPL < DEST.selector.RPL:
    raise #GP(task_gate_selector);
if task_gate.not_present:
    raise #NP(task_gate_selector);
TSS_selector = task_gate.TSS_selector;
if TSS_selector_is_local or TSS_index_outside_GDT or descriptor_not_TSS or TSS_busy:
    raise #GP(TSS_selector);
if TSS.not_present:
    raise #NP(TSS_selector);
switch_tasks_to_TSS(TSS_selector);
if new_EIP outside new_code_segment_limit:
    raise #GP(0);
# JMP task switch does not set NT and does not save previous-task link for IRET return.
"""

semantic_task_state_segment = """
if TSS.DPL < CPL or TSS.DPL < DEST.selector.RPL or TSS_not_available:
    raise #GP(TSS_selector);
if TSS.not_present:
    raise #NP(TSS_selector);
switch_tasks_to_TSS(TSS_selector);
if new_EIP outside new_code_segment_limit:
    raise #GP(0);
# JMP task switch does not set NT and does not save previous-task link for IRET return.
"""

semantic_64_bit_mode = """
# Near operation size is fixed at 64 bits.
# rel32 is sign-extended to 64 bits for near relative JMP.
# r/m64 is used for near absolute indirect JMP.
# Direct far absolute immediate forms are invalid in 64-bit mode.
# For far indirect JMP, if selector points to a gate, RIP is taken from the 64-bit gate displacement;
# otherwise RIP is the zero-extended offset from the far pointer referenced by memory.
# Non-canonical target addresses raise #GP(0).
"""

cet_behavior = """
near_indirect_absolute_jmp:
    if EndbranchEnabledAndNotSuppressed(CPL):
        if CPL == 3:
            if no_3EH_prefix or IA32_U_CET.NO_TRACK_EN == 0:
                IA32_U_CET.TRACKER = WAIT_FOR_ENDBRANCH;
        else:
            if no_3EH_prefix or IA32_S_CET.NO_TRACK_EN == 0:
                IA32_S_CET.TRACKER = WAIT_FOR_ENDBRANCH;

far_jmp_to_code_or_gate:
    if EndbranchEnabled(CPL):
        tracker = WAIT_FOR_ENDBRANCH;
        suppress = 0;
"""

speculation_ordering = [
  "Instructions after a far JMP may be fetched before earlier instructions complete, but will not execute, including speculatively, until prior instructions complete.",
  "Instructions sequentially following a near indirect JMP may execute speculatively if they are not the target.",
  "Use INT3 or LFENCE after near indirect JMP when software must block fall-through speculative execution side channels."
]

exceptions_protected_mode = [
  "#GP(0): target offset/call gate/TSS beyond code segment limit",
  "#GP(0): null segment selector in destination, call gate, task gate, or TSS",
  "#GP(0): memory operand effective address outside CS/DS/ES/FS/GS segment limit",
  "#GP(0): DS/ES/FS/GS used with null segment selector",
  "#GP(0): target compatibility mode and SSP not in low 4GB",
  "#GP(selector): selector index outside descriptor table limits",
  "#GP(selector): descriptor type invalid for JMP target",
  "#GP(selector): nonconforming DPL != CPL or RPL > CPL",
  "#GP(selector): conforming DPL > CPL",
  "#GP(selector): call/task gate/TSS DPL less than CPL or RPL",
  "#GP(selector): call gate target descriptor is not code segment",
  "#GP(selector): task gate descriptor does not indicate available TSS",
  "#GP(selector): TSS selector local/global bit set local",
  "#GP(selector): TSS descriptor busy or unavailable",
  "#SS(0): memory operand effective address outside SS segment limit",
  "#NP(selector): code segment, call gate, task gate, or TSS not present",
  "#PF(fault-code): page fault",
  "#AC(0): CPL3 alignment checking and unaligned memory reference while fetching target from memory",
  "#UD: LOCK prefix used"
]

exceptions_real_address_mode = [
  "#GP: memory operand effective address outside CS/DS/ES/FS/GS segment limit",
  "#SS: memory operand effective address outside SS segment limit",
  "#UD: LOCK prefix used"
]

exceptions_virtual_8086_mode = [
  "#GP(0): target operand beyond code segment limit",
  "#GP(0): memory operand effective address outside CS/DS/ES/FS/GS segment limit",
  "#SS(0): memory operand effective address outside SS segment limit",
  "#PF(fault-code): page fault",
  "#AC(0): alignment checking enabled and unaligned memory reference while fetching target from memory",
  "#UD: LOCK prefix used"
]

exceptions_compatibility_mode = [
  "same_as_64_bit_mode_exceptions"
]

exceptions_64_bit_mode = [
  "#GP(0): memory address is non-canonical",
  "#GP(0): target offset in destination operand is non-canonical",
  "#GP(0): target offset beyond new code segment limit",
  "#GP(0): segment selector in destination operand is NULL",
  "#GP(0): code segment selector in 64-bit gate is NULL",
  "#GP(0): transitioning to compatibility mode and SSP beyond 4GB",
  "#GP(selector): code segment or 64-bit call gate outside descriptor table limits",
  "#GP(selector): code segment or 64-bit call gate overlaps non-canonical space",
  "#GP(selector): segment descriptor from 64-bit call gate is in non-canonical space",
  "#GP(selector): descriptor is not conforming code, nonconforming code, or 64-bit call gate",
  "#GP(selector): code segment has both D-bit and L-bit set",
  "#GP(selector): nonconforming DPL != CPL or selector RPL > CPL",
  "#GP(selector): conforming DPL > CPL",
  "#GP(selector): 64-bit call-gate DPL less than CPL or RPL",
  "#GP(selector): upper type field of 64-bit call gate is not 0x0",
  "#GP(selector): segment selector from 64-bit call gate beyond descriptor table limits",
  "#GP(selector): call-gate target code segment does not have L-bit set and D-bit clear",
  "#GP(selector): call-gate selector does not indicate code segment",
  "#GP(selector): nonconforming code and CPL != DPL",
  "#GP(selector): conforming code and CPL < DPL",
  "#NP(selector): code segment or 64-bit call gate not present",
  "#UD: direct far jump to absolute memory address in 64-bit mode",
  "#UD: LOCK prefix used",
  "#PF(fault-code): page fault",
  "#AC(0): CPL3 alignment checking and unaligned memory reference"
]

handler = "x86_jmp"
jit_lowering = "arm64_control_transfer_jmp"
fallback = "zig_control_flow_slow_path"

arm64_register_model = """
x86 RIP/EIP and CS are represented in the Rosette CPU context. ARM64 branch instructions may be used only when the translated target is known inside the current generated block; otherwise the lowering writes the resolved x86 target into the CPU context and exits/dispatches through the Rosette control-flow dispatcher.
"""

arm64_flag_model = """
JMP does not read or write x86 flags unless it performs a hardware task switch. The ARM64 lowering must preserve all x86 flag state for normal near and far jumps.
"""

arm64_lowering_near_relative = """
# Static/direct target known in translated block:
b translated_target

# Dynamic or block-external target:
add xTMP, xRIP_AFTER, sign_extend(displacement)
str xTMP, [xCPU, RIP_OFFSET]
b rosette_dispatch_next_block
"""

arm64_lowering_near_indirect = """
# Resolve r/m target through decoded register or memory operand.
bl rosette_read_rm_target
bl rosette_validate_near_jmp_target
str xTARGET, [xCPU, RIP_OFFSET]
b rosette_dispatch_next_block
"""

arm64_lowering_far_or_task = """
# Far jumps, gates, descriptor checks, CET, shadow-stack validation, and task switches route through the architectural slow path.
bl rosette_x86_jmp_far_or_task_slow_path
b rosette_dispatch_next_block
"""

neon_register_model = """
No SIMD/NEON data lanes are required. The target_isa remains arm64_neon for mirror consistency with the rest of the Rosette ISA table set.
"""

neon_flag_model = """
No NEON flag behavior applies. x86 flags are preserved unless the JMP executes a task switch, in which case the task-switch slow path owns full architectural flag state restoration/update.
"""

neon_assembly = """
# Near direct, internal block:
b translated_target

# Near indirect/external/far/task:
bl rosette_x86_jmp_resolve_or_slow_path
b rosette_dispatch_next_block
"""

neon_notes = [
  "This file covers JMP only; conditional Jcc instructions belong in a separate Jcc table.",
  "Short and near relative jumps are intrasegment and do not modify CS.",
  "Near absolute indirect jumps load the instruction pointer from r/m16, r/m32, or r/m64 according to mode support.",
  "Far jumps may load CS and EIP/RIP, traverse code segment descriptors, traverse call gates, or perform task switches.",
  "64-bit mode rejects direct far absolute immediate JMP forms, but supports far indirect memory forms as documented.",
  "The ARM64 lowering must not collapse far jump, descriptor, CET, shadow stack, task-switch, canonicality, or exception behavior into a plain branch.",
  "Runtime ABI validation checks both the x86 table shape and this ARM64 lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
