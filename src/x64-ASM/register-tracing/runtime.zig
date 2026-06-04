const runtime_abi = @import("runtime_abi_handshake");
const x64 = @import("../x64_state.zig");
const bridge = @import("bridge_register_tracing");

pub fn init() void {
    runtime_abi.common.acquire();
    runtime_abi.common.writeLine("# [register-trace][x64] init\n", .{});
}

fn vectorHash(regs: *const x64.RegisterFile64) u64 {
    var hash: u64 = 0;
    for (regs.xmm) |lane| {
        const low: u64 = @truncate(lane);
        const high: u64 = @truncate(lane >> 64);
        hash ^= low;
        hash ^= high;
    }
    return hash;
}

pub fn deinit() void {
    runtime_abi.common.writeLine("# [register-trace][x64] deinit\n", .{});
    runtime_abi.common.release();
}

pub fn logCheckpoint(tag: []const u8, regs: *const x64.RegisterFile64) void {
    runtime_abi.common.writeLine(
        "[register-trace][x64][{s}] RAX=0x{x} RCX=0x{x} RDX=0x{x} RBX=0x{x} RSP=0x{x} RBP=0x{x} RSI=0x{x} RDI=0x{x} R8=0x{x} R9=0x{x} R10=0x{x} R11=0x{x} R12=0x{x} R13=0x{x} R14=0x{x} R15=0x{x}\n",
        .{ tag, regs.rax, regs.rcx, regs.rdx, regs.rbx, regs.rsp, regs.rbp, regs.rsi, regs.rdi, regs.r8, regs.r9, regs.r10, regs.r11, regs.r12, regs.r13, regs.r14, regs.r15 },
    );
    runtime_abi.common.writeLine(
        "[register-trace][x64][{s}] RIP=0x{x} RFLAGS=0x{x} FS_BASE=0x{x} GS_BASE=0x{x} ABI={s} HOST_ABI={s} SHADOW={d} VARARGS=0x{x} SRET=0x{x} UNWIND={d} SEH={d}\n",
        .{
            tag,
            regs.rip,
            regs.rflags,
            regs.fs_base,
            regs.gs_base,
            @tagName(regs.abi_mode),
            @tagName(regs.host_abi_mode),
            regs.shadow_space_bytes,
            regs.varargs_duplicate_mask,
            regs.struct_return_ptr,
            @intFromBool(regs.unwind_info_present),
            @intFromBool(regs.seh_scope_present),
        },
    );
    var snap = bridge.makeSnapshot(.x64, .checkpoint, 0, tag);
    snap.regs.result = .{ .valid = true, .value = regs.rax };
    snap.regs.arg0 = .{ .valid = true, .value = regs.rcx };
    snap.regs.arg1 = .{ .valid = true, .value = regs.rdx };
    snap.regs.arg2 = .{ .valid = true, .value = regs.r8 };
    snap.regs.arg3 = .{ .valid = true, .value = regs.r9 };
    snap.regs.stack = .{ .valid = true, .value = regs.rsp };
    snap.regs.frame = .{ .valid = true, .value = regs.rbp };
    snap.regs.counter = .{ .valid = true, .value = regs.rcx };
    snap.regs.base = .{ .valid = true, .value = regs.rbx };
    snap.regs.data = .{ .valid = true, .value = regs.rdx };
    snap.regs.source = .{ .valid = true, .value = regs.rsi };
    snap.regs.dest = .{ .valid = true, .value = regs.rdi };
    snap.regs.instruction = .{ .valid = true, .value = regs.rip };
    snap.regs.flags = .{ .valid = true, .value = regs.rflags };
    snap.regs.fs_base = .{ .valid = true, .value = regs.fs_base };
    snap.regs.gs_base = .{ .valid = true, .value = regs.gs_base };
    snap.regs.fp_arg0 = .{ .valid = true, .value = regs.xmmLow64(0) };
    snap.regs.fp_arg1 = .{ .valid = true, .value = regs.xmmLow64(1) };
    snap.regs.fp_arg2 = .{ .valid = true, .value = regs.xmmLow64(2) };
    snap.regs.fp_arg3 = .{ .valid = true, .value = regs.xmmLow64(3) };
    snap.regs.shadow_space_size = .{ .valid = true, .value = regs.shadow_space_bytes };
    snap.regs.callee_saved_mask = .{ .valid = true, .value = regs.calleeSavedMask() };
    snap.regs.guest_abi_mode = .{ .valid = true, .value = @intFromEnum(regs.abi_mode) };
    snap.regs.host_abi_mode = .{ .valid = true, .value = @intFromEnum(regs.host_abi_mode) };
    snap.regs.host_calling_convention = .{ .valid = true, .value = @intFromEnum(regs.host_abi_mode) };
    snap.regs.struct_return = .{ .valid = regs.struct_return_ptr != 0, .value = regs.struct_return_ptr };
    snap.regs.unwind_state = .{ .valid = true, .value = (@as(u64, @intFromBool(regs.unwind_info_present)) | (@as(u64, @intFromBool(regs.seh_scope_present)) << 1)) };
    snap.regs.vector_state_hash = .{ .valid = true, .value = vectorHash(regs) };
    bridge.reportSnapshot(snap);
}

pub fn logAddressing(tag: []const u8, rip_after_decode: u64, computed: u64) void {
    runtime_abi.common.writeLine(
        "[register-trace][x64][{s}] RIP_AFTER_DECODE=0x{x} ADDR=0x{x}\n",
        .{ tag, rip_after_decode, computed },
    );
}
