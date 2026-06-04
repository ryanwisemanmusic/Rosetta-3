const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const model = @import("bridge_model");

pub const Arch = model.Arch;
pub const Phase = model.Phase;
pub const Scalar = model.Scalar;

var pending_source: ?model.Snapshot = null;
var pending_target: ?model.Snapshot = null;
var last_source_op: ?model.Operation = null;
var last_target_op: ?model.Operation = null;

fn copyBounded(dst: []u8, src: []const u8) u8 {
    const len: usize = @min(dst.len, src.len);
    @memcpy(dst[0..len], src[0..len]);
    if (len < dst.len) @memset(dst[len..], 0);
    return @intCast(len);
}

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

fn scalar(label: []const u8, value: model.Scalar) void {
    if (!value.valid) return;
    runtime_abi.common.writeLine("[bridge-register-trace]   {s}=0x{x}\n", .{ label, value.value });
}

pub fn makeSnapshot(arch: model.Arch, phase: model.Phase, sequence: u64, scope: []const u8) model.Snapshot {
    var snap: model.Snapshot = .{
        .arch = arch,
        .phase = phase,
        .sequence = sequence,
    };
    snap.scope_len = copyBounded(&snap.scope, scope);
    return snap;
}

pub fn makeOperation(arch: model.Arch, sequence: u64, scope: []const u8, opname: []const u8) model.Operation {
    var op: model.Operation = .{
        .arch = arch,
        .sequence = sequence,
    };
    op.scope_len = copyBounded(&op.scope, scope);
    op.opname_len = copyBounded(&op.opname, opname);
    return op;
}

pub fn reportSnapshot(snap: model.Snapshot) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][snapshot][{s}] phase={s} seq={d} scope={s}\n",
        .{ archTag(snap.arch), archRole(snap.arch), phaseName(snap.phase), snap.sequence, scopeSlice(&snap.scope, snap.scope_len) },
    );
    scalar("result", snap.regs.result);
    scalar("arg0", snap.regs.arg0);
    scalar("arg1", snap.regs.arg1);
    scalar("arg2", snap.regs.arg2);
    scalar("arg3", snap.regs.arg3);
    scalar("stack", snap.regs.stack);
    scalar("frame", snap.regs.frame);
    scalar("counter", snap.regs.counter);
    scalar("base", snap.regs.base);
    scalar("data", snap.regs.data);
    scalar("source", snap.regs.source);
    scalar("dest", snap.regs.dest);
    scalar("instruction", snap.regs.instruction);
    scalar("flags", snap.regs.flags);
    scalar("segment_cs", snap.regs.segment_cs);
    scalar("segment_ds", snap.regs.segment_ds);
    scalar("segment_es", snap.regs.segment_es);
    scalar("segment_ss", snap.regs.segment_ss);
    scalar("fs_base", snap.regs.fs_base);
    scalar("gs_base", snap.regs.gs_base);
    scalar("direction_flag", snap.regs.direction_flag);
    scalar("interrupt_flag", snap.regs.interrupt_flag);
    scalar("iopl", snap.regs.iopl);
    scalar("operand_size_bits", snap.regs.operand_size_bits);
    scalar("address_size_bits", snap.regs.address_size_bits);
    scalar("segment_cs_base", snap.regs.segment_cs_base);
    scalar("segment_cs_limit", snap.regs.segment_cs_limit);
    scalar("segment_ds_base", snap.regs.segment_ds_base);
    scalar("segment_ds_limit", snap.regs.segment_ds_limit);
    scalar("segment_es_base", snap.regs.segment_es_base);
    scalar("segment_es_limit", snap.regs.segment_es_limit);
    scalar("segment_ss_base", snap.regs.segment_ss_base);
    scalar("segment_ss_limit", snap.regs.segment_ss_limit);
    scalar("mxcsr", snap.regs.mxcsr);
    scalar("fpu_control", snap.regs.fpu_control);
    scalar("fpu_status", snap.regs.fpu_status);
    scalar("fpu_tag", snap.regs.fpu_tag);
    scalar("x87_top", snap.regs.x87_top);
    scalar("exception_state", snap.regs.exception_state);
    scalar("debug_status", snap.regs.debug_status);
    scalar("debug_control", snap.regs.debug_control);
    scalar("fp_arg0", snap.regs.fp_arg0);
    scalar("fp_arg1", snap.regs.fp_arg1);
    scalar("fp_arg2", snap.regs.fp_arg2);
    scalar("fp_arg3", snap.regs.fp_arg3);
    scalar("shadow_space_size", snap.regs.shadow_space_size);
    scalar("callee_saved_mask", snap.regs.callee_saved_mask);
    scalar("guest_abi_mode", snap.regs.guest_abi_mode);
    scalar("host_abi_mode", snap.regs.host_abi_mode);
    scalar("struct_return", snap.regs.struct_return);
    scalar("unwind_state", snap.regs.unwind_state);
    scalar("link_register", snap.regs.link_register);
    scalar("fpcr", snap.regs.fpcr);
    scalar("fpsr", snap.regs.fpsr);
    scalar("host_page_size", snap.regs.host_page_size);
    scalar("host_memory_permissions", snap.regs.host_memory_permissions);
    scalar("cache_coherency_state", snap.regs.cache_coherency_state);
    scalar("host_calling_convention", snap.regs.host_calling_convention);
    scalar("vector_state_hash", snap.regs.vector_state_hash);

    if (snap.arch == .arm64) {
        pending_target = snap;
    } else {
        pending_source = snap;
    }
    tryCompare();
}

