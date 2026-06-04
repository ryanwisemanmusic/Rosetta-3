const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

pub const DosSemanticKind = model.DosSemanticKind;

var pending_source: ?model.DosSemanticEvent = null;
var pending_target: ?model.DosSemanticEvent = null;

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

fn sameKey(a: model.DosSemanticEvent, b: model.DosSemanticEvent) bool {
    return a.sequence == b.sequence and
        a.kind == b.kind and
        a.major == b.major and
        a.minor == b.minor and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

pub fn makeDosEvent(arch: model.Arch, sequence: u64, scope: []const u8, kind: DosSemanticKind) model.DosSemanticEvent {
    var event: model.DosSemanticEvent = .{
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

pub fn reportDosEvent(event: model.DosSemanticEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][dos-runtime][{s}] seq={d} scope={s} kind={s} major=0x{x} minor=0x{x} v0=0x{x} v1=0x{x} v2=0x{x} v3=0x{x}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            @tagName(event.kind),
            event.major,
            event.minor,
            event.value0,
            event.value1,
            event.value2,
            event.value3,
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
    if (source.value0 != target.value0 or
        source.value1 != target.value1 or
        source.value2 != target.value2 or
        source.value3 != target.value3)
    {
        runtime_abi.common.violation(
            "bridge-dos-runtime",
            "semantic_mismatch",
            "scope={s} kind={s} major=0x{x} minor=0x{x} source(v0=0x{x}, v1=0x{x}, v2=0x{x}, v3=0x{x}) target(v0=0x{x}, v1=0x{x}, v2=0x{x}, v3=0x{x})",
            .{
                scope,
                @tagName(source.kind),
                source.major,
                source.minor,
                source.value0,
                source.value1,
                source.value2,
                source.value3,
                target.value0,
                target.value1,
                target.value2,
                target.value3,
            },
        );
        emitOperationContext(scope);
    }
    pending_source = null;
    pending_target = null;
}
