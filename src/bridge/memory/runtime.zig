const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

var pending_source_memory: ?model.MemoryEvent = null;
var pending_target_memory: ?model.MemoryEvent = null;

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

fn sameMemoryKey(a: model.MemoryEvent, b: model.MemoryEvent) bool {
    return a.sequence == b.sequence and
        a.access == b.access and
        a.width_bytes == b.width_bytes and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

pub fn makeMemoryEvent(arch: model.Arch, sequence: u64, scope: []const u8, access: model.MemoryAccess) model.MemoryEvent {
    var event: model.MemoryEvent = .{
        .arch = arch,
        .sequence = sequence,
        .access = access,
    };
    const len: usize = @min(event.scope.len, scope.len);
    @memcpy(event.scope[0..len], scope[0..len]);
    if (len < event.scope.len) @memset(event.scope[len..], 0);
    event.scope_len = @intCast(len);
    return event;
}

pub fn reportMemoryEvent(event: model.MemoryEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][memory][{s}] seq={d} scope={s} access={s} addr=0x{x} width={d} value=0x{x}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            @tagName(event.access),
            event.address,
            event.width_bytes,
            event.value,
        },
    );
    if (event.arch == .arm64) pending_target_memory = event else pending_source_memory = event;
    tryCompareMemory(emitOperationContext);
}

fn tryCompareMemory(emitOperationContext: *const fn ([]const u8) void) void {
    const source = pending_source_memory orelse return;
    const target = pending_target_memory orelse return;
    if (!sameMemoryKey(source, target)) return;

    const scope = scopeSlice(&source.scope, source.scope_len);
    if (source.address != target.address or source.value != target.value) {
        runtime_abi.common.violation(
            "bridge-memory-trace",
            "memory_mismatch",
            "scope={s} access={s} width={d} source(addr=0x{x}, value=0x{x}) target(addr=0x{x}, value=0x{x})",
            .{ scope, @tagName(source.access), source.width_bytes, source.address, source.value, target.address, target.value },
        );
        emitOperationContext(scope);
    }
    pending_source_memory = null;
    pending_target_memory = null;
}
