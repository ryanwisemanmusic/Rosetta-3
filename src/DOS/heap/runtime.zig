const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_heap");

fn noopContext(_: []const u8) void {}

pub fn logEvent(scope: []const u8, action: bridge.HeapAction, sequence: u64, heap_handle: u32, address: u32, size: u32, flags: u32, result: u32) void {
    runtime_abi.common.writeLine(
        "[heap-trace][DOS] scope={s} seq={d} action={s} heap=0x{x} addr=0x{x} size=0x{x} flags=0x{x} result=0x{x}\n",
        .{ scope, sequence, @tagName(action), heap_handle, address, size, flags, result },
    );
    var event = bridge.makeHeapEvent(.dos, sequence, scope, action);
    event.heap_handle = heap_handle;
    event.address = address;
    event.size = size;
    event.flags = flags;
    event.result = result;
    bridge.reportHeapEvent(event, noopContext);
}
