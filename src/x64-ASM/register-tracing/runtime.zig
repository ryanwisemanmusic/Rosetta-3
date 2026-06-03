const runtime_abi = @import("runtime_abi_handshake");
const x64 = @import("../x64_state.zig");
const bridge = @import("bridge_register_tracing");

pub fn init() void {
    runtime_abi.common.acquire();
    runtime_abi.common.writeLine("# [register-trace][x64] init\n", .{});
}

pub fn deinit() void {
    runtime_abi.common.writeLine("# [register-trace][x64] deinit\n", .{});
    runtime_abi.common.release();
}

pub fn logCheckpoint(tag: []const u8, regs: *const x64.RegisterFile64) void {
    runtime_abi.common.writeLine(
        "[register-trace][x64][{s}] RAX=0x{x} RCX=0x{x} RDX=0x{x} RBX=0x{x} RSP=0x{x} RBP=0x{x} RSI=0x{x} RDI=0x{x} R8=0x{x} R9=0x{x} R10=0x{x} R11=0x{x} R12=0x{x} R13=0x{x} R14=0x{x} R15=0x{x}\n",
        .{ tag, regs.rax, regs.rcx, regs.rdx, regs.rbx, regs.rsp, regs.rbp, regs.rsi, regs.rdi, regs.r8, regs.r9, regs.r10, regs.r11, regs.r12, regs.r13, regs.r14, regs.r15 },
    );
    runtime_abi.common.writeLine(
        "[register-trace][x64][{s}] RIP=0x{x} RFLAGS=0x{x} FS_BASE=0x{x} GS_BASE=0x{x} X87=unmodeled SSE=unmodeled AVX=unmodeled\n",
        .{ tag, regs.rip, regs.rflags, regs.fs_base, regs.gs_base },
    );
    var snap = bridge.makeSnapshot(.x64, .checkpoint, 0, tag);
    snap.regs.result = .{ .valid = true, .value = regs.rax };
    snap.regs.arg0 = .{ .valid = true, .value = regs.rcx };
    snap.regs.arg1 = .{ .valid = true, .value = regs.rdx };
    snap.regs.arg2 = .{ .valid = true, .value = regs.r8 };
    snap.regs.arg3 = .{ .valid = true, .value = regs.r9 };
    snap.regs.stack = .{ .valid = true, .value = regs.rsp };
    snap.regs.frame = .{ .valid = true, .value = regs.rbp };
    snap.regs.counter = .{ .valid = true, .value = regs.rcx };
    snap.regs.base = .{ .valid = true, .value = regs.rbx };
    snap.regs.data = .{ .valid = true, .value = regs.rdx };
    snap.regs.source = .{ .valid = true, .value = regs.rsi };
    snap.regs.dest = .{ .valid = true, .value = regs.rdi };
    snap.regs.instruction = .{ .valid = true, .value = regs.rip };
    snap.regs.flags = .{ .valid = true, .value = regs.rflags };
    snap.regs.fs_base = .{ .valid = true, .value = regs.fs_base };
    snap.regs.gs_base = .{ .valid = true, .value = regs.gs_base };
    bridge.reportSnapshot(snap);
}

pub fn logAddressing(tag: []const u8, rip_after_decode: u64, computed: u64) void {
    runtime_abi.common.writeLine(
        "[register-trace][x64][{s}] RIP_AFTER_DECODE=0x{x} ADDR=0x{x}\n",
        .{ tag, rip_after_decode, computed },
    );
}
