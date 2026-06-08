// RET/RET.inc
// ARM64/NEON translation mirror generated from ISA/x86/RET/RET.inc.
// This file preserves the full x86 RET instruction contract, then appends the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "RET/RET.inc"
x86_handler = "x86_ret"
neon_lowering = "arm64_ret_pop_return_and_restore_control_flow"
lowering_kind = "arm64_control_flow_stack"

name = "RET"
category = "control_flow_return"
operation = "return from procedure by popping a return address from the stack, optionally releasing parameter bytes, and optionally restoring CS/SS privilege state for far returns"

encodings = [
  { opcode = "C3", form = "RET", op_en = "ZO", mode64 = "valid", compat = "valid", return_kind = "near", imm = "none", description = "Near return to calling procedure." },
  { opcode = "CB", form = "RET", op_en = "ZO", mode64 = "valid", compat = "valid", return_kind = "far", imm = "none", description = "Far return to calling procedure." },
  { opcode = "C2 iw", form = "RET imm16", op_en = "I", mode64 = "valid", compat = "valid", return_kind = "near", imm = 16, description = "Near return to calling procedure and pop imm16 bytes from stack." },
  { opcode = "CA iw", form = "RET imm16", op_en = "I", mode64 = "valid", compat = "valid", return_kind = "far", imm = 16, description = "Far return to calling procedure and pop imm16 bytes from stack." }
]

