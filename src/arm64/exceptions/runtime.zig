const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_exceptions");

var sequence: u64 = 0;

pub fn logSignalMapping(scope: []const u8, signal_number: u32, mapped_code: u32, address: u64, instruction: u64, flags: u64) void {
    sequence += 1;
    const signal_kind: runtime_abi.arm64.HostSignalKind = switch (signal_number) {
        4 => .sigill,
        5 => .sigtrap,
        6 => .sigabort,
        8 => .sigfpe,
        10 => .sigbus,
        11 => .sigsegv,
        else => .none,
    };
    runtime_abi.arm64.validateSignalDelivery(scope, signal_kind, mapped_code);
    runtime_abi.common.writeLine(
        "[exception-trace][arm64] scope={s} seq={d} kind=macos_signal_exception signal={d} mapped=0x{x} addr=0x{x} instr=0x{x} flags=0x{x}\n",
        .{ scope, sequence, signal_number, mapped_code, address, instruction, flags },
    );
    var target = bridge.makeExceptionEvent(.arm64, sequence, scope, .macos_signal_exception);
    target.vector = @intCast(signal_number);
    target.code = mapped_code;
    target.address = address;
    target.instruction = instruction;
    target.flags = flags;
    bridge.reportExceptionEvent(target, noopContext);
}

fn noopContext(_: []const u8) void {}
