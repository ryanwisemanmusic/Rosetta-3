const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_memory");
const reg_trace = @import("../register-tracing/runtime.zig");
const layout = @import("layout.zig");

fn reportShadow(scope: []const u8, access: bridge.MemoryAccess, seq: u64, addr: u32, width: u8, value: u64, stack_pointer: u32, executable_write: bool) void {
    var target = bridge.makeMemoryEvent(.arm64, seq, scope, access);
    target.address = addr;
    target.width_bytes = width;
    target.value = value;
    const meta = layout.classify(addr, width, stack_pointer);
    target.permissions = meta.permissions;
    target.region = meta.region;
    target.null_page = meta.null_page;
    target.guard_page = meta.guard_page;
    target.stack_access = meta.stack_access;
    target.aligned = meta.aligned;
    target.stack_grows_down = meta.stack_grows_down;
    target.self_modified_code = executable_write;
    target.cache_invalidate = executable_write;
    target.translated_block_invalidate = executable_write;
    bridge.reportMemoryEvent(target, reg_trace.emitOperationContext);
}

pub fn logRead(scope: []const u8, addr: u32, width: u8, value: u64, stack_pointer: u32) void {
    runtime_abi.common.writeLine(
        "[memory-trace][x86][read] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ scope, reg_trace.currentSequence(), addr, width, value },
    );
    var source = bridge.makeMemoryEvent(.x86, reg_trace.currentSequence(), scope, .read);
    source.address = addr;
    source.width_bytes = width;
    source.value = value;
    const meta = layout.classify(addr, width, stack_pointer);
    source.permissions = meta.permissions;
    source.region = meta.region;
    source.null_page = meta.null_page;
    source.guard_page = meta.guard_page;
    source.stack_access = meta.stack_access;
    source.aligned = meta.aligned;
    source.stack_grows_down = meta.stack_grows_down;
    bridge.reportMemoryEvent(source, reg_trace.emitOperationContext);
    reportShadow(scope, .read, reg_trace.currentSequence(), addr, width, value, stack_pointer, false);
}

pub fn logWrite(scope: []const u8, addr: u32, width: u8, value: u64, stack_pointer: u32, executable_write: bool) void {
    runtime_abi.common.writeLine(
        "[memory-trace][x86][write] scope={s} seq={d} addr=0x{x} width={d} value=0x{x}\n",
        .{ scope, reg_trace.currentSequence(), addr, width, value },
    );
    var source = bridge.makeMemoryEvent(.x86, reg_trace.currentSequence(), scope, .write);
    source.address = addr;
    source.width_bytes = width;
    source.value = value;
    const meta = layout.classify(addr, width, stack_pointer);
    source.permissions = meta.permissions;
    source.region = meta.region;
    source.null_page = meta.null_page;
    source.guard_page = meta.guard_page;
    source.stack_access = meta.stack_access;
    source.aligned = meta.aligned;
    source.stack_grows_down = meta.stack_grows_down;
    source.self_modified_code = executable_write;
    source.cache_invalidate = executable_write;
    source.translated_block_invalidate = executable_write;
    bridge.reportMemoryEvent(source, reg_trace.emitOperationContext);
    reportShadow(scope, .write, reg_trace.currentSequence(), addr, width, value, stack_pointer, executable_write);
}