pub fn reportOperation(op: model.Operation) void {
    runtime_abi.common.writeLine(
        "[{s}][bridge][operation][{s}] seq={d} scope={s} op={s} lhs=0x{x} rhs=0x{x} result=0x{x} width={d} flags_before=0x{x} flags_after=0x{x}\n",
        .{
            archTag(op.arch),
            archRole(op.arch),
            op.sequence,
            scopeSlice(&op.scope, op.scope_len),
            scopeSlice(&op.opname, op.opname_len),
            op.lhs,
            op.rhs,
            op.result,
            op.width_bits,
            op.flags_before,
            op.flags_after,
        },
    );
    if (op.arch == .arm64) {
        last_target_op = op;
    } else {
        last_source_op = op;
    }
}

fn sameKey(a: model.Snapshot, b: model.Snapshot) bool {
    return a.phase == b.phase and
        a.sequence == b.sequence and
        std.mem.eql(u8, scopeSlice(&a.scope, a.scope_len), scopeSlice(&b.scope, b.scope_len));
}

fn compareScalar(scope: []const u8, role: []const u8, source: model.Scalar, target: model.Scalar) void {
    if (!source.valid or !target.valid) return;
    if (source.value != target.value) {
        runtime_abi.common.violation(
            "bridge-register-trace",
            "semantic_mismatch",
            "scope={s} role={s} [x86/DOS/x64]=0x{x} [ARM64]=0x{x}",
            .{ scope, role, source.value, target.value },
        );
        emitOperationContext(scope);
    }
}

pub fn emitOperationContext(scope: []const u8) void {
    if (last_source_op) |op| {
        runtime_abi.common.writeLine(
            "[{s}][bridge][context][source] scope={s} op={s} lhs=0x{x} rhs=0x{x} result=0x{x} flags_before=0x{x} flags_after=0x{x}\n",
            .{ archTag(op.arch), scope, scopeSlice(&op.opname, op.opname_len), op.lhs, op.rhs, op.result, op.flags_before, op.flags_after },
        );
    }
    if (last_target_op) |op| {
        runtime_abi.common.writeLine(
            "[{s}][bridge][context][target] scope={s} op={s} lhs=0x{x} rhs=0x{x} result=0x{x} flags_before=0x{x} flags_after=0x{x}\n",
            .{ archTag(op.arch), scope, scopeSlice(&op.opname, op.opname_len), op.lhs, op.rhs, op.result, op.flags_before, op.flags_after },
        );
    }
}

