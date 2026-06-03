const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

var pending_source_stack: ?model.StackEvent = null;
var pending_target_stack: ?model.StackEvent = null;

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

fn phaseName(phase: model.Phase) []const u8 {
    return @tagName(phase);
}

fn scopeSlice(scope: []const u8, len: u8) []const u8 {
    return scope[0..len];
}

fn sameStackKey(a: model.StackEvent, b: model.StackEvent) bool {
    return a.phase == b.phase and
        a.sequence == b.sequence and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

fn compareScalar(scope: []const u8, role: []const u8, source: model.Scalar, target: model.Scalar, emitOperationContext: *const fn ([]const u8) void) void {
    if (!source.valid or !target.valid) return;
    if (source.value != target.value) {
        runtime_abi.common.violation(
            "bridge-stack-trace",
            "stack_value_mismatch",
            "scope={s} role={s} [x86/DOS/x64]=0x{x} [ARM64]=0x{x}",
            .{ scope, role, source.value, target.value },
        );
        emitOperationContext(scope);
    }
}

fn scalar(label: []const u8, value: model.Scalar) void {
    if (!value.valid) return;
    runtime_abi.common.writeLine("[bridge-stack-trace]   {s}=0x{x}\n", .{ label, value.value });
}

pub fn makeStackEvent(arch: model.Arch, phase: model.Phase, sequence: u64, scope: []const u8) model.StackEvent {
    var event: model.StackEvent = .{
        .arch = arch,
        .phase = phase,
        .sequence = sequence,
    };
    const len: usize = @min(event.scope.len, scope.len);
    @memcpy(event.scope[0..len], scope[0..len]);
    if (len < event.scope.len) @memset(event.scope[len..], 0);
    event.scope_len = @intCast(len);
    return event;
}

pub fn reportStackEvent(event: model.StackEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][stack][{s}] phase={s} seq={d} scope={s} sp=0x{x} fp=0x{x} align={d}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            phaseName(event.phase),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            event.sp,
            event.fp,
            event.alignment,
        },
    );
    scalar("top0", event.top0);
    scalar("top1", event.top1);
    scalar("arg0", event.arg0);
    scalar("arg1", event.arg1);
    scalar("arg2", event.arg2);
    scalar("arg3", event.arg3);
    if (event.arch == .arm64) pending_target_stack = event else pending_source_stack = event;
    tryCompareStack(emitOperationContext);
}

fn tryCompareStack(emitOperationContext: *const fn ([]const u8) void) void {
    const source = pending_source_stack orelse return;
    const target = pending_target_stack orelse return;
    if (!sameStackKey(source, target)) return;

    const scope = scopeSlice(&source.scope, source.scope_len);
    if (source.sp != target.sp or source.fp != target.fp) {
        runtime_abi.common.violation(
            "bridge-stack-trace",
            "pointer_mismatch",
            "scope={s} source(sp=0x{x}, fp=0x{x}) target(sp=0x{x}, fp=0x{x})",
            .{ scope, source.sp, source.fp, target.sp, target.fp },
        );
        emitOperationContext(scope);
    }
    compareScalar(scope, "stack.top0", source.top0, target.top0, emitOperationContext);
    compareScalar(scope, "stack.top1", source.top1, target.top1, emitOperationContext);
    compareScalar(scope, "stack.arg0", source.arg0, target.arg0, emitOperationContext);
    compareScalar(scope, "stack.arg1", source.arg1, target.arg1, emitOperationContext);
    compareScalar(scope, "stack.arg2", source.arg2, target.arg2, emitOperationContext);
    compareScalar(scope, "stack.arg3", source.arg3, target.arg3, emitOperationContext);
    pending_source_stack = null;
    pending_target_stack = null;
}
