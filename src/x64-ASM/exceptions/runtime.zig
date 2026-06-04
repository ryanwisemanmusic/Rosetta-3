const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_exceptions");
const x64 = @import("../x64_state.zig");

var sequence: u64 = 0;

fn reportShadow(scope: []const u8, seq: u64, kind: bridge.ExceptionKind, vector: u16, code: u64, address: u64, instruction: u64, flags: u64) void {
    var target = bridge.makeExceptionEvent(.arm64, seq, scope, kind);
    target.vector = vector;
    target.code = code;
    target.address = address;
    target.instruction = instruction;
    target.flags = flags;
    bridge.reportExceptionEvent(target, noopContext);
}

pub fn logStructuredException(scope: []const u8, code: u32, address: u64, regs: *const x64.RegisterFile64) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[exception-trace][x64] scope={s} seq={d} kind=windows_seh code=0x{x} addr=0x{x} rip=0x{x} flags=0x{x}\n",
        .{ scope, sequence, code, address, regs.rip, regs.rflags },
    );
    var source = bridge.makeExceptionEvent(.x64, sequence, scope, .windows_seh);
    source.vector = 0;
    source.code = code;
    source.address = address;
    source.instruction = regs.rip;
    source.flags = regs.rflags;
    bridge.reportExceptionEvent(source, noopContext);
    reportShadow(scope, sequence, .windows_seh, 0, code, address, regs.rip, regs.rflags);
}

fn noopContext(_: []const u8) void {}
