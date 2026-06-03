const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const reg_trace = @import("register-tracing/runtime.zig");

pub const Register64 = enum(u5) {
    rax,
    rcx,
    rdx,
    rbx,
    rsp,
    rbp,
    rsi,
    rdi,
    r8,
    r9,
    r10,
    r11,
    r12,
    r13,
    r14,
    r15,
};

pub const RegisterFile64 = struct {
    rax: u64 = 0,
    rcx: u64 = 0,
    rdx: u64 = 0,
    rbx: u64 = 0,
    rsp: u64 = 0,
    rbp: u64 = 0,
    rsi: u64 = 0,
    rdi: u64 = 0,
    r8: u64 = 0,
    r9: u64 = 0,
    r10: u64 = 0,
    r11: u64 = 0,
    r12: u64 = 0,
    r13: u64 = 0,
    r14: u64 = 0,
    r15: u64 = 0,
    rip: u64 = 0,
    rflags: u64 = 0,
    fs_base: u64 = 0,
    gs_base: u64 = 0,

    pub fn get(self: *const RegisterFile64, reg: Register64) u64 {
        return switch (reg) {
            .rax => self.rax,
            .rcx => self.rcx,
            .rdx => self.rdx,
            .rbx => self.rbx,
            .rsp => self.rsp,
            .rbp => self.rbp,
            .rsi => self.rsi,
            .rdi => self.rdi,
            .r8 => self.r8,
            .r9 => self.r9,
            .r10 => self.r10,
            .r11 => self.r11,
            .r12 => self.r12,
            .r13 => self.r13,
            .r14 => self.r14,
            .r15 => self.r15,
        };
    }

    pub fn set(self: *RegisterFile64, reg: Register64, value: u64) void {
        switch (reg) {
            .rax => self.rax = value,
            .rcx => self.rcx = value,
            .rdx => self.rdx = value,
            .rbx => self.rbx = value,
            .rsp => self.rsp = value,
            .rbp => self.rbp = value,
            .rsi => self.rsi = value,
            .rdi => self.rdi = value,
            .r8 => self.r8 = value,
            .r9 => self.r9 = value,
            .r10 => self.r10 = value,
            .r11 => self.r11 = value,
            .r12 => self.r12 = value,
            .r13 => self.r13 = value,
            .r14 => self.r14 = value,
            .r15 => self.r15 = value,
        }
    }
};

pub const X64State = struct {
    regs: RegisterFile64 = .{},

    pub fn instructionPointer(self: *X64State) *u64 {
        return &self.regs.rip;
    }

    pub fn stackPointer(self: *X64State) *u64 {
        return &self.regs.rsp;
    }
};

test "x64 state covers extended registers and pointers" {
    reg_trace.init();
    defer reg_trace.deinit();
    var state: X64State = .{};
    state.regs.r13 = 0xCAFE_BABE;
    state.regs.rip = 0x1400_1000;
    state.regs.rsp = 0x7FFF_F000;
    runtime_abi.x64.validateState("x64-state-test", state.regs.rip, state.regs.rsp, state.regs.rflags | 0x2, 1, 0);
    reg_trace.logCheckpoint("x64-state-test", &state.regs);
    try std.testing.expectEqual(@as(u64, 0xCAFE_BABE), state.regs.get(.r13));
    try std.testing.expectEqual(@as(u64, 0x1400_1000), state.instructionPointer().*);
}
