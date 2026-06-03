const std = @import("std");
const testing = std.testing;
const runtime_abi = @import("runtime_abi_handshake");
const mem_trace = @import("memory/runtime.zig");
const stack_trace = @import("stack/runtime.zig");

/// 32-bit x86 general-purpose register identifiers.
pub const Register = enum(u4) {
    eax = 0,
    ecx = 1,
    edx = 2,
    ebx = 3,
    esp = 4,
    ebp = 5,
    esi = 6,
    edi = 7,

    pub fn name(self: Register) []const u8 {
        return @tagName(self);
    }

    /// Convert a NASM register name (e.g. "eax", "ax", "al") to a Register.
    /// Only the 32-bit name is canonical; sub-registers map to the same full register.
    pub fn fromName(name_: []const u8) ?Register {
        var lower_buf: [16]u8 = undefined;
        const name_len = @min(name_.len, lower_buf.len);
        for (name_[0..name_len], 0..) |c, i| {
            lower_buf[i] = std.ascii.toLower(c);
        }
        const lower = lower_buf[0..name_len];
        if (std.mem.eql(u8, lower, "eax")) return .eax;
        if (std.mem.eql(u8, lower, "ecx")) return .ecx;
        if (std.mem.eql(u8, lower, "edx")) return .edx;
        if (std.mem.eql(u8, lower, "ebx")) return .ebx;
        if (std.mem.eql(u8, lower, "esp")) return .esp;
        if (std.mem.eql(u8, lower, "ebp")) return .ebp;
        if (std.mem.eql(u8, lower, "esi")) return .esi;
        if (std.mem.eql(u8, lower, "edi")) return .edi;
        if (std.mem.eql(u8, lower, "ax"))   return .eax;
        if (std.mem.eql(u8, lower, "cx"))   return .ecx;
        if (std.mem.eql(u8, lower, "dx"))   return .edx;
        if (std.mem.eql(u8, lower, "bx"))   return .ebx;
        if (std.mem.eql(u8, lower, "sp"))   return .esp;
        if (std.mem.eql(u8, lower, "bp"))   return .ebp;
        if (std.mem.eql(u8, lower, "si"))   return .esi;
        if (std.mem.eql(u8, lower, "di"))   return .edi;
        if (std.mem.eql(u8, lower, "al"))   return .eax;
        if (std.mem.eql(u8, lower, "cl"))   return .ecx;
        if (std.mem.eql(u8, lower, "dl"))   return .edx;
        if (std.mem.eql(u8, lower, "bl"))   return .ebx;
        return null;
    }
};

/// x86 FLAGS register layout (EFLAGS).
pub const Flags = packed struct(u32) {
    cf: u1 = 0,         // Carry
    reserved1: u1 = 1,  // bit 1 (always 1)
    pf: u1 = 0,         // Parity
    reserved2: u1 = 0,  // bit 3
    af: u1 = 0,         // Auxiliary Carry
    reserved3: u1 = 0,  // bit 5
    zf: u1 = 0,         // Zero
    sf: u1 = 0,         // Sign
    tf: u1 = 0,         // Trap
    if_: u1 = 1,        // Interrupt Enable
    df: u1 = 0,         // Direction
    of: u1 = 0,         // Overflow
    iopl: u2 = 0,       // I/O Privilege Level
    nt: u1 = 0,         // Nested Task
    reserved4: u1 = 0,  // bit 15
    rf: u1 = 0,         // Resume
    vm: u1 = 0,         // Virtual 8086 Mode
    ac: u1 = 0,         // Alignment Check
    vif: u1 = 0,        // Virtual Interrupt
    vip: u1 = 0,        // Virtual Interrupt Pending
    id: u1 = 0,         // ID
    reserved5: u10 = 0, // bits 22-31

    /// Read flags as a raw u32.
    pub fn raw(self: Flags) u32 {
        return @bitCast(self);
    }

    /// Set flags from a raw u32.
    pub fn fromRaw(val: u32) Flags {
        return @bitCast(val);
    }
};

