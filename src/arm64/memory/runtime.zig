const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_register_tracing");

pub fn logAccess(scope: []const u8, access: bridge.MemoryAccess, sequence: u64, address: u64, width: u8, value: u64) void {
    runtime_abi.common.writeLine(
        "[memory-trace][arm64][{s}] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ @tagName(access), scope, sequence, address, width, value },
    );
    var target = bridge.makeMemoryEvent(.arm64, sequence, scope, access);
    target.address = address;
    target.width_bytes = width;
    target.value = value;
    bridge.reportMemoryEvent(target);
}
