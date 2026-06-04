const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_memory");
const layout = @import("layout.zig");

var sequence: u64 = 0;

fn physical(segment: u16, offset: u16) u32 {
    return ((@as(u32, segment) << 4) + @as(u32, offset)) & 0xFFFFF;
}

fn reportShadow(scope: []const u8, access: bridge.MemoryAccess, seq: u64, segment: u16, offset: u16, width: u8, value: u64, stack_physical: u32) void {
    var target = bridge.makeMemoryEvent(.arm64, seq, scope, access);
    target.address = physical(segment, offset);
    target.width_bytes = width;
    target.value = value;
    const wrapped = (@as(u32, segment) << 4) + @as(u32, offset) > 0xFFFFF;
    const meta = layout.classify(@intCast(target.address), width, stack_physical, wrapped);
    target.permissions = meta.permissions;
    target.region = meta.region;
    target.null_page = meta.null_page;
    target.guard_page = meta.guard_page;
    target.stack_access = meta.stack_access;
    target.aligned = meta.aligned;
    target.wraparound = meta.wraparound;
    target.stack_grows_down = meta.stack_grows_down;
    bridge.reportMemoryEvent(target, noopContext);
}

pub fn logRead(scope: []const u8, segment: u16, offset: u16, width: u8, value: u64, stack_physical: u32) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[memory-trace][dos][read] scope={s} seq={d} seg:off={x}:{x} phys=0x{x} width={d} value=0x{x}\n",
        .{ scope, sequence, segment, offset, physical(segment, offset), width, value },
    );
    var source = bridge.makeMemoryEvent(.dos, sequence, scope, .read);
    source.address = physical(segment, offset);
    source.width_bytes = width;
    source.value = value;
    const wrapped = (@as(u32, segment) << 4) + @as(u32, offset) > 0xFFFFF;
    const meta = layout.classify(@intCast(source.address), width, stack_physical, wrapped);
    source.permissions = meta.permissions;
    source.region = meta.region;
    source.null_page = meta.null_page;
    source.guard_page = meta.guard_page;
    source.stack_access = meta.stack_access;
    source.aligned = meta.aligned;
    source.wraparound = meta.wraparound;
    source.stack_grows_down = meta.stack_grows_down;
    bridge.reportMemoryEvent(source, noopContext);
    reportShadow(scope, .read, sequence, segment, offset, width, value, stack_physical);
}

pub fn logWrite(scope: []const u8, segment: u16, offset: u16, width: u8, value: u64, stack_physical: u32) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[memory-trace][dos][write] scope={s} seq={d} seg:off={x}:{x} phys=0x{x} width={d} value=0x{x}\n",
        .{ scope, sequence, segment, offset, physical(segment, offset), width, value },
    );
    var source = bridge.makeMemoryEvent(.dos, sequence, scope, .write);
    source.address = physical(segment, offset);
    source.width_bytes = width;
    source.value = value;
    const wrapped = (@as(u32, segment) << 4) + @as(u32, offset) > 0xFFFFF;
    const meta = layout.classify(@intCast(source.address), width, stack_physical, wrapped);
    source.permissions = meta.permissions;
    source.region = meta.region;
    source.null_page = meta.null_page;
    source.guard_page = meta.guard_page;
    source.stack_access = meta.stack_access;
    source.aligned = meta.aligned;
    source.wraparound = meta.wraparound;
    source.stack_grows_down = meta.stack_grows_down;
    bridge.reportMemoryEvent(source, noopContext);
    reportShadow(scope, .write, sequence, segment, offset, width, value, stack_physical);
}

fn noopContext(_: []const u8) void {}
