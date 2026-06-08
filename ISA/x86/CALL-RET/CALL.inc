// CALL/CALL.inc
// ARM64/NEON translation mirror generated from ISA/x86/CALL/CALL.inc.
// This file preserves the full x86 CALL instruction contract, then appends the ARM64 lowering contract.

// Canonical table metadata for registry-wide .inc validation.
semantic = """
CALL: preserve save procedure linking information on the stack and branch to the target procedure.
See operation, semantic_* blocks, source_contract, or preserved X86_INST rows below for the full instruction behavior.
Category: control_flow_call.
"""

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CALL/CALL.inc"
x86_handler = "x86_call"
neon_lowering = "arm64_call_push_return_and_branch"
lowering_kind = "arm64_control_flow_stack"

name = "CALL"
category = "control_flow_call"
operation = "save procedure linking information on the stack and branch to the target procedure"

encodings = [
  { opcode = "E8 cw", form = "CALL rel16", op_en = "D", mode64 = "not_supported", compat = "valid", call_kind = "near_relative", operand_size = 16, displacement = 16, description = "Call near, relative, displacement relative to next instruction." },
  { opcode = "E8 cd", form = "CALL rel32", op_en = "D", mode64 = "valid", compat = "valid", call_kind = "near_relative", operand_size = "32_or_64", displacement = 32, mode64_displacement_extend = "sign_extend_to_64", description = "Call near, relative; rel32 is sign-extended to 64 bits in 64-bit mode." },

  { opcode = "FF /2", form = "CALL r/m16", op_en = "M", mode64 = "not_encodable", compat = "valid", call_kind = "near_absolute_indirect", operand_size = 16, modrm_ext = 2, target = "r/m16", description = "Call near, absolute indirect, address given in r/m16." },
  { opcode = "FF /2", form = "CALL r/m32", op_en = "M", mode64 = "not_encodable", compat = "valid", call_kind = "near_absolute_indirect", operand_size = 32, modrm_ext = 2, target = "r/m32", description = "Call near, absolute indirect, address given in r/m32." },
  { opcode = "FF /2", form = "CALL r/m64", op_en = "M", mode64 = "valid", compat = "not_encodable", call_kind = "near_absolute_indirect", operand_size = 64, modrm_ext = 2, target = "r/m64", description = "Call near, absolute indirect, address given in r/m64." },

  { opcode = "9A cd", form = "CALL ptr16:16", op_en = "D", mode64 = "invalid", compat = "valid", call_kind = "far_absolute_direct", operand_size = 16, pointer = "ptr16:16", description = "Call far, absolute, address given in operand." },
  { opcode = "9A cp", form = "CALL ptr16:32", op_en = "D", mode64 = "invalid", compat = "valid", call_kind = "far_absolute_direct", operand_size = 32, pointer = "ptr16:32", description = "Call far, absolute, address given in operand." },

  { opcode = "FF /3", form = "CALL m16:16", op_en = "M", mode64 = "valid", compat = "valid", call_kind = "far_absolute_indirect", operand_size = 16, modrm_ext = 3, target = "m16:16", description = "Call far, absolute indirect address given in m16:16. In 32-bit mode, gate selector may redirect through descriptor logic; otherwise offset is zero-extended from far pointer." },
  { opcode = "FF /3", form = "CALL m16:32", op_en = "M", mode64 = "valid", compat = "valid", call_kind = "far_absolute_indirect", operand_size = 32, modrm_ext = 3, target = "m16:32", description = "Call far, absolute indirect address given in m16:32. In 64-bit mode, gate selector gives 64-bit gate displacement; otherwise offset is zero-extended from far pointer." },
  { opcode = "REX.W FF /3", form = "CALL m16:64", op_en = "M", mode64 = "valid", compat = "not_encodable", call_kind = "far_absolute_indirect", operand_size = 64, modrm_ext = 3, target = "m16:64", description = "Call far, absolute indirect address given in m16:64. In 64-bit mode, gate selector gives 64-bit gate displacement; otherwise offset is 64-bit far pointer offset." }
]

