const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_register_tracing");

pub fn logAccess(scope: []const u8, access: bridge.MemoryAccess, sequence: u64, address: u64, width: u8, value: u64) void {
    runtime_abi.common.writeLine(
        "[memory-trace][x64][{s}] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ @tagName(access), scope, sequence, address, width, value },
    );
    var source = bridge.makeMemoryEvent(.x64, sequence, scope, access);
    source.address = address;
    source.width_bytes = width;
    source.value = value;
    bridge.reportMemoryEvent(source);
}
