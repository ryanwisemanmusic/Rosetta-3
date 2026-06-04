const runtime_abi = @import("runtime_abi_handshake");
const reg_map = @import("../register_mapping.zig");
const bridge = @import("bridge_stack");
const reg_trace = @import("../register-tracing/runtime.zig");

fn slot(mem: *const reg_map.Memory, addr: u32) bridge.Scalar {
    if (addr < mem.base or @as(usize, @intCast(addr - mem.base + 4)) > mem.data.len) return .{};
    return .{ .valid = true, .value = mem.read32(addr) };
}

fn reportShadow(scope: []const u8, phase: bridge.Phase, seq: u64, regs: *const reg_map.RegisterFile, mem: *const reg_map.Memory) void {
    var target = bridge.makeStackEvent(.arm64, phase, seq, scope);
    target.sp = regs.esp;
    target.fp = regs.ebp;
    target.alignment = @intCast(regs.esp & 0xF);
    target.top0 = slot(mem, regs.esp);
    target.top1 = slot(mem, regs.esp + 4);
    target.arg0 = slot(mem, regs.esp + 4);
    target.arg1 = slot(mem, regs.esp + 8);
    target.arg2 = slot(mem, regs.esp + 12);
    target.arg3 = slot(mem, regs.esp + 16);
    bridge.reportStackEvent(target, reg_trace.emitOperationContext);
}

pub fn logState(scope: []const u8, phase: bridge.Phase, regs: *const reg_map.RegisterFile, mem: *const reg_map.Memory) void {
    runtime_abi.common.writeLine(
        "[stack-trace][x86] scope={s} phase={s} seq={d} esp=0x{x} ebp=0x{x} align16={d}\n",
        .{ scope, @tagName(phase), reg_trace.currentSequence(), regs.esp, regs.ebp, regs.esp & 0xF },
    );
    var source = bridge.makeStackEvent(.x86, phase, reg_trace.currentSequence(), scope);
    source.sp = regs.esp;
    source.fp = regs.ebp;
    source.alignment = @intCast(regs.esp & 0xF);
    source.top0 = slot(mem, regs.esp);
    source.top1 = slot(mem, regs.esp + 4);
    source.arg0 = slot(mem, regs.esp + 4);
    source.arg1 = slot(mem, regs.esp + 8);
    source.arg2 = slot(mem, regs.esp + 12);
    source.arg3 = slot(mem, regs.esp + 16);
    bridge.reportStackEvent(source, reg_trace.emitOperationContext);
    reportShadow(scope, phase, reg_trace.currentSequence(), regs, mem);
}
