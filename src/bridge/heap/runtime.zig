const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

pub const HeapAction = model.HeapAction;

var pending_source_heap: ?model.HeapEvent = null;
var pending_target_heap: ?model.HeapEvent = null;

fn archRole(arch: model.Arch) []const u8 {
    return switch (arch) {
        .arm64 => "target",
        else => "source",
    };
}

fn archTag(arch: model.Arch) []const u8 {
    return switch (arch) {
        .dos => "DOS",
        .x86 => "x86",
        .x64 => "x64",
        .arm64 => "ARM64",
    };
}

fn scopeSlice(scope: []const u8, len: u8) []const u8 {
    return scope[0..len];
}

fn sameHeapKey(a: model.HeapEvent, b: model.HeapEvent) bool {
    return a.sequence == b.sequence and
        a.action == b.action and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

pub fn makeHeapEvent(arch: model.Arch, sequence: u64, scope: []const u8, action: model.HeapAction) model.HeapEvent {
    var event: model.HeapEvent = .{
        .arch = arch,
        .sequence = sequence,
        .action = action,
    };
    const len: usize = @min(event.scope.len, scope.len);
    @memcpy(event.scope[0..len], scope[0..len]);
    if (len < event.scope.len) @memset(event.scope[len..], 0);
    event.scope_len = @intCast(len);
    return event;
}

pub fn reportHeapEvent(event: model.HeapEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][heap][{s}] seq={d} scope={s} action={s} heap=0x{x} addr=0x{x} size=0x{x} flags=0x{x} result=0x{x}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            @tagName(event.action),
            event.heap_handle,
            event.address,
            event.size,
            event.flags,
            event.result,
        },
    );
    if (event.arch == .arm64) pending_target_heap = event else pending_source_heap = event;
    tryCompareHeap(emitOperationContext);
}

fn tryCompareHeap(emitOperationContext: *const fn ([]const u8) void) void {
    const source = pending_source_heap orelse return;
    const target = pending_target_heap orelse return;
    if (!sameHeapKey(source, target)) return;

    const scope = scopeSlice(&source.scope, source.scope_len);
    if (source.heap_handle != target.heap_handle or
        source.address != target.address or
        source.size != target.size or
        source.flags != target.flags or
        source.result != target.result)
    {
        runtime_abi.common.violation(
            "bridge-heap-trace",
            "heap_mismatch",
            "scope={s} action={s} source(heap=0x{x}, addr=0x{x}, size=0x{x}, flags=0x{x}, result=0x{x}) target(heap=0x{x}, addr=0x{x}, size=0x{x}, flags=0x{x}, result=0x{x})",
            .{
                scope,
                @tagName(source.action),
                source.heap_handle,
                source.address,
                source.size,
                source.flags,
                source.result,
                target.heap_handle,
                target.address,
                target.size,
                target.flags,
                target.result,
            },
        );
        emitOperationContext(scope);
    }
    pending_source_heap = null;
    pending_target_heap = null;
}
