const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_flags");

fn noopContext(_: []const u8) void {}

pub fn logFlags(scope: []const u8, sequence: u64, before_raw: u64, after_raw: u64) void {
    var event = bridge.makeFlagEvent(.arm64, sequence, scope);
    event.before_raw = before_raw;
    event.after_raw = after_raw;
    bridge.reportFlagEvent(event, noopContext);
    runtime_abi.common.writeLine("[flag-trace][arm64] scope={s} seq={d} before=0x{x} after=0x{x}\n", .{ scope, sequence, before_raw, after_raw });
}