operand_encoding = [
  { op_en = "D", operand1 = "Offset", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "M", operand1 = "ModRM:r/m (read)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
]

reads = ["RIP/EIP/IP", "target operand", "stack pointer", "CS for far calls", "descriptor tables for protected/IA-32e far calls"]
writes = ["RIP/EIP/IP", "stack pointer", "memory stack", "CS for far calls"]
implicit_reads = ["CS", "SS", "RSP/ESP/SP", "CPL", "EFLAGS/RFLAGS", "IA32_EFER.LMA", "descriptor tables", "TSS when required", "CET state when enabled"]
implicit_writes = ["RSP/ESP/SP", "CS for far calls", "SS for privilege-changing far calls", "EIP/RIP", "shadow stack when CET shadow stack is enabled", "CET ENDBRANCH tracker when enabled", "EFLAGS.NT on task-switch CALL"]
flags_read = []
flags_written = []
flags_affected = "All flags are affected if a task switch occurs; no flags are affected if a task switch does not occur."
lock_allowed = false

call_types = [
  "near_call_current_code_segment",
  "far_call_different_code_segment",
  "inter_privilege_level_far_call_protected_mode_only",
  "task_switch_protected_mode_only"
]

mode_notes = [
  "Near CALL pushes the offset of the instruction following CALL, then branches within the current code segment.",
  "Near relative CALL target = next IP plus signed displacement.",
  "Near absolute CALL target comes from r/m16, r/m32, or r/m64 depending on mode and operand size.",
  "In 64-bit mode, near CALL operand size is forced to 64 bits and rel32 is sign-extended to 64 bits.",
  "CALL rel16 is not supported in 64-bit mode.",
  "CALL r/m16 and CALL r/m32 are not encodable in 64-bit mode; CALL r/m64 is the near absolute indirect form for 64-bit mode.",
  "Direct far absolute CALL ptr16:16 and ptr16:32 is invalid in 64-bit mode.",
  "Far CALL direct and indirect forms push CS plus return offset, then load CS and IP/EIP/RIP from the far target or gate.",
  "In protected mode, far CALL resolves the target selector through GDT/LDT descriptor logic: code segment, call gate, task gate, or TSS.",
  "Inter-privilege far CALL must go through a call gate and may switch stacks using TSS state.",
  "CALL task switch sets EFLAGS.NT and records the old task link; JMP task switch does not.",
  "Task switches are not supported in IA-32e mode, including compatibility and 64-bit mode.",
  "In compatibility mode, far CALL may remain in compatibility mode or transition to 64-bit mode based on target descriptor L bit.",
  "In 64-bit mode, far CALL may remain in 64-bit mode or transition to compatibility mode through indirect far forms or 64-bit call gates.",
  "Parameter copy through call gates is not supported in IA-32e mode.",
  "For near indirect CALL, sequential fall-through instructions may be speculatively executed; LFENCE after the CALL can block this software-visible side-channel pattern.",
  "Instructions following a far CALL may be fetched early but do not execute, even speculatively, until prior instructions complete."
]

semantic_near_relative = """
# DEST is rel16 or rel32. IP below means IP/EIP/RIP for the active operand size.
next_ip = instruction_pointer_after_CALL;
if OperandSize == 64:
    tempDEST = sign_extend_32_to_64(DEST);
    tempRIP = next_RIP + tempDEST;
    check_stack_room(bytes = 8) else #SS(0);
    Push(next_RIP);
    if ShadowStackEnabled(CPL) and DEST != 0: ShadowStackPush8B(next_RIP);
    RIP = tempRIP;
elif OperandSize == 32:
    tempEIP = next_EIP + DEST;
    check_code_segment_limit(tempEIP) else #GP(0);
    check_stack_room(bytes = 4) else #SS(0);
    Push(next_EIP);
    if ShadowStackEnabled(CPL) and DEST != 0: ShadowStackPush4B(next_EIP);
    EIP = tempEIP;
elif OperandSize == 16:
    tempEIP = (next_EIP + DEST) & 0xFFFF;
    check_code_segment_limit(tempEIP) else #GP(0);
    check_stack_room(bytes = 2) else #SS(0);
    Push(next_IP);
    if ShadowStackEnabled(CPL) and DEST != 0: ShadowStackPush4B(zero_extend(next_IP));
    EIP = tempEIP;
"""

semantic_near_absolute = """
# DEST is r/m16, r/m32, or r/m64.
# If the memory operand uses ESP/RSP as base, the base value used is the value before CALL stack push.
if OperandSize == 64:
    tempRIP = DEST;
    check_stack_room(bytes = 8) else #SS(0);
    Push(next_RIP);
    if ShadowStackEnabled(CPL): ShadowStackPush8B(next_RIP);
    RIP = tempRIP;
elif OperandSize == 32:
    tempEIP = DEST;
    check_code_segment_limit(tempEIP) else #GP(0);
    check_stack_room(bytes = 4) else #SS(0);
    Push(next_EIP);
    if ShadowStackEnabled(CPL): ShadowStackPush4B(next_EIP);
    EIP = tempEIP;
elif OperandSize == 16:
    tempEIP = DEST & 0xFFFF;
    check_code_segment_limit(tempEIP) else #GP(0);
    check_stack_room(bytes = 2) else #SS(0);
    Push(next_IP);
    if ShadowStackEnabled(CPL): ShadowStackPush4B(zero_extend(next_IP));
    EIP = tempEIP;

if near_absolute_indirect and EndbranchEnabledAndNotSuppressed(CPL):
    if CPL == 3:
        if no_3EH_prefix or IA32_U_CET.NO_TRACK_EN == 0:
            IA32_U_CET.TRACKER = WAIT_FOR_ENDBRANCH;
    else:
        if no_3EH_prefix or IA32_S_CET.NO_TRACK_EN == 0:
            IA32_S_CET.TRACKER = WAIT_FOR_ENDBRANCH;
"""

semantic_far_real_or_v8086 = """
# Applies when PE == 0 or PE == 1 and VM == 1.
# DEST is ptr16:16, ptr16:32, [m16:16], or [m16:32].
if OperandSize == 32:
    check_stack_room(bytes = 6) else #SS(0);
    if DEST.offset[31:16] != 0: #GP(0);
    Push(CS padded to 32-bit stack slot as applicable);
    Push(EIP);
    CS = DEST.segment_selector;
    EIP = DEST.offset32;
elif OperandSize == 16:
    check_stack_room(bytes = 4) else #SS(0);
    Push(CS);
    Push(IP);
    CS = DEST.segment_selector;
    EIP = DEST.offset16;
"""

semantic_far_protected_or_ia32e_dispatch = """
# Applies when PE == 1 and VM == 0.
if target.segment_selector == NULL: #GP(0);
if selector_index_outside_descriptor_table(target.segment_selector): #GP(new_code_segment_selector);
desc = read_descriptor(target.segment_selector);
if IA32_EFER.LMA == 0:
    require desc.type in {conforming_code, nonconforming_code, call_gate, task_gate, TSS} else #GP(selector);
else:
    require desc.type in {conforming_code, nonconforming_code, sixty_four_bit_call_gate} else #GP(selector);

dispatch desc.type:
    conforming_code_segment -> semantic_conforming_code_segment;
    nonconforming_code_segment -> semantic_nonconforming_code_segment;
    call_gate -> semantic_call_gate;
    task_gate -> semantic_task_gate;
    task_state_segment -> semantic_task_state_segment;
"""

semantic_conforming_code_segment = """
if IA32_EFER.LMA == 1 and descriptor.L == 1 and descriptor.D == 1: #GP(new_code_segment_selector);
if descriptor.DPL > CPL: #GP(new_code_segment_selector);
if not descriptor.present: #NP(new_code_segment_selector);
check_stack_room(return_address_size) else #SS(0);
tempEIP = DEST.offset;
if target_mode == compatibility: tempEIP &= 0xFFFFFFFF;
if OperandSize == 16: tempEIP &= 0xFFFF;
if (IA32_EFER.LMA == 0 or target_mode == compatibility) and outside_code_segment_limit(tempEIP): #GP(0);
if non_canonical(tempEIP): #GP(0);
prepare_shadow_stack_far_return_if_enabled();
Push(CS); Push(return_IP_for_operand_size);
CS = DEST.code_segment_selector; CS.RPL = CPL;
IP_EIP_RIP = tempEIP;
update_shadow_stack_far_call_same_privilege_if_enabled();
set_endbranch_tracker_if_enabled(CPL);
"""

semantic_nonconforming_code_segment = """
if IA32_EFER.LMA == 1 and descriptor.L == 1 and descriptor.D == 1: #GP(new_code_segment_selector);
if target_selector.RPL > CPL or descriptor.DPL != CPL: #GP(new_code_segment_selector);
if not descriptor.present: #NP(new_code_segment_selector);
check_stack_room(return_address_size) else #SS(0);
tempEIP = DEST.offset;
if target_mode == compatibility: tempEIP &= 0xFFFFFFFF;
if OperandSize == 16: tempEIP &= 0xFFFF;
if (IA32_EFER.LMA == 0 or target_mode == compatibility) and outside_code_segment_limit(tempEIP): #GP(0);
if non_canonical(tempEIP): #GP(0);
prepare_shadow_stack_far_return_if_enabled();
Push(CS); Push(return_IP_for_operand_size);
CS = DEST.code_segment_selector; CS.RPL = CPL;
IP_EIP_RIP = tempEIP;
update_shadow_stack_far_call_same_privilege_if_enabled();
set_endbranch_tracker_if_enabled(CPL);
"""

semantic_call_gate = """
# The target offset embedded in the far pointer is ignored when a call gate is used.
if call_gate.DPL < CPL or call_gate.selector.RPL > call_gate.DPL: #GP(call_gate_selector);
if not call_gate.present: #NP(call_gate_selector);
if call_gate.code_segment_selector == NULL: #GP(0);
if call_gate.code_segment_selector outside descriptor table: #GP(call_gate_code_segment_selector);
code_desc = read_descriptor(call_gate.code_segment_selector);
if not code_desc.is_code_segment or code_desc.DPL > CPL: #GP(call_gate_code_segment_selector);
if IA32_EFER.LMA == 1 and (not code_desc.is_64_bit_code_segment or (code_desc.L == 1 and code_desc.D == 1)): #GP(call_gate_code_segment_selector);
if not code_desc.present: #NP(call_gate_code_segment_selector);
if code_desc.nonconforming and code_desc.DPL < CPL:
    goto MORE_PRIVILEGE;
else:
    goto SAME_PRIVILEGE;
"""

semantic_more_privilege = """
# Inter-privilege CALL through call gate. Stack switch uses current TSS.
load_new_stack_from_TSS_for_new_CPL() else #TS(selector_or_current_TSS);
validate_new_stack_segment_unless_IA32e() else #TS/#SS;
if CallGateSize == 32:
    check_new_stack_room(parameter_bytes + 16) else #SS(NewSS);
    check_call_gate_target_within_limit() else #GP(0);
    SS = NewSS; ESP = NewESP; CS:EIP = call_gate_target;
    Push(oldSS:oldESP); copy_call_gate_parameters(masked_count_5_bits); Push(oldCS:oldEIP);
elif CallGateSize == 16:
    check_new_stack_room(parameter_bytes + 8) else #SS(NewSS);
    check_call_gate_target_within_limit_16() else #GP(0);
    SS = NewSS; ESP = NewESP; CS:IP = call_gate_target;
    Push(oldSS:oldESP); copy_call_gate_parameters(masked_count_5_bits); Push(oldCS:oldEIP);
elif CallGateSize == 64:
    check_push_32_bytes_canonical() else #SS(NewSS);
    check_call_gate_target_canonical() else #GP(0);
    SS = NULL_selector_with_new_CPL_RPL; RSP = NewRSP; CS:RIP = call_gate_target;
    Push(oldSS:oldRSP); Push(oldCS:oldRIP);
update_PL3_SSP_on_ring3_exit_if_required();
CPL = code_desc.DPL; CS.RPL = CPL;
switch_and_validate_shadow_stack_for_new_CPL_if_enabled();
set_supervisor_endbranch_tracker_if_enabled();
"""

semantic_same_privilege = """
# CALL through call gate without privilege-level change.
if CallGateSize == 32:
    check_stack_room(bytes = 8) else #SS(0);
    check_call_gate_target_within_limit() else #GP(0);
    CS:EIP = call_gate_target;
    Push(oldCS:oldEIP);
elif CallGateSize == 16:
    check_stack_room(bytes = 4) else #SS(0);
    check_call_gate_target_within_limit() else #GP(0);
    CS:IP = call_gate_target;
    Push(oldCS:oldIP);
elif CallGateSize == 64:
    check_push_16_bytes_canonical() else #SS(0);
    check_RIP_canonical() else #GP(0);
    CS:RIP = call_gate_target;
    Push(oldCS:oldRIP);
CS.RPL = CPL;
update_shadow_stack_far_call_same_privilege_if_enabled();
set_endbranch_tracker_if_enabled(CPL);
"""

semantic_task_gate = """
if task_gate.DPL < CPL or task_gate.selector.RPL > task_gate.DPL: #GP(task_gate_selector);
if not task_gate.present: #NP(task_gate_selector);
tss_selector = task_gate.TSS_selector;
if tss_selector.local or tss_selector.index_outside_GDT: #GP(TSS_selector);
tss_desc = read_GDT_descriptor(tss_selector);
if not tss_desc.is_TSS: #GP(TSS_selector);
if tss_desc.busy: #GP(TSS_selector);
if not tss_desc.present: #NP(TSS_selector);
SWITCH_TASKS(with_nesting = true, new_TSS = tss_selector);
# CALL task switch sets NT and previous task link.
EFLAGS.NT = 1;
new_TSS.previous_task_link = old_TSS_selector;
if EIP outside new code segment limit: #GP(0);
"""

semantic_task_state_segment = """
if TSS.DPL < CPL or target_selector.RPL > TSS.DPL or TSS.not_available: #GP(TSS_selector);
if not TSS.present: #NP(TSS_selector);
SWITCH_TASKS(with_nesting = true, new_TSS = TSS_selector);
EFLAGS.NT = 1;
new_TSS.previous_task_link = old_TSS_selector;
if EIP outside new code segment limit: #GP(0);
"""

cet_contract = [
  "Near CALL pushes a return address onto the architectural stack and, when CET shadow stack is enabled, also pushes the return address onto the shadow stack.",
  "Near relative CALL with DEST == 0 suppresses the shadow-stack push according to the documented operation.",
  "Near indirect CALL can set the ENDBRANCH tracker to WAIT_FOR_ENDBRANCH when endbranch tracking is enabled and not suppressed.",
  "Far CALL to code segment or through call gate updates shadow stack with CS:LIP:oldSSP records when shadow stack is enabled.",
  "For legacy or compatibility targets, SSP must be in low 4GB when shadow stack is enabled.",
  "Privilege-changing call gates validate/switch IA32_PLi_SSP, token alignment, natural 32-byte region containment, busy token state, and SSP token match."
]

arm64_lowering_contract = """
# Rosette/Rosetta 3 lowering intent:
# CALL is not just a branch. It must preserve x86 return-link semantics by writing the x86 return address to the emulated x86 stack.
# For near CALL, lower to:
#   1. compute next_x86_ip
#   2. compute target_x86_ip
#   3. decrement emulated x86 SP by return-address width
#   4. store next_x86_ip at emulated x86 stack
#   5. update emulated RIP/EIP/IP to target
#   6. branch in host dispatcher to translated target block
# ARM64 BL/LR may be used only for host helper calls; it must not replace the x86 architectural return-address push.
# Far CALL requires an emulated segmentation/descriptor path. In user-mode app translation this may usually trap, emulate, or reject unless Rosette has descriptor-table state.
# Inter-privilege CALL and task-switch CALL require privileged CPU state/TSS emulation and should be routed to a full system/OS compatibility path, not a simple user-mode branch lowering.
"""

exceptions = {
  protected_mode = {
    GP_0 = [
      "Target offset in destination operand is beyond the new code segment limit.",
      "Segment selector in destination operand is NULL.",
      "Code segment selector in gate is NULL.",
      "Memory operand effective address is outside CS, DS, ES, FS, or GS segment limit.",
      "DS, ES, FS, or GS is used to access memory and contains a NULL segment selector.",
      "Target mode is compatibility mode and SSP is not in low 4GB.",
      "SSP in IA32_PLi_SSP for the new CPL is not 8-byte aligned.",
      "Token and stack frame pushed on shadow stack are not contained in a naturally aligned 32-byte region.",
      "Supervisor shadow-stack token on new shadow stack is marked busy.",
      "Destination mode is 32-bit or compatibility mode but supervisor shadow-stack token SSP is beyond 4GB.",
      "Supervisor shadow-stack token SSP does not match IA32_PLi_SSP for the new CPL."
    ],
    GP_selector = [
      "Code segment, gate, or TSS selector index is outside descriptor table limits.",
      "Descriptor is not a conforming-code segment, nonconforming-code segment, call gate, task gate, or TSS.",
      "Nonconforming code segment DPL is not equal to CPL or selector RPL is greater than CPL.",
      "Conforming code segment DPL is greater than CPL.",
      "Call-gate, task-gate, or TSS DPL is less than CPL or less than selector RPL.",
      "Segment selector from call gate does not indicate a code segment.",
      "Segment selector from call gate is beyond descriptor table limits.",
      "DPL for code segment obtained from call gate is greater than CPL.",
      "TSS selector has local/global bit set to local.",
      "TSS descriptor specifies busy or not available."
    ],
    SS_0 = [
      "Pushing return address, parameters, or stack segment pointer exceeds stack bounds when no stack switch occurs.",
      "Memory operand effective address is outside SS segment limit."
    ],
    SS_selector = [
      "Pushing return address, parameters, or stack segment pointer exceeds stack bounds when a stack switch occurs.",
      "SS loaded during stack switch points to not-present segment.",
      "Stack segment does not have room for required pushed values during stack switch."
    ],
    NP_selector = ["Code segment, data segment, call gate, task gate, or TSS is not present."],
    TS_selector = [
      "New stack segment selector and ESP are beyond end of TSS.",
      "New stack segment selector is NULL.",
      "RPL of new stack selector in TSS is not equal to DPL of accessed code segment.",
      "DPL of new stack segment descriptor is not equal to DPL of code segment descriptor.",
      "New stack segment is not a writable data segment.",
      "Stack segment selector index is outside descriptor table limits."
    ],
    PF = ["Page fault occurs."],
    AC_0 = ["Alignment checking is enabled and an unaligned memory reference is made while CPL is 3."],
    UD = ["LOCK prefix is used."]
  },
  real_address_mode = {
    GP = ["Memory operand effective address is outside CS, DS, ES, FS, or GS segment limit.", "Target offset is beyond code segment limit."],
    UD = ["LOCK prefix is used."]
  },
  virtual_8086_mode = {
    GP_0 = ["Memory operand effective address is outside CS, DS, ES, FS, or GS segment limit.", "Target offset is beyond code segment limit."],
    PF = ["Page fault occurs."],
    AC_0 = ["Alignment checking is enabled and an unaligned memory reference is made."],
    UD = ["LOCK prefix is used."]
  },
  compatibility_mode = {
    same_as = "protected_mode",
    GP_selector = ["Memory address accessed by selector is in non-canonical space."],
    GP_0 = ["Target offset in destination operand is non-canonical."]
  },
  mode64 = {
    GP_0 = [
      "Memory address is non-canonical.",
      "Target offset in destination operand is non-canonical.",
      "Segment selector in destination operand is NULL.",
      "Code segment selector in 64-bit gate is NULL.",
      "Target mode is compatibility mode and SSP is not in low 4GB.",
      "SSP in IA32_PLi_SSP for new CPL is not 8-byte aligned.",
      "Token and stack frame pushed on shadow stack are not contained in a naturally aligned 32-byte region.",
      "Supervisor shadow-stack token on new shadow stack is marked busy.",
      "Destination mode is 32-bit or compatibility mode but supervisor shadow-stack token SSP is beyond 4GB.",
      "Supervisor shadow-stack token SSP does not match IA32_PLi_SSP for new CPL."
    ],
    GP_selector = [
      "Code segment or 64-bit call gate is outside descriptor table limits.",
      "Code segment or 64-bit call gate overlaps non-canonical space.",
      "Descriptor is not a conforming-code segment, nonconforming-code segment, or 64-bit call gate.",
      "Code segment descriptor has both D-bit and L-bit set.",
      "Nonconforming code DPL is not equal to CPL or selector RPL is greater than CPL.",
      "Conforming code DPL is greater than CPL.",
      "64-bit call-gate DPL is less than CPL or less than call-gate selector RPL.",
      "Upper type field of 64-bit call gate is not 0x0.",
      "Segment selector from 64-bit call gate is beyond descriptor table limits.",
      "DPL for code segment obtained from 64-bit call gate is greater than CPL.",
      "Code segment descriptor pointed to by selector in 64-bit gate does not have L-bit set and D-bit clear.",
      "Segment descriptor for selector from 64-bit call gate does not indicate a code segment."
    ],
    SS_0 = [
      "Pushing return offset or CS selector onto stack exceeds stack segment bounds when no stack switch occurs.",
      "Memory operand effective address is outside SS segment limit.",
      "Stack address is non-canonical."
    ],
    SS_selector = ["Pushing old SS selector, stack pointer, EFLAGS, CS selector, offset, or error code violates canonical boundary during stack switch."],
    NP_selector = ["Code segment or 64-bit call gate is not present."],
    TS_selector = ["Load of new RSP exceeds TSS limit."],
    UD = ["Far call direct to an absolute address in memory in 64-bit mode.", "LOCK prefix is used."],
    PF = ["Page fault occurs."],
    AC_0 = ["Alignment checking is enabled and an unaligned memory reference is made while CPL is 3."]
  }
}

validation_checklist = [
  "Decode /2 as near absolute indirect CALL and /3 as far absolute indirect CALL.",
  "Reject direct far CALL forms in 64-bit mode.",
  "For near CALL, always push the x86 return address before updating IP.",
  "For 16-bit operand size, clear upper EIP bits after target calculation.",
  "For 64-bit near relative CALL, sign-extend rel32 to 64 bits.",
  "Preserve ESP/RSP pre-instruction base behavior when indirect operand uses stack pointer as base.",
  "Route far CALL through segmentation/descriptor model rather than treating it as a plain branch.",
  "Handle call gates, privilege transitions, stack switches, TSS task switches, and CET shadow stack separately from near calls.",
  "Task-switch CALL sets NT and previous-task link; this differs from JMP task switch.",
  "LOCK prefix must raise #UD."
]