/// Emulated x86 register file — holds all general-purpose registers,
/// the instruction pointer, the EFLAGS register, and segment selectors.
pub const RegisterFile = struct {
    eax: u32 = 0,
    ecx: u32 = 0,
    edx: u32 = 0,
    ebx: u32 = 0,
    esp: u32 = 0,
    ebp: u32 = 0,
    esi: u32 = 0,
    edi: u32 = 0,
    eip: u32 = 0,
    flags: Flags = .{},
    cs: u32 = 0,
    ds: u32 = 0,
    es: u32 = 0,
    fs: u32 = 0,
    gs: u32 = 0,
    ss: u32 = 0,

    /// Get a register by its enum tag.
    pub fn get(self: *const RegisterFile, reg: Register) u32 {
        return switch (reg) {
            .eax => self.eax,
            .ecx => self.ecx,
            .edx => self.edx,
            .ebx => self.ebx,
            .esp => self.esp,
            .ebp => self.ebp,
            .esi => self.esi,
            .edi => self.edi,
        };
    }

    /// Set a register by its enum tag.
    pub fn set(self: *RegisterFile, reg: Register, value: u32) void {
        switch (reg) {
            .eax => self.eax = value,
            .ecx => self.ecx = value,
            .edx => self.edx = value,
            .ebx => self.ebx = value,
            .esp => self.esp = value,
            .ebp => self.ebp = value,
            .esi => self.esi = value,
            .edi => self.edi = value,
        }
    }

    /// Get the low 16 bits of a register.
    pub fn get16(self: *const RegisterFile, reg: Register) u16 {
        return @truncate(self.get(reg));
    }

    /// Set the low 16 bits of a register (preserving high 16 bits).
    pub fn set16(self: *RegisterFile, reg: Register, value: u16) void {
        const wide = self.get(reg) & 0xFFFF0000 | value;
        self.set(reg, wide);
    }

    /// Get the low 8 bits of a register.
    pub fn get8(self: *const RegisterFile, reg: Register) u8 {
        return @truncate(self.get(reg));
    }

    /// Set the low 8 bits of a register (preserving high 24 bits).
    pub fn set8(self: *RegisterFile, reg: Register, value: u8) void {
        const wide = self.get(reg) & 0xFFFFFF00 | value;
        self.set(reg, wide);
    }

    /// Push a 32-bit value onto the emulated stack (pre-decrement ESP).
    pub fn push(self: *RegisterFile, mem: *Memory, value: u32) void {
        self.esp -|= 4;
        mem.write32(self.esp, value);
        stack_trace.logState("push", .after_instruction, self, mem);
    }

    /// Pop a 32-bit value from the emulated stack (post-increment ESP).
    pub fn pop(self: *RegisterFile, mem: *const Memory) u32 {
        const value = mem.read32(self.esp);
        self.esp +|= 4;
        stack_trace.logState("pop", .after_instruction, self, mem);
        return value;
    }

    // ---- Flag helpers (matching x86 semantics) ----

    pub fn setZero(self: *RegisterFile, result: u32) void {
        self.flags.zf = if (result == 0) 1 else 0;
    }

    pub fn setSign(self: *RegisterFile, result: u32) void {
        self.flags.sf = @intCast(result >> 31);
    }

    pub fn setZeroSign(self: *RegisterFile, result: u32) void {
        self.setZero(result);
        self.setSign(result);
    }

    pub fn setCarry(self: *RegisterFile, a: u32, b: u32, _: u64, bit_count: u6, is_sub: bool) void {
        self.flags.cf = if (is_sub)
            @intFromBool(a < b)
        else
            @intFromBool(@as(u64, a) + @as(u64, b) > (@as(u64, 1) << bit_count) - 1);
    }

    pub fn setOverflow(self: *RegisterFile, a: u32, b: u32, result: u32, is_sub: bool) void {
        const a_sign = a >> 31;
        const b_sign = b >> 31;
        const r_sign = result >> 31;
        self.flags.of = if (is_sub)
            @intCast((a_sign ^ b_sign) & (a_sign ^ r_sign))
        else
            @intCast((~a_sign & ~b_sign & r_sign) | (a_sign & b_sign & ~r_sign));
    }

    /// Update ZF and SF after an arithmetic operation.
    pub fn update_zs(self: *RegisterFile, result: u32) void {
        self.setZeroSign(result);
    }

    /// Update ZF, SF, CF, and OF after an arithmetic operation.
    pub fn update_zsco(self: *RegisterFile, a: u32, b: u32, result: u32, is_sub: bool) void {
        self.setZeroSign(result);
        self.setCarry(a, b, result, 32, is_sub);
        self.setOverflow(a, b, result, is_sub);
    }

    /// Apply the result of TEST (sets ZF, SF, clears CF, OF).
    pub fn update_test(self: *RegisterFile, result: u32) void {
        self.setZeroSign(result);
        self.flags.cf = 0;
        self.flags.of = 0;
    }

    /// Apply the result of CMP (same as SUB but result is discarded).
    pub fn update_cmp(self: *RegisterFile, a: u32, b: u32) void {
        const result = a -% b;
        self.update_zsco(a, b, result, true);
    }
};

