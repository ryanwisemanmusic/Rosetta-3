const runtime_abi = @import("runtime_abi_handshake");
const cpu_mod = @import("../execution/cpu_state.zig");
const mem_mod = @import("../execution/segmented_memory.zig");
const bridge = @import("bridge_register_tracing");

var sequence: u64 = 0;

fn stackSlot(mem: *const mem_mod.RealModeMemory, ss: u16, sp: u16, delta: u16) bridge.Scalar {
    const value = mem.read16(ss, sp +% delta) catch return .{};
    return .{ .valid = true, .value = value };
}

fn reportShadow(scope: []const u8, phase: bridge.Phase, seq: u64, cpu: *const cpu_mod.CpuState, mem: *const mem_mod.RealModeMemory) void {
    var target = bridge.makeStackEvent(.arm64, phase, seq, scope);
    target.sp = cpu.physicalSsSp();
    target.fp = cpu.bp;
    target.alignment = @intCast(cpu.sp & 0xF);
    target.top0 = stackSlot(mem, cpu.ss, cpu.sp, 0);
    target.top1 = stackSlot(mem, cpu.ss, cpu.sp, 2);
    target.arg0 = stackSlot(mem, cpu.ss, cpu.sp, 2);
    target.arg1 = stackSlot(mem, cpu.ss, cpu.sp, 4);
    bridge.reportStackEvent(target);
}

pub fn logState(scope: []const u8, phase: bridge.Phase, cpu: *const cpu_mod.CpuState, mem: *const mem_mod.RealModeMemory) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[stack-trace][dos] scope={s} phase={s} seq={d} ss:sp={x}:{x} phys=0x{x} bp=0x{x} align16={d}\n",
        .{ scope, @tagName(phase), sequence, cpu.ss, cpu.sp, cpu.physicalSsSp(), cpu.bp, cpu.sp & 0xF },
    );
    var source = bridge.makeStackEvent(.dos, phase, sequence, scope);
    source.sp = cpu.physicalSsSp();
    source.fp = cpu.bp;
    source.alignment = @intCast(cpu.sp & 0xF);
    source.top0 = stackSlot(mem, cpu.ss, cpu.sp, 0);
    source.top1 = stackSlot(mem, cpu.ss, cpu.sp, 2);
    source.arg0 = stackSlot(mem, cpu.ss, cpu.sp, 2);
    source.arg1 = stackSlot(mem, cpu.ss, cpu.sp, 4);
    bridge.reportStackEvent(source);
    reportShadow(scope, phase, sequence, cpu, mem);
}
