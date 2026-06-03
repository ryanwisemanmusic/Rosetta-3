const runtime_abi = @import("runtime_abi_handshake");
const cpu_mod = @import("../execution/cpu_state.zig");
const bridge = @import("bridge_register_tracing");

fn rawFlags(flags: cpu_mod.Flags) u16 {
    return @bitCast(flags);
}

pub fn init() void {
    runtime_abi.common.acquire();
    runtime_abi.common.writeLine("# [register-trace][dos] init\n", .{});
}

pub fn deinit() void {
    runtime_abi.common.writeLine("# [register-trace][dos] deinit\n", .{});
    runtime_abi.common.release();
}

pub fn logCheckpoint(tag: []const u8, cpu: *const cpu_mod.CpuState) void {
    runtime_abi.common.writeLine(
        "[register-trace][dos][{s}] AX=0x{x} BX=0x{x} CX=0x{x} DX=0x{x} SP=0x{x} BP=0x{x} SI=0x{x} DI=0x{x} CS=0x{x} DS=0x{x} ES=0x{x} SS=0x{x} IP=0x{x} FLAGS=0x{x}\n",
        .{ tag, cpu.ax, cpu.bx, cpu.cx, cpu.dx, cpu.sp, cpu.bp, cpu.si, cpu.di, cpu.cs, cpu.ds, cpu.es, cpu.ss, cpu.ip, rawFlags(cpu.flags) },
    );
    runtime_abi.common.writeLine(
        "[register-trace][dos][{s}] PHYS_CSIP=0x{x} PHYS_SSSP=0x{x} FPU=unmodeled SIMD=unmodeled\n",
        .{ tag, cpu.physicalCsIp(), cpu.physicalSsSp() },
    );
    var snap = bridge.makeSnapshot(.dos, .checkpoint, 0, tag);
    snap.regs.result = .{ .valid = true, .value = cpu.ax };
    snap.regs.arg0 = .{ .valid = true, .value = cpu.bx };
    snap.regs.arg1 = .{ .valid = true, .value = cpu.cx };
    snap.regs.arg2 = .{ .valid = true, .value = cpu.dx };
    snap.regs.stack = .{ .valid = true, .value = cpu.sp };
    snap.regs.frame = .{ .valid = true, .value = cpu.bp };
    snap.regs.counter = .{ .valid = true, .value = cpu.cx };
    snap.regs.base = .{ .valid = true, .value = cpu.bx };
    snap.regs.data = .{ .valid = true, .value = cpu.dx };
    snap.regs.source = .{ .valid = true, .value = cpu.si };
    snap.regs.dest = .{ .valid = true, .value = cpu.di };
    snap.regs.instruction = .{ .valid = true, .value = cpu.physicalCsIp() };
    snap.regs.flags = .{ .valid = true, .value = rawFlags(cpu.flags) };
    snap.regs.segment_cs = .{ .valid = true, .value = cpu.cs };
    snap.regs.segment_ds = .{ .valid = true, .value = cpu.ds };
    snap.regs.segment_es = .{ .valid = true, .value = cpu.es };
    snap.regs.segment_ss = .{ .valid = true, .value = cpu.ss };
    bridge.reportSnapshot(snap);
}

pub fn logInterrupt(phase: []const u8, vector: u8, cpu: *const cpu_mod.CpuState) void {
    runtime_abi.common.writeLine(
        "[register-trace][dos][interrupt-{s}] vector=0x{x} AH=0x{x} AL=0x{x}\n",
        .{ phase, vector, cpu.ah(), cpu.al() },
    );
    logCheckpoint(phase, cpu);
}
