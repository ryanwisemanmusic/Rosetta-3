const runtime_abi = @import("runtime_abi_handshake");
const x64 = @import("../x64_state.zig");
const bridge = @import("bridge_stack");

pub fn logState(scope: []const u8, phase: bridge.Phase, sequence: u64, regs: *const x64.RegisterFile64) void {
    runtime_abi.common.writeLine(
        "[stack-trace][x64] scope={s} phase={s} seq={d} rsp=0x{x} rbp=0x{x} align16={d} shadow={d} abi={s}\n",
        .{ scope, @tagName(phase), sequence, regs.rsp, regs.rbp, regs.rsp & 0xF, regs.shadow_space_bytes, @tagName(regs.abi_mode) },
    );
    var snap = bridge.makeStackEvent(.x64, phase, sequence, scope);
    snap.sp = regs.rsp;
    snap.fp = regs.rbp;
    snap.alignment = @intCast(regs.rsp & 0xF);
    snap.arg0 = .{ .valid = true, .value = regs.rcx };
    snap.arg1 = .{ .valid = true, .value = regs.rdx };
    snap.arg2 = .{ .valid = true, .value = regs.r8 };
    snap.arg3 = .{ .valid = true, .value = regs.r9 };
    snap.top0 = .{ .valid = true, .value = regs.shadow_space_bytes };
    snap.top1 = .{ .valid = true, .value = @intFromEnum(regs.abi_mode) };
    bridge.reportStackEvent(snap, noopContext);
}

fn noopContext(_: []const u8) void {}
