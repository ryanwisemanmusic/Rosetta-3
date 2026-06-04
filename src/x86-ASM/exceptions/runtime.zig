const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_exceptions");
const reg_trace = @import("../register-tracing/runtime.zig");
const regs_mod = @import("../register_mapping.zig");

fn reportShadow(scope: []const u8, seq: u64, kind: bridge.ExceptionKind, vector: u16, code: u64, address: u64, instruction: u64, flags: u64) void {
    var target = bridge.makeExceptionEvent(.arm64, seq, scope, kind);
    target.vector = vector;
    target.code = code;
    target.address = address;
    target.instruction = instruction;
    target.flags = flags;
    bridge.reportExceptionEvent(target, reg_trace.emitOperationContext);
}

pub fn logFault(scope: []const u8, kind: bridge.ExceptionKind, vector: u16, code: u64, address: u64, instruction: u64, regs: *const regs_mod.RegisterFile) void {
    const seq = reg_trace.currentSequence();
    runtime_abi.common.writeLine(
        "[exception-trace][x86] scope={s} seq={d} kind={s} vector=0x{x} code=0x{x} addr=0x{x} instr=0x{x} flags=0x{x}\n",
        .{ scope, seq, @tagName(kind), vector, code, address, instruction, regs.flags.raw() },
    );
    var source = bridge.makeExceptionEvent(.x86, seq, scope, kind);
    source.vector = vector;
    source.code = code;
    source.address = address;
    source.instruction = instruction;
    source.flags = regs.flags.raw();
    bridge.reportExceptionEvent(source, reg_trace.emitOperationContext);
    reportShadow(scope, seq, kind, vector, code, address, instruction, regs.flags.raw());
}
