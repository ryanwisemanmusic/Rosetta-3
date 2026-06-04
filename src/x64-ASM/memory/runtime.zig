const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_memory");
const layout = @import("layout.zig");

pub fn logAccess(scope: []const u8, access: bridge.MemoryAccess, sequence: u64, address: u64, width: u8, value: u64, stack_pointer: u64) void {
    runtime_abi.common.writeLine(
        "[memory-trace][x64][{s}] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ @tagName(access), scope, sequence, address, width, value },
    );
    const meta = layout.classify(address, width, stack_pointer);
    runtime_abi.x64.validateMemoryAccess(@tagName(access), address, width, meta.permissions, meta.aligned, meta.null_page, meta.guard_page, meta.canonical, meta.stack_access);
    var source = bridge.makeMemoryEvent(.x64, sequence, scope, access);
    source.address = address;
    source.width_bytes = width;
    source.value = value;
    source.permissions = meta.permissions;
    source.region = meta.region;
    source.null_page = meta.null_page;
    source.guard_page = meta.guard_page;
    source.stack_access = meta.stack_access;
    source.aligned = meta.aligned;
    source.canonical = meta.canonical;
    source.stack_grows_down = meta.stack_grows_down;
    bridge.reportMemoryEvent(source, noopContext);
}

fn noopContext(_: []const u8) void {}
