const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

pub const ExceptionKind = model.ExceptionKind;

var pending_source: ?model.ExceptionEvent = null;
var pending_target: ?model.ExceptionEvent = null;

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

fn sameKey(a: model.ExceptionEvent, b: model.ExceptionEvent) bool {
    return a.sequence == b.sequence and
        a.kind == b.kind and
        a.vector == b.vector and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

pub fn makeExceptionEvent(arch: model.Arch, sequence: u64, scope: []const u8, kind: ExceptionKind) model.ExceptionEvent {
    var event: model.ExceptionEvent = .{
        .arch = arch,
        .sequence = sequence,
        .kind = kind,
    };
    const len: usize = @min(event.scope.len, scope.len);
    @memcpy(event.scope[0..len], scope[0..len]);
    if (len < event.scope.len) @memset(event.scope[len..], 0);
    event.scope_len = @intCast(len);
    return event;
}

pub fn reportExceptionEvent(event: model.ExceptionEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][exception][{s}] seq={d} scope={s} kind={s} vector=0x{x} code=0x{x} addr=0x{x} instr=0x{x} flags=0x{x}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            @tagName(event.kind),
            event.vector,
            event.code,
            event.address,
            event.instruction,
            event.flags,
        },
    );
    if (event.arch == .arm64) pending_target = event else pending_source = event;
    tryCompare(emitOperationContext);
}

fn tryCompare(emitOperationContext: *const fn ([]const u8) void) void {
    const source = pending_source orelse return;
    const target = pending_target orelse return;
    if (!sameKey(source, target)) return;
    const scope = scopeSlice(&source.scope, source.scope_len);
    if (source.code != target.code or
        source.address != target.address or
        source.instruction != target.instruction or
        source.flags != target.flags)
    {
        runtime_abi.common.violation(
            "bridge-exception-trace",
            "exception_mismatch",
            "scope={s} kind={s} vector=0x{x} source(code=0x{x}, addr=0x{x}, instr=0x{x}, flags=0x{x}) target(code=0x{x}, addr=0x{x}, instr=0x{x}, flags=0x{x})",
            .{
                scope,
                @tagName(source.kind),
                source.vector,
                source.code,
                source.address,
                source.instruction,
                source.flags,
                target.code,
                target.address,
                target.instruction,
                target.flags,
            },
        );
        emitOperationContext(scope);
    }
    pending_source = null;
    pending_target = null;
}