/// Simple flat memory model with byte-addressable access.
pub const Memory = struct {
    data: []u8,
    owned: bool,
    allocator: std.mem.Allocator,
    base: u32, // base address offset

    pub fn init(allocator: std.mem.Allocator, size: u32) Memory {
        const slice = allocator.alloc(u8, size) catch unreachable;
        @memset(slice, 0);
        return .{ .data = slice, .owned = true, .allocator = allocator, .base = 0 };
    }

    pub fn fromSlice(slice: []u8) Memory {
        return .{ .data = slice, .owned = false, .allocator = undefined, .base = 0 };
    }

    pub fn deinit(self: *Memory) void {
        if (self.owned) {
            self.allocator.free(self.data);
        }
    }

    pub fn read8(self: *const Memory, addr: u32) u8 {
        runtime_abi.x86.validateFlatMemoryAccess(.read, self.base, self.data.len, addr, 1);
        const idx = addr - self.base;
        if (idx >= self.data.len) return 0;
        const value = self.data[idx];
        mem_trace.logRead("read8", addr, 1, value);
        return value;
    }

    pub fn read16(self: *const Memory, addr: u32) u16 {
        runtime_abi.x86.validateFlatMemoryAccess(.read, self.base, self.data.len, addr, 2);
        const idx = addr - self.base;
        if (idx + 2 > self.data.len) return 0;
        const value: u16 = @bitCast([_]u8{ self.data[idx], self.data[idx + 1] });
        mem_trace.logRead("read16", addr, 2, value);
        return value;
    }

    pub fn read32(self: *const Memory, addr: u32) u32 {
        runtime_abi.x86.validateFlatMemoryAccess(.read, self.base, self.data.len, addr, 4);
        const idx = addr - self.base;
        if (idx + 4 > self.data.len) return 0;
        const value: u32 = @bitCast([_]u8{ self.data[idx], self.data[idx + 1], self.data[idx + 2], self.data[idx + 3] });
        mem_trace.logRead("read32", addr, 4, value);
        return value;
    }

    pub fn write8(self: *Memory, addr: u32, value: u8) void {
        runtime_abi.x86.validateFlatMemoryAccess(.write, self.base, self.data.len, addr, 1);
        const idx = addr - self.base;
        if (idx < self.data.len) {
            self.data[idx] = value;
            mem_trace.logWrite("write8", addr, 1, value);
        }
    }

    pub fn write16(self: *Memory, addr: u32, value: u16) void {
        runtime_abi.x86.validateFlatMemoryAccess(.write, self.base, self.data.len, addr, 2);
        const idx = addr - self.base;
        const bytes = @as([2]u8, @bitCast(value));
        if (idx + 2 <= self.data.len) {
            self.data[idx] = bytes[0];
            self.data[idx + 1] = bytes[1];
            mem_trace.logWrite("write16", addr, 2, value);
        }
    }

    pub fn write32(self: *Memory, addr: u32, value: u32) void {
        runtime_abi.x86.validateFlatMemoryAccess(.write, self.base, self.data.len, addr, 4);
        const idx = addr - self.base;
        const bytes = @as([4]u8, @bitCast(value));
        if (idx + 4 <= self.data.len) {
            self.data[idx] = bytes[0];
            self.data[idx + 1] = bytes[1];
            self.data[idx + 2] = bytes[2];
            self.data[idx + 3] = bytes[3];
            mem_trace.logWrite("write32", addr, 4, value);
        }
    }
};

// ---- Tests ----
test "register get/set" {
    var rf = RegisterFile{};
    rf.set(.eax, 0xDEADBEEF);
    try testing.expectEqual(@as(u32, 0xDEADBEEF), rf.get(.eax));
    rf.set16(.eax, 0xBEEF);
    try testing.expectEqual(@as(u32, 0xDEADBEEF), rf.get(.eax));
}

test "register fromName" {
    try testing.expectEqual(Register.eax, Register.fromName("eax").?);
    try testing.expectEqual(Register.eax, Register.fromName("ax").?);
    try testing.expectEqual(Register.eax, Register.fromName("al").?);
    try testing.expectEqual(Register.ecx, Register.fromName("cx").?);
    try testing.expectEqual(null, Register.fromName("foo"));
}

test "push/pop" {
    var rf = RegisterFile{};
    var mem = Memory.init(std.testing.allocator, 1024);
    defer mem.deinit();

    rf.esp = 512;
    rf.push(&mem, 0x12345678);
    const val = rf.pop(&mem);
    try testing.expectEqual(@as(u32, 0x12345678), val);
}

test "flag helpers" {
    var rf = RegisterFile{};
    rf.update_cmp(10, 10);
    try testing.expectEqual(@as(u1, 1), rf.flags.zf);

    rf.update_cmp(10, 20);
    try testing.expectEqual(@as(u1, 1), rf.flags.cf); // borrow
}
