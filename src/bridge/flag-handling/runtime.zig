const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

pub const FlagEvent = model.FlagEvent;

var pending_source_flag: ?model.FlagEvent = null;
var pending_target_flag: ?model.FlagEvent = null;

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

fn scalar(label: []const u8, value: model.Scalar) void {
    if (!value.valid) return;
    runtime_abi.common.writeLine("[bridge-flag-trace]   {s}=0x{x}\n", .{ label, value.value });
}

fn sameKey(a: model.FlagEvent, b: model.FlagEvent) bool {
    return a.sequence == b.sequence and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

pub fn makeFlagEvent(arch: model.Arch, sequence: u64, scope: []const u8) model.FlagEvent {
    var event: model.FlagEvent = .{
        .arch = arch,
        .sequence = sequence,
    };
    const len: usize = @min(event.scope.len, scope.len);
    @memcpy(event.scope[0..len], scope[0..len]);
    if (len < event.scope.len) @memset(event.scope[len..], 0);
    event.scope_len = @intCast(len);
    return event;
}

pub fn reportFlagEvent(event: model.FlagEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][flags][{s}] seq={d} scope={s} before=0x{x} after=0x{x} updated=0x{x} preserved=0x{x} undefined=0x{x}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            event.before_raw,
            event.after_raw,
            event.updated_mask,
            event.preserved_mask,
            event.undefined_mask,
        },
    );
    scalar("PF", event.parity_flag);
    scalar("AF", event.auxiliary_flag);
    scalar("ZF", event.zero_flag);
    scalar("SF", event.sign_flag);
    scalar("CF", event.carry_flag);
    scalar("OF", event.overflow_flag);
    scalar("DF", event.direction_flag);
    scalar("IF", event.interrupt_flag);
    scalar("TF", event.trap_flag);
    scalar("LAHF", event.lahf_image);
    scalar("SAHF", event.sahf_image);
    if (event.arch == .arm64) pending_target_flag = event else pending_source_flag = event;
    tryCompare(emitOperationContext);
}

fn compareScalar(scope: []const u8, role: []const u8, source: model.Scalar, target: model.Scalar, emitOperationContext: *const fn ([]const u8) void) void {
    if (!source.valid or !target.valid) return;
    if (source.value != target.value) {
        runtime_abi.common.violation(
            "bridge-flag-trace",
            "flag_scalar_mismatch",
            "scope={s} role={s} [x86/DOS/x64]=0x{x} [ARM64]=0x{x}",
            .{ scope, role, source.value, target.value },
        );
        emitOperationContext(scope);
    }
}

fn tryCompare(emitOperationContext: *const fn ([]const u8) void) void {
    const source = pending_source_flag orelse return;
    const target = pending_target_flag orelse return;
    if (!sameKey(source, target)) return;

    const scope = scopeSlice(&source.scope, source.scope_len);
    if (source.before_raw != target.before_raw or
        source.after_raw != target.after_raw or
        source.updated_mask != target.updated_mask or
        source.preserved_mask != target.preserved_mask or
        source.undefined_mask != target.undefined_mask)
    {
        runtime_abi.common.violation(
            "bridge-flag-trace",
            "flag_envelope_mismatch",
            "scope={s} source(before=0x{x}, after=0x{x}, updated=0x{x}, preserved=0x{x}, undefined=0x{x}) target(before=0x{x}, after=0x{x}, updated=0x{x}, preserved=0x{x}, undefined=0x{x})",
            .{
                scope,
                source.before_raw,
                source.after_raw,
                source.updated_mask,
                source.preserved_mask,
                source.undefined_mask,
                target.before_raw,
                target.after_raw,
                target.updated_mask,
                target.preserved_mask,
                target.undefined_mask,
            },
        );
        emitOperationContext(scope);
    }
    compareScalar(scope, "PF", source.parity_flag, target.parity_flag, emitOperationContext);
    compareScalar(scope, "AF", source.auxiliary_flag, target.auxiliary_flag, emitOperationContext);
    compareScalar(scope, "ZF", source.zero_flag, target.zero_flag, emitOperationContext);
    compareScalar(scope, "SF", source.sign_flag, target.sign_flag, emitOperationContext);
    compareScalar(scope, "CF", source.carry_flag, target.carry_flag, emitOperationContext);
    compareScalar(scope, "OF", source.overflow_flag, target.overflow_flag, emitOperationContext);
    compareScalar(scope, "DF", source.direction_flag, target.direction_flag, emitOperationContext);
    compareScalar(scope, "IF", source.interrupt_flag, target.interrupt_flag, emitOperationContext);
    compareScalar(scope, "TF", source.trap_flag, target.trap_flag, emitOperationContext);
    compareScalar(scope, "LAHF", source.lahf_image, target.lahf_image, emitOperationContext);
    compareScalar(scope, "SAHF", source.sahf_image, target.sahf_image, emitOperationContext);
    pending_source_flag = null;
    pending_target_flag = null;
}
