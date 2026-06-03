const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_register_tracing");

var sequence: u64 = 0;

fn physical(segment: u16, offset: u16) u32 {
    return ((@as(u32, segment) << 4) + @as(u32, offset)) & 0xFFFFF;
}

fn reportShadow(scope: []const u8, access: bridge.MemoryAccess, seq: u64, segment: u16, offset: u16, width: u8, value: u64) void {
    var target = bridge.makeMemoryEvent(.arm64, seq, scope, access);
    target.address = physical(segment, offset);
    target.width_bytes = width;
    target.value = value;
    bridge.reportMemoryEvent(target);
}

pub fn logRead(scope: []const u8, segment: u16, offset: u16, width: u8, value: u64) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[memory-trace][dos][read] scope={s} seq={d} seg:off={x}:{x} phys=0x{x} width={d} value=0x{x}\n",
        .{ scope, sequence, segment, offset, physical(segment, offset), width, value },
    );
    var source = bridge.makeMemoryEvent(.dos, sequence, scope, .read);
    source.address = physical(segment, offset);
    source.width_bytes = width;
    source.value = value;
    bridge.reportMemoryEvent(source);
    reportShadow(scope, .read, sequence, segment, offset, width, value);
}

pub fn logWrite(scope: []const u8, segment: u16, offset: u16, width: u8, value: u64) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[memory-trace][dos][write] scope={s} seq={d} seg:off={x}:{x} phys=0x{x} width={d} value=0x{x}\n",
        .{ scope, sequence, segment, offset, physical(segment, offset), width, value },
    );
    var source = bridge.makeMemoryEvent(.dos, sequence, scope, .write);
    source.address = physical(segment, offset);
    source.width_bytes = width;
    source.value = value;
    bridge.reportMemoryEvent(source);
    reportShadow(scope, .write, sequence, segment, offset, width, value);
}
