const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

pub const ControlTransferKind = model.ControlTransferKind;

var pending_source_decode: ?model.DecodeEvent = null;
var pending_target_decode: ?model.DecodeEvent = null;

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

fn prefixOrderSlice(order: []const u8, count: u8) []const u8 {
    return order[0..count];
}

fn sameKey(a: model.DecodeEvent, b: model.DecodeEvent) bool {
    return a.sequence == b.sequence and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

pub fn makeDecodeEvent(arch: model.Arch, sequence: u64, scope: []const u8) model.DecodeEvent {
    var event: model.DecodeEvent = .{
        .arch = arch,
        .sequence = sequence,
    };
    const len: usize = @min(event.scope.len, scope.len);
    @memcpy(event.scope[0..len], scope[0..len]);
    if (len < event.scope.len) @memset(event.scope[len..], 0);
    event.scope_len = @intCast(len);
    return event;
}

pub fn reportDecodeEvent(event: model.DecodeEvent, emitOperationContext: *const fn ([]const u8) void) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][decode][{s}] seq={d} scope={s} len={d} prefixes={d} opcode_len={d} modrm={} sib={} imm_width={d} rel=0x{x} ctl={s} invalid={} undefined={}\n",
        .{
            archTag(event.arch),
            archRole(event.arch),
            event.sequence,
            scopeSlice(&event.scope, event.scope_len),
            event.decoded_len,
            event.prefix_count,
            event.opcode_len,
            event.has_modrm,
            event.has_sib,
            event.immediate_width,
            event.relative_target,
            @tagName(event.control_kind),
            event.invalid_opcode,
            event.undefined_opcode,
        },
    );
    if (event.prefix_count > 0) {
        runtime_abi.common.writeLine(
            "[{s}][bridge][decode][{s}] prefix_order={any}\n",
            .{ archTag(event.arch), archRole(event.arch), prefixOrderSlice(&event.prefix_order, event.prefix_count) },
        );
    }
    if (event.arch == .arm64) pending_target_decode = event else pending_source_decode = event;
    tryCompare(emitOperationContext);
}

fn tryCompare(emitOperationContext: *const fn ([]const u8) void) void {
    const source = pending_source_decode orelse return;
    const target = pending_target_decode orelse return;
    if (!sameKey(source, target)) return;

    const scope = scopeSlice(&source.scope, source.scope_len);
    const mismatch =
        source.prefix_count != target.prefix_count or
        !std.mem.eql(u8, prefixOrderSlice(&source.prefix_order, source.prefix_count), prefixOrderSlice(&target.prefix_order, target.prefix_count)) or
        source.operand_size_override != target.operand_size_override or
        source.address_size_override != target.address_size_override or
        source.lock != target.lock or
        source.rep != target.rep or
        source.repe != target.repe or
        source.repne != target.repne or
        source.segment_override != target.segment_override or
        source.opcode_len != target.opcode_len or
        source.decoded_len != target.decoded_len or
        source.has_modrm != target.has_modrm or
        source.has_sib != target.has_sib or
        source.modrm != target.modrm or
        source.sib != target.sib or
        source.immediate_width != target.immediate_width or
        source.immediate_value != target.immediate_value or
        source.sign_extended_immediate != target.sign_extended_immediate or
        source.relative_target != target.relative_target or
        source.control_kind != target.control_kind or
        source.invalid_opcode != target.invalid_opcode or
        source.undefined_opcode != target.undefined_opcode;
    if (mismatch) {
        runtime_abi.common.violation(
            "bridge-instruction-decoding",
            "decode_mismatch",
            "scope={s} source(len={d}, prefixes={d}, opcode_len={d}, rel=0x{x}, ctl={s}, invalid={}, undefined={}) target(len={d}, prefixes={d}, opcode_len={d}, rel=0x{x}, ctl={s}, invalid={}, undefined={})",
            .{
                scope,
                source.decoded_len,
                source.prefix_count,
                source.opcode_len,
                source.relative_target,
                @tagName(source.control_kind),
                source.invalid_opcode,
                source.undefined_opcode,
                target.decoded_len,
                target.prefix_count,
                target.opcode_len,
                target.relative_target,
                @tagName(target.control_kind),
                target.invalid_opcode,
                target.undefined_opcode,
            },
        );
        emitOperationContext(scope);
    }
    pending_source_decode = null;
    pending_target_decode = null;
}
