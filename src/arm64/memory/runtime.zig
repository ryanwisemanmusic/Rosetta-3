const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_memory");
const layout = @import("layout.zig");

pub fn logAccess(scope: []const u8, access: bridge.MemoryAccess, sequence: u64, address: u64, width: u8, value: u64, stack_pointer: u64) void {
    runtime_abi.common.writeLine(
        "[memory-trace][arm64][{s}] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ @tagName(access), scope, sequence, address, width, value },
    );
    const meta = layout.classify(address, width, stack_pointer);
    runtime_abi.arm64.validateMemoryAccess(switch (access) {
        .read => .read,
        .write => .write,
    }, address, width, meta.permissions, meta.aligned, meta.null_page, meta.guard_page, meta.stack_access);
    var target = bridge.makeMemoryEvent(.arm64, sequence, scope, access);
    target.address = address;
    target.width_bytes = width;
    target.value = value;
    target.permissions = meta.permissions;
    target.region = meta.region;
    target.null_page = meta.null_page;
    target.guard_page = meta.guard_page;
    target.stack_access = meta.stack_access;
    target.aligned = meta.aligned;
    target.stack_grows_down = meta.stack_grows_down;
    bridge.reportMemoryEvent(target, noopContext);
}

fn noopContext(_: []const u8) void {}
