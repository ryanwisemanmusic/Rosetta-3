const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_register_tracing");
const reg_trace = @import("../register-tracing/runtime.zig");

fn reportShadow(scope: []const u8, access: bridge.MemoryAccess, seq: u64, addr: u32, width: u8, value: u64) void {
    var target = bridge.makeMemoryEvent(.arm64, seq, scope, access);
    target.address = addr;
    target.width_bytes = width;
    target.value = value;
    bridge.reportMemoryEvent(target);
}

pub fn logRead(scope: []const u8, addr: u32, width: u8, value: u64) void {
    runtime_abi.common.writeLine(
        "[memory-trace][x86][read] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ scope, reg_trace.currentSequence(), addr, width, value },
    );
    var source = bridge.makeMemoryEvent(.x86, reg_trace.currentSequence(), scope, .read);
    source.address = addr;
    source.width_bytes = width;
    source.value = value;
    bridge.reportMemoryEvent(source);
    reportShadow(scope, .read, reg_trace.currentSequence(), addr, width, value);
}

pub fn logWrite(scope: []const u8, addr: u32, width: u8, value: u64) void {
    runtime_abi.common.writeLine(
        "[memory-trace][x86][write] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ scope, reg_trace.currentSequence(), addr, width, value },
    );
    var source = bridge.makeMemoryEvent(.x86, reg_trace.currentSequence(), scope, .write);
    source.address = addr;
    source.width_bytes = width;
    source.value = value;
    bridge.reportMemoryEvent(source);
    reportShadow(scope, .write, reg_trace.currentSequence(), addr, width, value);
}
