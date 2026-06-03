const runtime_abi = @import("runtime_abi_handshake");
const reg_map = @import("../register_mapping.zig");
const bridge = @import("bridge_register_tracing");

var instruction_counter: u64 = 0;

pub fn currentSequence() u64 {
    return instruction_counter;
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
