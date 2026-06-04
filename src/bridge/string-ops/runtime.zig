const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

pub const StringOpKind = model.StringOpKind;
pub const StringRepMode = model.StringRepMode;
pub const StringOpEvent = model.StringOpEvent;

var pending_source: ?model.StringOpEvent = null;
var pending_target: ?model.StringOpEvent = null;

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

fn sameKey(a: model.StringOpEvent, b: model.StringOpEvent) bool {
    return a.sequence == b.sequence and
        a.op == b.op and
        a.rep_mode == b.rep_mode and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

pub fn makeStringOpEvent(arch: model.Arch, sequence: u64, scope: []const u8, op: model.StringOpKind, rep_mode: model.StringRepMode) model.StringOpEvent {
    var event: model.StringOpEvent = .{
        .arch = arch,
        .sequence = sequence,
        .op = op,
        .rep_mode = rep_mode,
    };
    const len: usize = @min(event.scope.len, scope.len);
    @memcpy(event.scope[0..len], scope[0..len]);
    if (len < event.scope.len) @memset(event.scope[len..], 0);
    event.scope_len = @intCast(len);
    return event;
}

pub fn reportStringOpEvent(event: model.StringOpEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][string-op][{s}] seq={d} scope={s} op={s} rep={s} width={d} count={d}->{d} src=0x{x}->0x{x} dst=0x{x}->0x{x} segs=0x{x}/0x{x} zero={} partial={} interrupted={} match={}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            @tagName(event.op),
            @tagName(event.rep_mode),
            event.width_bytes,
            event.count_before,
            event.count_after,
            event.src_before,
            event.src_after,
            event.dst_before,
            event.dst_after,
            event.source_segment,
            event.dest_segment,
            event.zero_count,
            event.partial_completion,
            event.interrupted,
            event.terminated_on_match,
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
    const mismatch =
        source.width_bytes != target.width_bytes or
        source.count_before != target.count_before or
        source.count_after != target.count_after or
        source.source_segment != target.source_segment or
        source.dest_segment != target.dest_segment or
        source.src_before != target.src_before or
        source.src_after != target.src_after or
        source.dst_before != target.dst_before or
        source.dst_after != target.dst_after or
        source.zero_count != target.zero_count or
        source.partial_completion != target.partial_completion or
        source.interrupted != target.interrupted or
        source.terminated_on_match != target.terminated_on_match;
    if (mismatch) {
        runtime_abi.common.violation(
            "bridge-string-ops",
            "string_op_mismatch",
            "scope={s} op={s} source(count={d}->{d}, src=0x{x}->0x{x}, dst=0x{x}->0x{x}, zero={}, partial={}, interrupted={}, match={}) target(count={d}->{d}, src=0x{x}->0x{x}, dst=0x{x}->0x{x}, zero={}, partial={}, interrupted={}, match={})",
            .{
                scope,
                @tagName(source.op),
                source.count_before,
                source.count_after,
                source.src_before,
                source.src_after,
                source.dst_before,
                source.dst_after,
                source.zero_count,
                source.partial_completion,
                source.interrupted,
                source.terminated_on_match,
                target.count_before,
                target.count_after,
                target.src_before,
                target.src_after,
                target.dst_before,
                target.dst_after,
                target.zero_count,
                target.partial_completion,
                target.interrupted,
                target.terminated_on_match,
            },
        );
        emitOperationContext(scope);
    }
    pending_source = null;
    pending_target = null;
}