operand_encoding = [
  { op_en = "ZO", operand1 = "N/A", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "I", operand1 = "imm16", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
]

reads = ["stack return address", "optional imm16", "CS for far returns", "SS/RSP/ESP/SP", "descriptor tables for protected/IA-32e far returns"]
writes = ["RIP/EIP/IP", "RSP/ESP/SP", "CS for far returns", "SS for inter-privilege far returns", "DS/ES/FS/GS may be cleared on privilege return"]
implicit_reads = ["CPL", "CS", "SS", "stack pointer", "IA32_EFER.LMA", "PE", "VM", "descriptor tables", "shadow stack state when CET is enabled"]
implicit_writes = ["instruction pointer", "stack pointer", "CS on far return", "SS on outer privilege far return", "CPL on outer privilege far return", "shadow stack pointer/token when CET shadow stack is enabled", "DS/ES/FS/GS invalidation on privilege return"]
flags_read = []
flags_written = []
flags_affected = "None."
lock_allowed = false

return_types = [
  "near_return_current_code_segment",
  "far_return_different_code_segment",
  "inter_privilege_level_far_return_protected_mode_only"
]

mode_notes = [
  "RET transfers control to a return address located on the top of the stack, normally pushed by CALL.",
  "RET imm16 additionally releases the specified number of stack bytes after popping the return address or far return frame.",
  "RET imm16 is required when returning from a call gate whose word count copied parameters to the called procedure stack; the immediate must match the call gate byte count requirement.",
  "Near RET pops only the return offset and does not modify CS.",
  "Far RET pops return offset and CS, then resumes execution in the selected code segment.",
  "Inter-privilege far RET additionally restores SS and stack pointer from the return frame and may clear DS, ES, FS, and GS if their cached descriptors are not accessible at the new privilege level.",
  "In 64-bit mode, near RET defaults to the stack-address size, normally 64 bits.",
  "In 64-bit mode, far RET default operation size is 32 bits unless overridden by the active operand-size semantics.",
  "Instructions following a far RET may be fetched early, but do not execute, even speculatively, until prior instructions complete.",
  "Unlike near indirect CALL/JMP, the processor does not speculatively execute the next sequential instruction after near RET unless that instruction is also a branch target or predictor target."
]

semantic_near_return = """
# Near RET: pop return offset from stack; CS is unchanged.
if OperandSize == 32:
    check_stack_top(bytes = 4) else #SS(0);
    EIP = Pop32();
    if ShadowStackEnabled(CPL):
        tempSsEIP = ShadowStackPop4B();
        if EIP != tempSsEIP: #CP(NEAR_RET);
elif OperandSize == 64:
    check_stack_top(bytes = 8) else #SS(0);
    RIP = Pop64();
    if ShadowStackEnabled(CPL):
        tempSsRIP = ShadowStackPop8B();
        if RIP != tempSsRIP: #CP(NEAR_RET);
elif OperandSize == 16:
    check_stack_top(bytes = 2) else #SS(0);
    tempEIP = Pop16() & 0xFFFF;
    check_code_segment_limit(tempEIP) else #GP(0);
    EIP = tempEIP;
    if ShadowStackEnabled(CPL):
        tempSsEIP = ShadowStackPop4B();
        if EIP != tempSsEIP: #CP(NEAR_RET);

if has_imm16:
    if StackAddressSize == 64: RSP += SRC;
    elif StackAddressSize == 32: ESP += SRC;
    elif StackAddressSize == 16: SP += SRC;
"""

semantic_far_real_or_v8086 = """
# Applies when (PE == 0) or (PE == 1 and VM == 1) and instruction is far RET.
if OperandSize == 32:
    check_stack_top(bytes = 8) else #SS(0);
    EIP = Pop32();
    CS = Pop32() & 0xFFFF;
elif OperandSize == 16:
    check_stack_top(bytes = 4) else #SS(0);
    tempEIP = Pop16() & 0xFFFF;
    check_code_segment_limit(tempEIP) else #GP(0);
    EIP = tempEIP;
    CS = Pop16();

if has_imm16:
    SP = SP + (SRC & 0xFFFF);
"""

semantic_far_protected_dispatch = """
# Applies when PE == 1, VM == 0, IA32_EFER.LMA == 0, and instruction is far RET.
if OperandSize == 32:
    check_second_doubleword_on_stack() else #SS(0);
elif OperandSize == 16:
    check_second_word_on_stack() else #SS(0);

if return_code_segment_selector == NULL: #GP(0);
if selector_outside_descriptor_table(return_code_segment_selector): #GP(selector);
return_code_desc = read_descriptor(return_code_segment_selector);
if not return_code_desc.is_code_segment: #GP(selector);
if return_code_segment_selector.RPL < CPL: #GP(selector);
if return_code_desc.conforming and return_code_desc.DPL > return_code_segment_selector.RPL: #GP(selector);
if return_code_desc.nonconforming and return_code_desc.DPL != return_code_segment_selector.RPL: #GP(selector);
if not return_code_desc.present: #NP(selector);

if return_code_segment_selector.RPL > CPL:
    goto RETURN_TO_OUTER_PRIVILEGE_LEVEL;
else:
    goto RETURN_TO_SAME_PRIVILEGE_LEVEL;
"""

semantic_return_to_same_privilege_legacy = """
# Protected mode, same privilege far RET.
check_return_ip_within_return_code_segment_limit() else #GP(0);
if OperandSize == 32:
    EIP = Pop32();
    CS = Pop32() & 0xFFFF;
elif OperandSize == 16:
    EIP = Pop16() & 0xFFFF;
    CS = Pop16();

if has_imm16:
    if StackAddressSize == 32: ESP += SRC;
    elif StackAddressSize == 16: SP += SRC;

if ShadowStackEnabled(CPL):
    require (SSP & 0x7) == 0 else #CP(FAR_RET_IRET);
    tempSsCS = shadow_stack_load8(SSP + 16);
    tempSsLIP = shadow_stack_load8(SSP + 8);
    prevSSP = shadow_stack_load8(SSP);
    SSP += 24;
    if zero_extend64(CS) != tempSsCS: #CP(FAR_RET_IRET);
    if CSBASE + EIP != tempSsLIP: #CP(FAR_RET_IRET);
    if (prevSSP & 0x3) != 0: #CP(FAR_RET_IRET);
    if prevSSP[63:32] != 0: #GP(0);
    SSP = prevSSP;
"""

semantic_return_to_outer_privilege_legacy = """
# Protected mode, outer privilege far RET.
if OperandSize == 32:
    check_stack_top(bytes = 16 + SRC) else #SS(0);
elif OperandSize == 16:
    check_stack_top(bytes = 8 + SRC) else #SS(0);

read_return_stack_segment_selector();
if stack_segment_selector == NULL: #GP(0);
if stack_selector_outside_descriptor_table(): #GP(selector);
stack_desc = read_stack_descriptor();
if stack_selector.RPL != return_code_selector.RPL or not stack_desc.writable_data or stack_desc.DPL != return_code_selector.RPL: #GP(selector);
if not stack_desc.present: #SS(StackSegmentSelector);
check_return_ip_within_return_code_segment_limit() else #GP(0);

if OperandSize == 32:
    EIP = Pop32();
    CS = Pop32() & 0xFFFF; CS.RPL = return_code_selector.RPL;
    if has_imm16: adjust_current_stack_by_SRC();
    tempESP = Pop32();
    tempSS = Pop32() & 0xFFFF;
elif OperandSize == 16:
    EIP = Pop16() & 0xFFFF;
    CS = Pop16(); CS.RPL = return_code_selector.RPL;
    if has_imm16: adjust_current_stack_by_SRC();
    tempESP = Pop16();
    tempSS = Pop16();

if ShadowStackEnabled(CPL):
    require (SSP & 0x7) == 0 else #CP(FAR_RET_IRET);
    if return_code_selector.RPL != 3:
        tempSsCS = shadow_stack_load8(SSP + 16);
        tempSsLIP = shadow_stack_load8(SSP + 8);
        tempSSP = shadow_stack_load8(SSP);
        SSP += 24;
        if zero_extend64(CS) != tempSsCS: #CP(FAR_RET_IRET);
        if CSBASE + EIP != tempSsLIP: #CP(FAR_RET_IRET);
        if (tempSSP & 0x3) != 0: #CP(FAR_RET_IRET);

tempOldCPL = CPL;
CPL = return_code_selector.RPL;
ESP = tempESP;
SS = tempSS;
tempOldSSP = SSP;
if ShadowStackEnabled(CPL):
    if CPL == 3: tempSSP = IA32_PL3_SSP;
    if tempSSP[63:32] != 0: #GP(0);
    SSP = tempSSP;
if ShadowStackEnabled(tempOldCPL):
    free_shadow_stack_token_at_old_SSP(tempOldSSP);

for SegReg in [ES, FS, GS, DS]:
    if segreg_null_or_descriptor_inaccessible_at_new_CPL(SegReg, CPL):
        SegReg.selector = 0;

if has_imm16:
    # Release parameters from the calling procedure stack after stack switch.
    if StackAddressSize == 32: ESP += SRC;
    elif StackAddressSize == 16: SP += SRC;
"""

semantic_far_ia32e_dispatch = """
# Applies when PE == 1, VM == 0, IA32_EFER.LMA == 1, and instruction is far RET.
if OperandSize == 32:
    check_second_doubleword_on_stack() else #SS(0);
    check_first_or_second_doubleword_canonical() else #SS(0);
elif OperandSize == 16:
    check_second_word_on_stack() else #SS(0);
    check_first_or_second_word_canonical() else #SS(0);
elif OperandSize == 64:
    check_first_or_second_quadword_canonical() else #SS(0);

if return_code_segment_selector == NULL: #GP(0);
if selector_outside_descriptor_table(return_code_segment_selector): #GP(selector);
if selector_descriptor_address_noncanonical(return_code_segment_selector): #GP(selector);
return_code_desc = read_descriptor(return_code_segment_selector);
if not return_code_desc.is_code_segment: #GP(selector);
if return_code_desc.L == 1 and return_code_desc.D == 1: #GP(selector);
if return_code_segment_selector.RPL < CPL: #GP(selector);
if return_code_desc.conforming and return_code_desc.DPL > return_code_segment_selector.RPL: #GP(selector);
if return_code_desc.nonconforming and return_code_desc.DPL != return_code_segment_selector.RPL: #GP(selector);
if not return_code_desc.present: #NP(selector);

if return_code_segment_selector.RPL > CPL:
    goto IA32E_RETURN_TO_OUTER_PRIVILEGE_LEVEL;
else:
    goto IA32E_RETURN_TO_SAME_PRIVILEGE_LEVEL;
"""

semantic_ia32e_same_privilege = """
check_return_ip_within_return_code_segment_limit() else #GP(0);
check_return_ip_canonical() else #GP(0);
if OperandSize == 32:
    EIP = Pop32();
    CS = Pop32() & 0xFFFF;
elif OperandSize == 16:
    EIP = Pop16() & 0xFFFF;
    CS = Pop16();
elif OperandSize == 64:
    RIP = Pop64();
    CS = Pop64() & 0xFFFF;

if has_imm16:
    if StackAddressSize == 64: RSP += SRC;
    elif StackAddressSize == 32: ESP += SRC;
    elif StackAddressSize == 16: SP += SRC;

if ShadowStackEnabled(CPL):
    require (SSP & 0x7) == 0 else #CP(FAR_RET_IRET);
    tempSsCS = shadow_stack_load8(SSP + 16);
    tempSsLIP = shadow_stack_load8(SSP + 8);
    tempSSP = shadow_stack_load8(SSP);
    SSP += 24;
    if zero_extend64(CS) != tempSsCS: #CP(FAR_RET_IRET);
    if CSBASE + RIP != tempSsLIP: #CP(FAR_RET_IRET);
    if (tempSSP & 0x3) != 0: #CP(FAR_RET_IRET);
    if (CS.L == 0 and tempSSP[63:32] != 0) or (CS.L == 1 and not canonical_for_current_paging(tempSSP)): #GP(0);
    SSP = tempSSP;
"""

semantic_ia32e_outer_privilege = """
if OperandSize == 32:
    check_stack_top(bytes = 16 + SRC) else #SS(0);
    check_stack_top_canonical(bytes = 16 + SRC) else #SS(0);
elif OperandSize == 16:
    check_stack_top(bytes = 8 + SRC) else #SS(0);
    check_stack_top_canonical(bytes = 8 + SRC) else #SS(0);
elif OperandSize == 64:
    check_stack_top_canonical(bytes = 32 + SRC) else #SS(0);

read_return_stack_segment_selector();
if stack_segment_selector == NULL:
    if new_CS_descriptor.L == 0: #GP(selector);
    if stack_segment_selector.RPL == 3: #GP(selector);
if stack_descriptor_outside_table(): #GP(selector);
if stack_descriptor_address_noncanonical(): #GP(selector);
stack_desc = read_stack_descriptor();
if stack_selector.RPL != return_code_selector.RPL or not stack_desc.writable_data or stack_desc.DPL != return_code_selector.RPL: #GP(selector);
if not stack_desc.present: #SS(StackSegmentSelector);
check_return_ip_within_return_code_segment_limit() else #GP(0);
check_return_ip_canonical() else #GP(0);

if OperandSize == 32:
    EIP = Pop32();
    CS = Pop32() & 0xFFFF; CS.RPL = return_code_selector.RPL;
    if has_imm16: adjust_current_stack_by_SRC();
    tempESP = Pop32();
    tempSS = Pop32() & 0xFFFF;
elif OperandSize == 16:
    EIP = Pop16() & 0xFFFF;
    CS = Pop16(); CS.RPL = return_code_selector.RPL;
    if has_imm16: adjust_current_stack_by_SRC();
    tempESP = Pop16();
    tempSS = Pop16();
elif OperandSize == 64:
    RIP = Pop64();
    CS = Pop64() & 0xFFFF; CS.RPL = return_code_selector.RPL;
    if has_imm16: RSP += SRC;
    tempESP = Pop64();
    tempSS = Pop64() & 0xFFFF;

if ShadowStackEnabled(CPL):
    require (SSP & 0x7) == 0 else #CP(FAR_RET_IRET);
    if return_code_selector.RPL != 3:
        tempSsCS = shadow_stack_load8(SSP + 16);
        tempSsLIP = shadow_stack_load8(SSP + 8);
        tempSSP = shadow_stack_load8(SSP);
        SSP += 24;
        if zero_extend64(CS) != tempSsCS: #CP(FAR_RET_IRET);
        if CSBASE + RIP != tempSsLIP: #CP(FAR_RET_IRET);
        if (tempSSP & 0x3) != 0: #CP(FAR_RET_IRET);

tempOldCPL = CPL;
CPL = return_code_selector.RPL;
ESP_or_RSP = tempESP;
SS = tempSS;
tempOldSSP = SSP;
if ShadowStackEnabled(CPL):
    if CPL == 3: tempSSP = IA32_PL3_SSP;
    if (CS.L == 0 and tempSSP[63:32] != 0) or (CS.L == 1 and not canonical_for_current_paging(tempSSP)): #GP(0);
    SSP = tempSSP;
if ShadowStackEnabled(tempOldCPL):
    free_shadow_stack_token_at_old_SSP(tempOldSSP);

for SegReg in [ES, FS, GS, DS]:
    if segment_register_points_to_data_or_nonconforming_code_and_CPL_exceeds_DPL(SegReg, CPL):
        SegReg.selector = 0;

if has_imm16:
    if StackAddressSize == 64: RSP += SRC;
    elif StackAddressSize == 32: ESP += SRC;
    elif StackAddressSize == 16: SP += SRC;
"""

shadow_stack_contract = [
  "Near RET validates that the normal stack return offset matches the CET shadow-stack return offset when shadow stack is enabled.",
  "Near RET mismatch raises #CP(NEAR_RET).",
  "Far RET and IRET-style shadow-stack frames require SSP 8-byte alignment before frame load.",
  "Far RET compares CS and LIP from the normal control transfer against the shadow-stack CS:LIP frame.",
  "Previous SSP must be 4-byte aligned or #CP(FAR_RET/IRET).",
  "Legacy/compatibility return targets require previous SSP to remain within the low 4GB where documented.",
  "Outer privilege returns may switch SSP using IA32_PL3_SSP or IA32_PLi_SSP and free a busy supervisor shadow-stack token after all faulting checks complete."
]

segment_and_privilege_contract = [
  "Far RET validates the return code-segment selector, descriptor type, RPL, DPL, and present bit before transferring control.",
  "Protected-mode far RET dispatches same-privilege vs outer-privilege returns based on return code selector RPL compared with CPL.",
  "Outer-privilege returns validate and restore SS and stack pointer from the return frame.",
  "Inter-privilege return clears DS/ES/FS/GS selectors if their cached descriptors are data or nonconforming code not accessible at the new CPL.",
  "IA-32e far RET additionally validates canonical descriptor addresses, canonical stack frame references, and the illegal L=1 plus D=1 code descriptor combination."
]

exceptions = {
  protected_mode = [
    "#GP(0) if the return code or stack segment selector is NULL.",
    "#GP(0) if the return instruction pointer is not within the return code segment limit.",
    "#GP(0) if returning to 32-bit or compatibility mode and the previous SSP from shadow stack or IA32_PL3_SSP is beyond 4GB.",
    "#GP(selector) if the RPL of the return code segment selector is less than CPL.",
    "#GP(selector) if the return code or stack segment selector index is outside descriptor table limits.",
    "#GP(selector) if the return code segment descriptor does not indicate a code segment.",
    "#GP(selector) if a nonconforming code segment DPL is not equal to the RPL of the code segment selector.",
    "#GP(selector) if a conforming code segment DPL is greater than the RPL of the code segment selector.",
    "#GP(selector) if the stack segment is not a writable data segment.",
    "#GP(selector) if the stack selector RPL is not equal to the return code selector RPL.",
    "#GP(selector) if the stack descriptor DPL is not equal to the return code selector RPL.",
    "#SS(0) if the top bytes of stack are not within stack limits.",
    "#SS(0) if the return stack segment is not present according to the provided documentation.",
    "#NP(selector) if the return code segment is not present.",
    "#PF(fault-code) if a page fault occurs.",
    "#AC(0) if an unaligned memory access occurs when CPL = 3 and alignment checking is enabled.",
    "#CP(Far-RET/IRET) if previous SSP is not 4-byte aligned or normal/shadow-stack return instruction pointers do not match."
  ],
  real_address_mode = [
    "#GP if the return instruction pointer is not within the return code segment limit.",
    "#SS if the top bytes of stack are not within stack limits."
  ],
  virtual_8086_mode = [
    "#GP(0) if the return instruction pointer is not within the return code segment limit.",
    "#SS(0) if the top bytes of stack are not within stack limits.",
    "#PF(fault-code) if a page fault occurs.",
    "#AC(0) if an unaligned memory access occurs when alignment checking is enabled."
  ],
  compatibility_mode = [
    "Same as 64-bit mode exceptions."
  ],
  mode64 = [
    "#GP(0) if the return instruction pointer is non-canonical.",
    "#GP(0) if the return instruction pointer is not within the return code segment limit.",
    "#GP(0) if the stack segment selector is NULL going back to compatibility mode.",
    "#GP(0) if the stack segment selector is NULL going back to CPL3 64-bit mode.",
    "#GP(0) if a NULL stack segment selector RPL is not equal to CPL going back to non-CPL3 64-bit mode.",
    "#GP(0) if the return code segment selector is NULL.",
    "#GP(0) if returning to 32-bit or compatibility mode and previous SSP from shadow stack or IA32_PL3_SSP is beyond 4GB.",
    "#GP(selector) if the proposed code-segment descriptor does not indicate a code segment.",
    "#GP(selector) if the proposed new code-segment descriptor has both D-bit and L-bit set.",
    "#GP(selector) if the DPL for a nonconforming code segment is not equal to the RPL of the code segment selector.",
    "#GP(selector) if CPL is greater than the RPL of the code segment selector.",
    "#GP(selector) if the DPL of a conforming code segment is greater than the return code selector RPL.",
    "#GP(selector) if a selector index is outside descriptor table limits.",
    "#GP(selector) if a descriptor memory address is non-canonical.",
    "#GP(selector) if the stack segment is not a writable data segment.",
    "#GP(selector) if stack descriptor DPL is not equal to the return code selector RPL.",
    "#GP(selector) if stack selector RPL is not equal to the return code selector RPL.",
    "#SS(0) if popping a value violates the SS limit.",
    "#SS(0) if popping a value causes a non-canonical address reference.",
    "#NP(selector) if the return code or stack segment is not present.",
    "#PF(fault-code) if a page fault occurs.",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made while CPL = 3.",
    "#CP(Far-RET/IRET) if previous SSP is not 4-byte aligned or normal/shadow-stack return instruction pointers do not match."
  ]
}

handler = "x86_ret"
jit_lowering = "arm64_ret_pop_return_and_restore_control_flow"

neon_register_model = """
RET is a control-flow and stack instruction, not a NEON arithmetic operation.
The ARM64 lowering must route through Rosette's x86 stack, segment, descriptor, privilege, and CET models.
All stack reads/pops must be performed with x86 stack-address-size semantics and x86 exception ordering.
"""

neon_assembly = """
# Schematic fast path for common near RET in 64-bit user mode, CET disabled.
ldr xTARGET, [xRSP]
add xRSP, xRSP, #8
br  xTARGET

# RET imm16 fast path additionally adds the decoded immediate after popping the target.
# Far returns, privilege changes, compatibility-mode targets, and CET paths must call the full helper.
"""

lowering_rules = [
  "Do not treat RET as a normal indirect branch only; it consumes a return frame from the x86 stack.",
  "Near RET keeps CS unchanged and pops only IP/EIP/RIP according to operand size.",
  "RET imm16 releases parameters after the return address is popped; far outer-privilege returns release parameters from both called and calling stacks where specified.",
  "Far RET must validate and load CS, and outer-privilege far RET must restore SS and stack pointer.",
  "In 64-bit mode, the near RET default size follows stack-address size; far RET defaults to 32-bit operation size unless overridden by the decoded form.",
  "CET shadow-stack checks must happen on the RET path when enabled and must raise #CP with the documented near/far class.",
  "Descriptor, canonical-address, stack-limit, and privilege checks must preserve Intel ordering as closely as possible.",
  "Segment-register invalidation for DS/ES/FS/GS is required on inter-privilege far returns.",
  "No flags are read or written by RET."
]

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64 lowering must not weaken x86 stack, privilege, segment, CET, canonical-address, or exception behavior.",
  "Common user-mode near RET can be fast-pathed, but all far, CET, compatibility, and privilege-changing cases should fall back to the full helper."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
