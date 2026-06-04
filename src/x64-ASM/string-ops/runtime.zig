const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_string_ops");

fn noopContext(_: []const u8) void {}

pub fn logStringOp(scope: []const u8, sequence: u64, op: bridge.StringOpKind, rep_mode: bridge.StringRepMode, count_before: u64, count_after: u64) void {
    var event = bridge.makeStringOpEvent(.x64, sequence, scope, op, rep_mode);
    event.count_before = count_before;
    event.count_after = count_after;
    runtime_abi.common.writeLine("[string-op-trace][x64] scope={s} op={s} rep={s} count={d}->{d}\n", .{ scope, @tagName(op), @tagName(rep_mode), count_before, count_after });
    bridge.reportStringOpEvent(event, noopContext);
}
