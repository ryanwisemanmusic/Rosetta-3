const runtime_abi = @import("runtime_abi_handshake");
const arm64_trace = @import("../register-tracing/runtime.zig");
const bridge = @import("bridge_stack");

pub fn logState(scope: []const u8, phase: bridge.Phase, sequence: u64, snap: *const arm64_trace.Arm64Snapshot) void {
    runtime_abi.common.writeLine(
        "[stack-trace][arm64] scope={s} phase={s} seq={d} sp=0x{x} fp=0x{x} align16={d}\n",
        .{ scope, @tagName(phase), sequence, snap.sp, snap.x[29], snap.sp & 0xF },
    );
    var event = bridge.makeStackEvent(.arm64, phase, sequence, scope);
    event.sp = snap.sp;
    event.fp = snap.x[29];
    event.alignment = @intCast(snap.sp & 0xF);
    event.arg0 = .{ .valid = true, .value = snap.x[0] };
    event.arg1 = .{ .valid = true, .value = snap.x[1] };
    event.arg2 = .{ .valid = true, .value = snap.x[2] };
    event.arg3 = .{ .valid = true, .value = snap.x[3] };
    bridge.reportStackEvent(event, noopContext);
}

fn noopContext(_: []const u8) void {}
