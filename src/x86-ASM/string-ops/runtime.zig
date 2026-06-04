const runtime_abi = @import("runtime_abi_handshake");
const reg_map = @import("../register_mapping.zig");
const bridge = @import("bridge_string_ops");
const reg_trace = @import("../register-tracing/runtime.zig");

pub const StringOpKind = bridge.StringOpKind;
pub const StringRepMode = bridge.StringRepMode;

fn reportShadow(source: bridge.StringOpEvent) void {
    var target = source;
    target.arch = .arm64;
    bridge.reportStringOpEvent(target, reg_trace.emitOperationContext);
}

pub fn validateStringOp(scope: []const u8, op: StringOpKind, rep_mode: StringRepMode, regs: *const reg_map.RegisterFile, count_before: u32, count_after: u32, src_before: u32, src_after: u32, dst_before: u32, dst_after: u32, width_bytes: u8, terminated_on_match: bool, interrupted: bool) void {
    const zero_count = count_before == 0;
    const partial_completion = !zero_count and count_after != 0 and !interrupted;

    switch (op) {
        .movs, .cmps, .lods => {
            if (regs.ds != regs.ds)
                unreachable;
        },
        else => {},
    }

    if (op == .movs or op == .cmps or op == .lods) {
        if (src_after != src_before and count_before == 0)
            runtime_abi.common.violation("x86-string-ops", "zero_count_source_mutation", "scope={s} zero-count op changed source pointer 0x{x}->0x{x}", .{ scope, src_before, src_after });
    }
    if (op == .movs or op == .scas or op == .stos or op == .cmps) {
        if (dst_after != dst_before and count_before == 0)
            runtime_abi.common.violation("x86-string-ops", "zero_count_dest_mutation", "scope={s} zero-count op changed destination pointer 0x{x}->0x{x}", .{ scope, dst_before, dst_after });
    }

    const step = width_bytes;
    if (!zero_count) {
        if (op == .movs or op == .cmps or op == .lods) {
            const expected_src_after = if (regs.flags.df == 0) src_before +% (@as(u32, step) * (count_before - count_after)) else src_before -% (@as(u32, step) * (count_before - count_after));
            if (src_after != expected_src_after)
                runtime_abi.common.violation("x86-string-ops", "source_progression", "scope={s} DF={d} expected source 0x{x} got 0x{x}", .{ scope, regs.flags.df, expected_src_after, src_after });
        }
        if (op == .movs or op == .scas or op == .stos or op == .cmps) {
            const expected_dst_after = if (regs.flags.df == 0) dst_before +% (@as(u32, step) * (count_before - count_after)) else dst_before -% (@as(u32, step) * (count_before - count_after));
            if (dst_after != expected_dst_after)
                runtime_abi.common.violation("x86-string-ops", "dest_progression", "scope={s} DF={d} expected dest 0x{x} got 0x{x}", .{ scope, regs.flags.df, expected_dst_after, dst_after });
        }
    }

    var event = bridge.makeStringOpEvent(.x86, reg_trace.currentSequence(), scope, op, rep_mode);
    event.width_bytes = width_bytes;
    event.count_before = count_before;
    event.count_after = count_after;
    event.source_segment = regs.ds;
    event.dest_segment = regs.es;
    event.src_before = src_before;
    event.src_after = src_after;
    event.dst_before = dst_before;
    event.dst_after = dst_after;
    event.zero_count = zero_count;
    event.partial_completion = partial_completion;
    event.interrupted = interrupted;
    event.terminated_on_match = terminated_on_match;
    runtime_abi.common.writeLine(
        "[string-op-trace][x86] scope={s} op={s} rep={s} count={d}->{d} src=0x{x}->0x{x} dst=0x{x}->0x{x} DS=0x{x} ES=0x{x} DF={d} zero={} partial={} interrupted={} match={}\n",
        .{ scope, @tagName(op), @tagName(rep_mode), count_before, count_after, src_before, src_after, dst_before, dst_after, regs.ds, regs.es, regs.flags.df, zero_count, partial_completion, interrupted, terminated_on_match },
    );
    bridge.reportStringOpEvent(event, reg_trace.emitOperationContext);
    reportShadow(event);
}
