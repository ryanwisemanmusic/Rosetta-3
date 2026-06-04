const runtime_abi = @import("runtime_abi_handshake");
const reg_map = @import("../register_mapping.zig");
const bridge = @import("bridge_register_tracing");

var instruction_counter: u64 = 0;

pub fn currentSequence() u64 {
    return instruction_counter;
}

pub fn emitOperationContext(scope: []const u8) void {
    bridge.emitOperationContext(scope);
}

fn logArm64Shadow(tag: []const u8, seq: u64, regs: *const reg_map.RegisterFile) void {
    runtime_abi.common.writeLine(
        "[register-trace][arm64-shadow][{s}] X0=0x{x} X1=0x{x} X2=0x{x} X3=0x{x} SP=0x{x} X29=0x{x} X20=0x{x} X21=0x{x} PC=0x{x} NZCV=0x{x}\n",
        .{ tag, regs.eax, regs.ecx, regs.edx, regs.ebx, regs.esp, regs.ebp, regs.esi, regs.edi, regs.eip, regs.flags.raw() },
    );
    var target = bridge.makeSnapshot(.arm64, .checkpoint, seq, tag);
    target.regs.result = .{ .valid = true, .value = regs.eax };
    target.regs.stack = .{ .valid = true, .value = regs.esp };
    target.regs.frame = .{ .valid = true, .value = regs.ebp };
    target.regs.counter = .{ .valid = true, .value = regs.ecx };
    target.regs.base = .{ .valid = true, .value = regs.ebx };
    target.regs.data = .{ .valid = true, .value = regs.edx };
    target.regs.source = .{ .valid = true, .value = regs.esi };
    target.regs.dest = .{ .valid = true, .value = regs.edi };
    target.regs.instruction = .{ .valid = true, .value = regs.eip };
    target.regs.flags = .{ .valid = true, .value = regs.flags.raw() };
    target.regs.fs_base = .{ .valid = true, .value = regs.fs };
    target.regs.gs_base = .{ .valid = true, .value = regs.gs };
    target.regs.direction_flag = .{ .valid = true, .value = regs.flags.df };
    target.regs.interrupt_flag = .{ .valid = true, .value = regs.flags.if_ };
    target.regs.iopl = .{ .valid = true, .value = regs.flags.iopl };
    target.regs.operand_size_bits = .{ .valid = true, .value = regs.cs_desc.default_operand_bits };
    target.regs.address_size_bits = .{ .valid = true, .value = regs.cs_desc.default_address_bits };
    target.regs.segment_cs_base = .{ .valid = true, .value = regs.cs_desc.base };
    target.regs.segment_cs_limit = .{ .valid = true, .value = regs.cs_desc.limit };
    target.regs.segment_ds_base = .{ .valid = true, .value = regs.ds_desc.base };
    target.regs.segment_ds_limit = .{ .valid = true, .value = regs.ds_desc.limit };
    target.regs.segment_es_base = .{ .valid = true, .value = regs.es_desc.base };
    target.regs.segment_es_limit = .{ .valid = true, .value = regs.es_desc.limit };
    target.regs.segment_ss_base = .{ .valid = true, .value = regs.ss_desc.base };
    target.regs.segment_ss_limit = .{ .valid = true, .value = regs.ss_desc.limit };
    target.regs.mxcsr = .{ .valid = true, .value = regs.fpu.mxcsr };
    target.regs.fpu_control = .{ .valid = true, .value = regs.fpu.control };
    target.regs.fpu_status = .{ .valid = true, .value = regs.fpu.status };
    target.regs.fpu_tag = .{ .valid = true, .value = regs.fpu.tag };
    target.regs.x87_top = .{ .valid = true, .value = regs.fpu.x87_top };
    target.regs.exception_state = .{ .valid = true, .value = regs.pending_exception };
    target.regs.debug_status = .{ .valid = true, .value = regs.debug.dr6 };
    target.regs.debug_control = .{ .valid = true, .value = regs.debug.dr7 };
    bridge.reportSnapshot(target);
}

