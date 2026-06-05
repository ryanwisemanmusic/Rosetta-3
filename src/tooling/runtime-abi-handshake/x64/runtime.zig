const std = @import("std");
const common = @import("../common.zig");
pub const AbiMode = enum(u8) {
    windows_x64 = 1,
    systemv_amd64 = 2,
    macos_arm64_host = 3,
    guest_vs_host = 4,
};

pub fn init() void {
    common.acquire();
}

pub fn deinit() void {
    common.release();
}

pub fn validateState(phase: []const u8, regs: anytype) void {
    common.noteValidation();
    const rip = regs.rip;
    const rsp = regs.rsp;
    const rflags = regs.rflags;
    const fs_base = regs.fs_base;
    const gs_base = regs.gs_base;
    if ((rflags & 0x2) == 0)
        common.violation("x64", "rflags_reserved1", "{s}: RFLAGS bit1 cleared (raw=0x{x})", .{ phase, rflags });
    if ((rsp & 0xF) != 0)
        common.violation("x64", "stack_alignment", "{s}: RSP 0x{x} is not 16-byte aligned", .{ phase, rsp });
    if (rip == 0)
        common.violation("x64", "rip_zero", "{s}: RIP is zero", .{phase});
    if (fs_base == 0 and gs_base == 0)
        common.violation("x64", "segment_bases", "{s}: FS/GS bases are both zero", .{phase});
    validateAbiBoundary(phase, regs);
}

pub fn validateAddressing(ip_after_decode: u64, computed: u64) void {
    common.noteValidation();
    if (computed == 0)
        common.violation("x64", "address_zero", "computed x64 address is zero (RIP after decode 0x{x})", .{ip_after_decode});
}

pub fn validateMemoryAccess(kind: []const u8, addr: u64, width: usize, permissions: u8, aligned: bool, null_page: bool, guard_page: bool, canonical: bool, stack_access: bool) void {
    common.noteValidation();
    if (!canonical)
        common.violation("x64", "canonical_address", "{s} at 0x{x} width {d} is non-canonical", .{ kind, addr, width });
    if (null_page)
        common.violation("x64", "null_page", "{s} at 0x{x} touched null page", .{ kind, addr });
    if (guard_page)
        common.violation("x64", "guard_page", "{s} at 0x{x} touched guard page", .{ kind, addr });
    if (!aligned)
        common.violation("x64", "unaligned_access", "{s} at 0x{x} width {d} unaligned", .{ kind, addr, width });
    const need_bit: u8 = if (std.mem.eql(u8, kind, "write")) 1 << 1 else if (std.mem.eql(u8, kind, "fetch")) 1 << 2 else 1 << 0;
    if ((permissions & need_bit) == 0)
        common.violation("x64", "page_permissions", "{s} at 0x{x} width {d} denied by perms 0x{x}", .{ kind, addr, width, permissions });
    _ = stack_access;
}

pub fn validateAbiBoundary(phase: []const u8, regs: anytype) void {
    common.noteValidation();
    const abi_mode: AbiMode = @enumFromInt(@intFromEnum(regs.abi_mode));
    switch (abi_mode) {
        .windows_x64 => validateWindowsX64(phase, regs),
        .systemv_amd64 => validateSystemV(phase, regs),
        .macos_arm64_host => validateHostBoundary(phase, regs),
        .guest_vs_host => {
            validateWindowsX64(phase, regs);
            validateHostBoundary(phase, regs);
        },
    }
}

fn validateWindowsX64(phase: []const u8, regs: anytype) void {
    if (regs.guest_call_boundary and regs.shadow_space_bytes < 32)
        common.violation("x64", "shadow_space", "{s}: Windows x64 call boundary requires 32-byte shadow space, saw {d}", .{ phase, regs.shadow_space_bytes });
    if (regs.guest_call_boundary and (regs.rsp & 0xF) != 0)
        common.violation("x64", "call_alignment", "{s}: Windows x64 call boundary RSP 0x{x} not 16-byte aligned", .{ phase, regs.rsp });
    if (regs.varargs_duplicate_mask != 0 and (regs.varargs_duplicate_mask & 0xF) == 0)
        common.violation("x64", "varargs_duplication", "{s}: varargs duplicate mask 0x{x} set outside XMM0-3/RCX-R9 duplication envelope", .{ phase, regs.varargs_duplicate_mask });
    if (regs.struct_return_ptr != 0 and regs.rcx != regs.struct_return_ptr)
        common.violation("x64", "struct_return", "{s}: Windows x64 struct return expects RCX=0x{x}, saw 0x{x}", .{ phase, regs.struct_return_ptr, regs.rcx });
    if (regs.guest_call_boundary and !regs.unwind_info_present)
        common.violation("x64", "unwind_metadata", "{s}: Windows x64 guest call boundary missing unwind metadata/SEH state", .{phase});
}

fn validateSystemV(phase: []const u8, regs: anytype) void {
    if (regs.shadow_space_bytes != 0)
        common.violation("x64", "sysv_shadow_space", "{s}: System V ABI should not reserve Windows shadow space, saw {d}", .{ phase, regs.shadow_space_bytes });
    if (regs.struct_return_ptr != 0 and regs.rdi != regs.struct_return_ptr)
        common.violation("x64", "sysv_struct_return", "{s}: System V struct return expects RDI=0x{x}, saw 0x{x}", .{ phase, regs.struct_return_ptr, regs.rdi });
}

fn validateHostBoundary(phase: []const u8, regs: anytype) void {
    const host_mode: AbiMode = @enumFromInt(@intFromEnum(regs.host_abi_mode));
    const abi_mode: AbiMode = @enumFromInt(@intFromEnum(regs.abi_mode));
    if (host_mode != .macos_arm64_host and abi_mode == .guest_vs_host)
        common.violation("x64", "host_abi_mode", "{s}: guest_vs_host mode requires macOS ARM64 host boundary tagging", .{phase});
    if ((regs.rsp & 0xF) != 0)
        common.violation("x64", "host_stack_alignment", "{s}: host ABI boundary requires 16-byte stack alignment, saw RSP=0x{x}", .{ phase, regs.rsp });
}

pub fn validateCalleeSavedPreserved(phase: []const u8, before: anytype, after: anytype) void {
    common.noteValidation();
    const regs = [_]struct { name: []const u8, lhs: u64, rhs: u64 }{
        .{ .name = "RBX", .lhs = before.rbx, .rhs = after.rbx },
        .{ .name = "RBP", .lhs = before.rbp, .rhs = after.rbp },
        .{ .name = "RDI", .lhs = before.rdi, .rhs = after.rdi },
        .{ .name = "RSI", .lhs = before.rsi, .rhs = after.rsi },
        .{ .name = "R12", .lhs = before.r12, .rhs = after.r12 },
        .{ .name = "R13", .lhs = before.r13, .rhs = after.r13 },
        .{ .name = "R14", .lhs = before.r14, .rhs = after.r14 },
        .{ .name = "R15", .lhs = before.r15, .rhs = after.r15 },
    };
    for (regs) |reg| {
        if (reg.lhs != reg.rhs)
            common.violation("x64", "callee_saved", "{s}: callee-saved register {s} changed from 0x{x} to 0x{x}", .{ phase, reg.name, reg.lhs, reg.rhs });
    }
    var i: usize = 6;
    while (i <= 15) : (i += 1) {
        if (before.xmm[i] != after.xmm[i])
            common.violation("x64", "callee_saved_xmm", "{s}: callee-saved XMM{d} changed", .{ phase, i });
    }
}