fn tryCompare() void {
    const source = pending_source orelse return;
    const target = pending_target orelse return;
    if (!sameKey(source, target)) return;

    const scope = scopeSlice(&source.scope, source.scope_len);
    runtime_abi.common.writeLine(
        "[bridge][compare] scope={s} phase={s} seq={d} source={s} target={s}\n",
        .{ scope, phaseName(source.phase), source.sequence, @tagName(source.arch), @tagName(target.arch) },
    );
    compareScalar(scope, "result", source.regs.result, target.regs.result);
    compareScalar(scope, "arg0", source.regs.arg0, target.regs.arg0);
    compareScalar(scope, "arg1", source.regs.arg1, target.regs.arg1);
    compareScalar(scope, "arg2", source.regs.arg2, target.regs.arg2);
    compareScalar(scope, "arg3", source.regs.arg3, target.regs.arg3);
    compareScalar(scope, "stack", source.regs.stack, target.regs.stack);
    compareScalar(scope, "frame", source.regs.frame, target.regs.frame);
    compareScalar(scope, "counter", source.regs.counter, target.regs.counter);
    compareScalar(scope, "base", source.regs.base, target.regs.base);
    compareScalar(scope, "data", source.regs.data, target.regs.data);
    compareScalar(scope, "source", source.regs.source, target.regs.source);
    compareScalar(scope, "dest", source.regs.dest, target.regs.dest);
    compareScalar(scope, "instruction", source.regs.instruction, target.regs.instruction);
    compareScalar(scope, "flags", source.regs.flags, target.regs.flags);
    compareScalar(scope, "fs_base", source.regs.fs_base, target.regs.fs_base);
    compareScalar(scope, "gs_base", source.regs.gs_base, target.regs.gs_base);
    compareScalar(scope, "direction_flag", source.regs.direction_flag, target.regs.direction_flag);
    compareScalar(scope, "interrupt_flag", source.regs.interrupt_flag, target.regs.interrupt_flag);
    compareScalar(scope, "iopl", source.regs.iopl, target.regs.iopl);
    compareScalar(scope, "operand_size_bits", source.regs.operand_size_bits, target.regs.operand_size_bits);
    compareScalar(scope, "address_size_bits", source.regs.address_size_bits, target.regs.address_size_bits);
    compareScalar(scope, "segment_cs_base", source.regs.segment_cs_base, target.regs.segment_cs_base);
    compareScalar(scope, "segment_cs_limit", source.regs.segment_cs_limit, target.regs.segment_cs_limit);
    compareScalar(scope, "segment_ds_base", source.regs.segment_ds_base, target.regs.segment_ds_base);
    compareScalar(scope, "segment_ds_limit", source.regs.segment_ds_limit, target.regs.segment_ds_limit);
    compareScalar(scope, "segment_es_base", source.regs.segment_es_base, target.regs.segment_es_base);
    compareScalar(scope, "segment_es_limit", source.regs.segment_es_limit, target.regs.segment_es_limit);
    compareScalar(scope, "segment_ss_base", source.regs.segment_ss_base, target.regs.segment_ss_base);
    compareScalar(scope, "segment_ss_limit", source.regs.segment_ss_limit, target.regs.segment_ss_limit);
    compareScalar(scope, "mxcsr", source.regs.mxcsr, target.regs.mxcsr);
    compareScalar(scope, "fpu_control", source.regs.fpu_control, target.regs.fpu_control);
    compareScalar(scope, "fpu_status", source.regs.fpu_status, target.regs.fpu_status);
    compareScalar(scope, "fpu_tag", source.regs.fpu_tag, target.regs.fpu_tag);
    compareScalar(scope, "x87_top", source.regs.x87_top, target.regs.x87_top);
    compareScalar(scope, "exception_state", source.regs.exception_state, target.regs.exception_state);
    compareScalar(scope, "debug_status", source.regs.debug_status, target.regs.debug_status);
    compareScalar(scope, "debug_control", source.regs.debug_control, target.regs.debug_control);
    compareScalar(scope, "fp_arg0", source.regs.fp_arg0, target.regs.fp_arg0);
    compareScalar(scope, "fp_arg1", source.regs.fp_arg1, target.regs.fp_arg1);
    compareScalar(scope, "fp_arg2", source.regs.fp_arg2, target.regs.fp_arg2);
    compareScalar(scope, "fp_arg3", source.regs.fp_arg3, target.regs.fp_arg3);
    compareScalar(scope, "shadow_space_size", source.regs.shadow_space_size, target.regs.shadow_space_size);
    compareScalar(scope, "callee_saved_mask", source.regs.callee_saved_mask, target.regs.callee_saved_mask);
    compareScalar(scope, "guest_abi_mode", source.regs.guest_abi_mode, target.regs.guest_abi_mode);
    compareScalar(scope, "host_abi_mode", source.regs.host_abi_mode, target.regs.host_abi_mode);
    compareScalar(scope, "struct_return", source.regs.struct_return, target.regs.struct_return);
    compareScalar(scope, "unwind_state", source.regs.unwind_state, target.regs.unwind_state);
    compareScalar(scope, "link_register", source.regs.link_register, target.regs.link_register);
    compareScalar(scope, "fpcr", source.regs.fpcr, target.regs.fpcr);
    compareScalar(scope, "fpsr", source.regs.fpsr, target.regs.fpsr);
    compareScalar(scope, "host_page_size", source.regs.host_page_size, target.regs.host_page_size);
    compareScalar(scope, "host_memory_permissions", source.regs.host_memory_permissions, target.regs.host_memory_permissions);
    compareScalar(scope, "cache_coherency_state", source.regs.cache_coherency_state, target.regs.cache_coherency_state);
    compareScalar(scope, "host_calling_convention", source.regs.host_calling_convention, target.regs.host_calling_convention);
    compareScalar(scope, "vector_state_hash", source.regs.vector_state_hash, target.regs.vector_state_hash);

    pending_source = null;
    pending_target = null;
}

test "bridge compares normalized snapshots" {
    var source = makeSnapshot(.x86, .checkpoint, 1, "unit");
    source.regs.result = .{ .valid = true, .value = 23 };
    var target = makeSnapshot(.arm64, .checkpoint, 1, "unit");
    target.regs.result = .{ .valid = true, .value = 23 };
    reportSnapshot(source);
    reportSnapshot(target);
}
