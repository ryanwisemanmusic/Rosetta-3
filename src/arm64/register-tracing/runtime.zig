const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_register_tracing");
const exception_trace = @import("arm64_exceptions");

pub const Arm64Snapshot = runtime_abi.arm64.HostState;

fn vectorHash(snap: *const Arm64Snapshot) u64 {
    var hash: u64 = 0;
    for (snap.fp) |lane| {
        const low: u64 = @truncate(lane);
        const high: u64 = @truncate(lane >> 64);
        hash ^= low;
        hash ^= high;
    }
    return hash;
}

pub fn init() void {
    runtime_abi.common.acquire();
    runtime_abi.common.writeLine("# [register-trace][arm64] init\n", .{});
}

pub fn deinit() void {
    runtime_abi.common.writeLine("# [register-trace][arm64] deinit\n", .{});
    runtime_abi.common.release();
}

pub fn logCheckpoint(tag: []const u8, snap: *const Arm64Snapshot) void {
    runtime_abi.arm64.validateHostState(tag, snap);
    runtime_abi.arm64.validateCallBoundary(tag, snap);
    runtime_abi.common.writeLine(
        "[register-trace][arm64][{s}] X0=0x{x} X1=0x{x} X2=0x{x} X3=0x{x} X4=0x{x} X5=0x{x} X6=0x{x} X7=0x{x} X8=0x{x} X9=0x{x}\n",
        .{ tag, snap.x[0], snap.x[1], snap.x[2], snap.x[3], snap.x[4], snap.x[5], snap.x[6], snap.x[7], snap.x[8], snap.x[9] },
    );
    runtime_abi.common.writeLine(
        "[register-trace][arm64][{s}] X10=0x{x} X11=0x{x} X12=0x{x} X13=0x{x} X14=0x{x} X15=0x{x} X16=0x{x} X17=0x{x} X18=0x{x} X19=0x{x}\n",
        .{ tag, snap.x[10], snap.x[11], snap.x[12], snap.x[13], snap.x[14], snap.x[15], snap.x[16], snap.x[17], snap.x[18], snap.x[19] },
    );
    runtime_abi.common.writeLine(
        "[register-trace][arm64][{s}] X20=0x{x} X21=0x{x} X22=0x{x} X23=0x{x} X24=0x{x} X25=0x{x} X26=0x{x} X27=0x{x} X28=0x{x} X29=0x{x} X30=0x{x}\n",
        .{ tag, snap.x[20], snap.x[21], snap.x[22], snap.x[23], snap.x[24], snap.x[25], snap.x[26], snap.x[27], snap.x[28], snap.x[29], snap.x[30] },
    );
    runtime_abi.common.writeLine(
        "[register-trace][arm64][{s}] SP=0x{x} PC=0x{x} NZCV=0x{x} FPCR=0x{x} FPSR=0x{x} ABI={s} PAGE={d} PERMS=0x{x} COHERENT={d} DIRTY={d} SIGNAL={s}/0x{x}\n",
        .{
            tag,
            snap.sp,
            snap.pc,
            snap.nzcv,
            snap.fpcr,
            snap.fpsr,
            @tagName(snap.calling_convention),
            snap.page_size,
            snap.memory_permissions,
            @intFromBool(snap.cache_coherent),
            @intFromBool(snap.generated_code_dirty),
            @tagName(snap.signal_kind),
            snap.signal_mapped_exception,
        },
    );
    runtime_abi.common.writeLine(
        "[register-trace][arm64][{s}] NEON_HASH=0x{x} V0=0x{x} V1=0x{x} V2=0x{x} V3=0x{x}\n",
        .{ tag, vectorHash(snap), @as(u64, @truncate(snap.fp[0])), @as(u64, @truncate(snap.fp[1])), @as(u64, @truncate(snap.fp[2])), @as(u64, @truncate(snap.fp[3])) },
    );
    var normalized = bridge.makeSnapshot(.arm64, .checkpoint, 0, tag);
    normalized.regs.result = .{ .valid = true, .value = snap.x[0] };
    normalized.regs.arg0 = .{ .valid = true, .value = snap.x[0] };
    normalized.regs.arg1 = .{ .valid = true, .value = snap.x[1] };
    normalized.regs.arg2 = .{ .valid = true, .value = snap.x[2] };
    normalized.regs.arg3 = .{ .valid = true, .value = snap.x[3] };
    normalized.regs.stack = .{ .valid = true, .value = snap.sp };
    normalized.regs.frame = .{ .valid = true, .value = snap.x[29] };
    normalized.regs.counter = .{ .valid = true, .value = snap.x[1] };
    normalized.regs.base = .{ .valid = true, .value = snap.x[19] };
    normalized.regs.data = .{ .valid = true, .value = snap.x[2] };
    normalized.regs.source = .{ .valid = true, .value = snap.x[20] };
    normalized.regs.dest = .{ .valid = true, .value = snap.x[21] };
    normalized.regs.instruction = .{ .valid = true, .value = snap.pc };
    normalized.regs.flags = .{ .valid = true, .value = snap.nzcv };
    normalized.regs.fp_arg0 = .{ .valid = true, .value = @truncate(snap.fp[0]) };
    normalized.regs.fp_arg1 = .{ .valid = true, .value = @truncate(snap.fp[1]) };
    normalized.regs.fp_arg2 = .{ .valid = true, .value = @truncate(snap.fp[2]) };
    normalized.regs.fp_arg3 = .{ .valid = true, .value = @truncate(snap.fp[3]) };
    normalized.regs.link_register = .{ .valid = true, .value = snap.x[30] };
    normalized.regs.fpcr = .{ .valid = true, .value = snap.fpcr };
    normalized.regs.fpsr = .{ .valid = true, .value = snap.fpsr };
    normalized.regs.host_page_size = .{ .valid = true, .value = snap.page_size };
    normalized.regs.host_memory_permissions = .{ .valid = true, .value = snap.memory_permissions };
    normalized.regs.cache_coherency_state = .{ .valid = true, .value = (@as(u64, @intFromBool(snap.cache_coherent)) | (@as(u64, @intFromBool(snap.generated_code_dirty)) << 1)) };
    normalized.regs.host_calling_convention = .{ .valid = true, .value = @intFromEnum(snap.calling_convention) };
    normalized.regs.vector_state_hash = .{ .valid = true, .value = vectorHash(snap) };
    normalized.regs.unwind_state = .{ .valid = true, .value = snap.signal_mapped_exception };
    bridge.reportSnapshot(normalized);
}

test "arm64 register trace snapshot compiles" {
    init();
    defer deinit();
    var snap: Arm64Snapshot = .{};
    snap.x[0] = 0x1234;
    snap.sp = 0x2000;
    snap.pc = 0x4000;
    snap.x[30] = 0x4444;
    snap.nzcv = 0xA0000000;
    snap.call_boundary = true;
    logCheckpoint("arm64-test", &snap);
    exception_trace.logSignalMapping("arm64-test", 11, 0xC0000005, snap.pc, snap.pc, snap.nzcv);
    try std.testing.expectEqual(@as(u64, 0x1234), snap.x[0]);
}