pub fn init() void {
    runtime_abi.common.acquire();
    instruction_counter = 0;
    runtime_abi.common.writeLine("# [register-trace][x86] init\n", .{});
}

pub fn deinit() void {
    runtime_abi.common.writeLine("# [register-trace][x86] instructions={d}\n", .{instruction_counter});
    runtime_abi.common.release();
}

pub fn logCheckpoint(tag: []const u8, regs: *const reg_map.RegisterFile, mem_base: u32, mem_len: usize) void {
    runtime_abi.common.writeLine(
        "[register-trace][x86][{s}] EAX=0x{x} ECX=0x{x} EDX=0x{x} EBX=0x{x} ESP=0x{x} EBP=0x{x} ESI=0x{x} EDI=0x{x} EIP=0x{x} EFLAGS=0x{x}\n",
        .{ tag, regs.eax, regs.ecx, regs.edx, regs.ebx, regs.esp, regs.ebp, regs.esi, regs.edi, regs.eip, regs.flags.raw() },
    );
    runtime_abi.common.writeLine(
        "[register-trace][x86][{s}] CS=0x{x} DS=0x{x} ES=0x{x} FS=0x{x} GS=0x{x} SS=0x{x} MEM=[0x{x}..0x{x}] FPU=unmodeled SIMD=unmodeled\n",
        .{ tag, regs.cs, regs.ds, regs.es, regs.fs, regs.gs, regs.ss, mem_base, @as(u64, mem_base) + mem_len },
    );
    runtime_abi.common.writeLine(
        "[register-trace][x86][{s}] DF={d} IF={d} IOPL={d} CS(base=0x{x},limit=0x{x},op={d},addr={d}) SS(base=0x{x},limit=0x{x}) FS(base=0x{x}) GS(base=0x{x})\n",
        .{
            tag,
            regs.flags.df,
            regs.flags.if_,
            regs.flags.iopl,
            regs.cs_desc.base,
            regs.cs_desc.limit,
            regs.cs_desc.default_operand_bits,
            regs.cs_desc.default_address_bits,
            regs.ss_desc.base,
            regs.ss_desc.limit,
            regs.fs_desc.base,
            regs.gs_desc.base,
        },
    );
    runtime_abi.common.writeLine(
        "[register-trace][x86][{s}] MXCSR=0x{x} FPU(ctrl=0x{x},status=0x{x},tag=0x{x},top={d},lazy={d}) DR6=0x{x} DR7=0x{x} pending_exception=0x{x}\n",
        .{ tag, regs.fpu.mxcsr, regs.fpu.control, regs.fpu.status, regs.fpu.tag, regs.fpu.x87_top, @intFromBool(regs.fpu.lazy), regs.debug.dr6, regs.debug.dr7, regs.pending_exception },
    );
    var snap = bridge.makeSnapshot(.x86, .checkpoint, instruction_counter, tag);
    snap.regs.result = .{ .valid = true, .value = regs.eax };
    snap.regs.stack = .{ .valid = true, .value = regs.esp };
    snap.regs.frame = .{ .valid = true, .value = regs.ebp };
    snap.regs.counter = .{ .valid = true, .value = regs.ecx };
    snap.regs.base = .{ .valid = true, .value = regs.ebx };
    snap.regs.data = .{ .valid = true, .value = regs.edx };
    snap.regs.source = .{ .valid = true, .value = regs.esi };
    snap.regs.dest = .{ .valid = true, .value = regs.edi };
    snap.regs.instruction = .{ .valid = true, .value = regs.eip };
    snap.regs.flags = .{ .valid = true, .value = regs.flags.raw() };
    snap.regs.segment_cs = .{ .valid = true, .value = regs.cs };
    snap.regs.segment_ds = .{ .valid = true, .value = regs.ds };
    snap.regs.segment_es = .{ .valid = true, .value = regs.es };
    snap.regs.segment_ss = .{ .valid = true, .value = regs.ss };
    snap.regs.fs_base = .{ .valid = true, .value = regs.fs };
    snap.regs.gs_base = .{ .valid = true, .value = regs.gs };
    snap.regs.direction_flag = .{ .valid = true, .value = regs.flags.df };
    snap.regs.interrupt_flag = .{ .valid = true, .value = regs.flags.if_ };
    snap.regs.iopl = .{ .valid = true, .value = regs.flags.iopl };
    snap.regs.operand_size_bits = .{ .valid = true, .value = regs.cs_desc.default_operand_bits };
    snap.regs.address_size_bits = .{ .valid = true, .value = regs.cs_desc.default_address_bits };
    snap.regs.segment_cs_base = .{ .valid = true, .value = regs.cs_desc.base };
    snap.regs.segment_cs_limit = .{ .valid = true, .value = regs.cs_desc.limit };
    snap.regs.segment_ds_base = .{ .valid = true, .value = regs.ds_desc.base };
    snap.regs.segment_ds_limit = .{ .valid = true, .value = regs.ds_desc.limit };
    snap.regs.segment_es_base = .{ .valid = true, .value = regs.es_desc.base };
    snap.regs.segment_es_limit = .{ .valid = true, .value = regs.es_desc.limit };
    snap.regs.segment_ss_base = .{ .valid = true, .value = regs.ss_desc.base };
    snap.regs.segment_ss_limit = .{ .valid = true, .value = regs.ss_desc.limit };
    snap.regs.mxcsr = .{ .valid = true, .value = regs.fpu.mxcsr };
    snap.regs.fpu_control = .{ .valid = true, .value = regs.fpu.control };
    snap.regs.fpu_status = .{ .valid = true, .value = regs.fpu.status };
    snap.regs.fpu_tag = .{ .valid = true, .value = regs.fpu.tag };
    snap.regs.x87_top = .{ .valid = true, .value = regs.fpu.x87_top };
    snap.regs.exception_state = .{ .valid = true, .value = regs.pending_exception };
    snap.regs.debug_status = .{ .valid = true, .value = regs.debug.dr6 };
    snap.regs.debug_control = .{ .valid = true, .value = regs.debug.dr7 };
    bridge.reportSnapshot(snap);
    logArm64Shadow(tag, instruction_counter, regs);
}

