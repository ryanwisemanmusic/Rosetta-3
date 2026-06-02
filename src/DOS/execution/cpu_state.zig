const std = @import("std");

pub const Flags = packed struct(u16) {
    cf: u1 = 0,
    reserved1: u1 = 1,
    pf: u1 = 0,
    reserved3: u1 = 0,
    af: u1 = 0,
    reserved5: u1 = 0,
    zf: u1 = 0,
    sf: u1 = 0,
    tf: u1 = 0,
    @"if": u1 = 1,
    df: u1 = 0,
    of: u1 = 0,
    iopl: u2 = 0,
    nt: u1 = 0,
    reserved15: u1 = 0,
};

pub const CpuState = struct {
    ax: u16 = 0,
    bx: u16 = 0,
    cx: u16 = 0,
    dx: u16 = 0,
    sp: u16 = 0,
    bp: u16 = 0,
    si: u16 = 0,
    di: u16 = 0,
    cs: u16 = 0,
    ds: u16 = 0,
    es: u16 = 0,
    ss: u16 = 0,
    ip: u16 = 0,
    flags: Flags = .{},

    pub fn ah(self: CpuState) u8 {
        return @truncate(self.ax >> 8);
    }

    pub fn al(self: CpuState) u8 {
        return @truncate(self.ax);
    }

    pub fn bh(self: CpuState) u8 {
        return @truncate(self.bx >> 8);
    }

    pub fn bl(self: CpuState) u8 {
        return @truncate(self.bx);
    }

    pub fn ch(self: CpuState) u8 {
        return @truncate(self.cx >> 8);
    }

    pub fn cl(self: CpuState) u8 {
        return @truncate(self.cx);
    }

    pub fn dh(self: CpuState) u8 {
        return @truncate(self.dx >> 8);
    }

    pub fn dl(self: CpuState) u8 {
        return @truncate(self.dx);
    }

    pub fn setAh(self: *CpuState, value: u8) void {
        self.ax = (self.ax & 0x00FF) | (@as(u16, value) << 8);
    }

    pub fn setAl(self: *CpuState, value: u8) void {
        self.ax = (self.ax & 0xFF00) | value;
    }

    pub fn setBh(self: *CpuState, value: u8) void {
        self.bx = (self.bx & 0x00FF) | (@as(u16, value) << 8);
    }

    pub fn setBl(self: *CpuState, value: u8) void {
        self.bx = (self.bx & 0xFF00) | value;
    }

    pub fn setCh(self: *CpuState, value: u8) void {
        self.cx = (self.cx & 0x00FF) | (@as(u16, value) << 8);
    }

    pub fn setCl(self: *CpuState, value: u8) void {
        self.cx = (self.cx & 0xFF00) | value;
    }

    pub fn setDh(self: *CpuState, value: u8) void {
        self.dx = (self.dx & 0x00FF) | (@as(u16, value) << 8);
    }

    pub fn setDl(self: *CpuState, value: u8) void {
        self.dx = (self.dx & 0xFF00) | value;
    }

    pub fn linearAddress(_: CpuState, segment: u16, offset: u16) u32 {
        return ((@as(u32, segment) << 4) + @as(u32, offset)) & 0xFFFFF;
    }

    pub fn physicalCsIp(self: CpuState) u32 {
        return linearAddress(self, self.cs, self.ip);
    }

    pub fn physicalSsSp(self: CpuState) u32 {
        return linearAddress(self, self.ss, self.sp);
    }
};

test "cpu state exposes byte register access" {
    var cpu: CpuState = .{};
    cpu.setAh(0x12);
    cpu.setAl(0x34);
    try std.testing.expectEqual(@as(u16, 0x1234), cpu.ax);
    try std.testing.expectEqual(@as(u8, 0x12), cpu.ah());
    try std.testing.expectEqual(@as(u8, 0x34), cpu.al());
}

test "linear address wraps to 20-bit real mode" {
    const cpu: CpuState = .{};
    try std.testing.expectEqual(@as(u32, 0x179B8), cpu.linearAddress(0x1234, 0x5678));
    try std.testing.expectEqual(@as(u32, 0x0000F), cpu.linearAddress(0xFFFF, 0x001F));
}
