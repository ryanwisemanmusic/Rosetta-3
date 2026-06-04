const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_exceptions");
const cpu_mod = @import("../execution/cpu_state.zig");

var sequence: u64 = 0;

fn rawFlags(flags: cpu_mod.Flags) u16 {
    return @bitCast(flags);
}

fn reportShadow(scope: []const u8, seq: u64, kind: bridge.ExceptionKind, vector: u16, code: u64, address: u64, instruction: u64, flags: u64) void {
    var target = bridge.makeExceptionEvent(.arm64, seq, scope, kind);
    target.vector = vector;
    target.code = code;
    target.address = address;
    target.instruction = instruction;
    target.flags = flags;
    bridge.reportExceptionEvent(target, noopContext);
}

pub fn logInterrupt(scope: []const u8, vector: u8, cpu: *const cpu_mod.CpuState) void {
    sequence += 1;
    const kind: bridge.ExceptionKind = switch (vector) {
        0x10, 0x16, 0x1A, 0x33 => .bios_interrupt,
        else => .dos_software_interrupt,
    };
    const instruction = cpu.physicalCsIp();
    const flags = rawFlags(cpu.flags);
    runtime_abi.common.writeLine(
        "[exception-trace][dos] scope={s} seq={d} kind={s} vector=0x{x} instr=0x{x} flags=0x{x}\n",
        .{ scope, sequence, @tagName(kind), vector, instruction, flags },
    );
    var source = bridge.makeExceptionEvent(.dos, sequence, scope, kind);
    source.vector = vector;
    source.address = instruction;
    source.instruction = instruction;
    source.flags = flags;
    bridge.reportExceptionEvent(source, noopContext);
    reportShadow(scope, sequence, kind, vector, 0, instruction, instruction, flags);
}

fn noopContext(_: []const u8) void {}