pub fn logInstructionBoundary(phase: []const u8, opcode_name: []const u8, start_eip: u32, regs: *const reg_map.RegisterFile, mem_base: u32, mem_len: usize) void {
    if (phase.len >= 3 and phase[0] == 'p' and phase[1] == 'r' and phase[2] == 'e') {
        instruction_counter += 1;
    }
    runtime_abi.common.writeLine(
        "[register-trace][x86][{s}] step={d} opcode={s} start_eip=0x{x}\n",
        .{ phase, instruction_counter, opcode_name, start_eip },
    );
    logCheckpoint(phase, regs, mem_base, mem_len);
}

pub fn logControlTransfer(kind: []const u8, source_eip: u32, target_eip: u32, regs: *const reg_map.RegisterFile) void {
    runtime_abi.common.writeLine(
        "[register-trace][x86][control] {s} src=0x{x} dst=0x{x} ESP=0x{x} EBP=0x{x} EFLAGS=0x{x}\n",
        .{ kind, source_eip, target_eip, regs.esp, regs.ebp, regs.flags.raw() },
    );
}

pub fn logThunkCall(id: u32, regs: *const reg_map.RegisterFile) void {
    runtime_abi.common.writeLine(
        "[register-trace][x86][thunk] id={d} EAX=0x{x} ECX=0x{x} EDX=0x{x} ESP=0x{x} EIP=0x{x}\n",
        .{ id, regs.eax, regs.ecx, regs.edx, regs.esp, regs.eip },
    );
}

pub fn logOperation(scope: []const u8, opname: []const u8, lhs: u64, rhs: u64, result: u64, width_bits: u16, flags_before: u64, flags_after: u64) void {
    var op = bridge.makeOperation(.x86, instruction_counter, scope, opname);
    op.lhs = lhs;
    op.rhs = rhs;
    op.result = result;
    op.width_bits = width_bits;
    op.flags_before = flags_before;
    op.flags_after = flags_after;
    bridge.reportOperation(op);
}
