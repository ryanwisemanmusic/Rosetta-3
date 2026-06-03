const runtime_abi = @import("runtime_abi_handshake");
const x64 = @import("../x64_state.zig");
const bridge = @import("bridge_register_tracing");

pub fn logState(scope: []const u8, phase: bridge.Phase, sequence: u64, regs: *const x64.RegisterFile64) void {
    runtime_abi.common.writeLine(
        "[stack-trace][x64] scope={s} phase={s} seq={d} rsp=0x{x} rbp=0x{x} align16={d}\n",
        .{ scope, @tagName(phase), sequence, regs.rsp, regs.rbp, regs.rsp & 0xF },
    );
    var snap = bridge.makeStackEvent(.x64, phase, sequence, scope);
    snap.sp = regs.rsp;
    snap.fp = regs.rbp;
    snap.alignment = @intCast(regs.rsp & 0xF);
    snap.arg0 = .{ .valid = true, .value = regs.rcx };
    snap.arg1 = .{ .valid = true, .value = regs.rdx };
    snap.arg2 = .{ .valid = true, .value = regs.r8 };
    snap.arg3 = .{ .valid = true, .value = regs.r9 };
    bridge.reportStackEvent(snap);
}
