const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_flags");

fn noopContext(_: []const u8) void {}

pub fn logFlags(scope: []const u8, sequence: u64, before_raw: u64, after_raw: u64) void {
    var event = bridge.makeFlagEvent(.x64, sequence, scope);
    event.before_raw = before_raw;
    event.after_raw = after_raw;
    event.direction_flag = .{ .valid = true, .value = @as(u1, @truncate((after_raw >> 10) & 1)) };
    event.interrupt_flag = .{ .valid = true, .value = @as(u1, @truncate((after_raw >> 9) & 1)) };
    event.trap_flag = .{ .valid = true, .value = @as(u1, @truncate((after_raw >> 8) & 1)) };
    bridge.reportFlagEvent(event, noopContext);
    runtime_abi.common.writeLine("[flag-trace][x64] scope={s} seq={d} before=0x{x} after=0x{x}\n", .{ scope, sequence, before_raw, after_raw });
}
