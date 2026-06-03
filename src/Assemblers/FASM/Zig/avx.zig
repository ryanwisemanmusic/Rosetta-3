const std = @import("std");
const fasm = @import("fasm_core.zig");
const x86_64 = @import("x86_64.zig");
const tables = @import("tables.zig");
const errors = @import("errors.zig");

pub const AvxVectorSize = enum(u8) {
    _128 = 0,
    _256 = 1,
    _512 = 2,
};

pub const AvxOpmask = enum(u8) {
    none = 0,
    k1 = 1,
    k2 = 2,
    k3 = 3,
    k4 = 4,
    k5 = 5,
    k6 = 6,
    k7 = 7,
    _,
};

pub const AvxBroadcast = enum(u8) {
    none = 0,
    _1to4 = 1,
    _1to8 = 2,
    _1to16 = 3,
    _,
};

pub const EvexTupleType = enum(u8) {
    full = 0,
    half = 1,
    full_mem = 2,
    half_mem = 3,
    quarter_mem = 4,
    eighth_mem = 5,
    mem128 = 6,
    mov_half = 7,
    _,
};

pub const EvexEncoding = struct {
    p: u2 = 0,
    vvvv: u4 = 0,
    z: bool = false,
    b: bool = false,
    ll: u2 = 0,
    rc: u2 = 0,
    aaa: u3 = 0,
    v: bool = false,
    r: bool = true,
    x: bool = true,
    m: u2 = 1,
    w: bool = false,
    upp: u2 = 0,

    pub fn encode(self: EvexEncoding) [4]u8 {
        const p0: u8 = 0x62;
        const p1: u8 = @as(u8, @intCast(u8, @as(u1, @boolToInt(!self.r)) << 7)) |
            @as(u8, @intCast(u8, @as(u1, @boolToInt(!self.x)) << 6)) |
            @as(u8, @intCast(u8, @as(u1, @boolToInt(!self.b)) << 5)) |
            @as(u8, @intCast(u8, self.m << 3)) |
            @as(u8, @intCast(u8, 1 << 2)) |
            @as(u8, @intCast(u8, 0));
        const p2: u8 = @as(u8, @intCast(u8, @as(u1, @boolToInt(self.w)) << 7)) |
            @as(u8, @intCast(u8, self.vvvv << 3)) |
            @as(u8, @intCast(u8, @boolToInt(self.z)) << 7) |
            @as(u8, @intCast(u8, self.ll << 5)) |
            @as(u8, @intCast(u8, self.b << 4)) |
            @as(u8, @intCast(u8, self.v << 3)) |
            @as(u8, @intCast(u8, self.aaa));
        const p3: u8 = @as(u8, @intCast(u8, self.upp)) |
            @as(u8, @intCast(u8, self.p << 2));

        return .{ p0, p1, p2, p3 };
    }
};

pub const AvxEncoder = struct {
    code_type: fasm.CodeType = .code_32,
    encoder: x86_64.Encoder = .{},

    pub fn encodeVexOp(self: AvxEncoder, opcode: u8, pp: u2, mmmmm: u5, w: bool, l: bool, vvvv: u4, modrm: x86_64.ModRM, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        if (mmmmm <= 3 and !w and vvvv == 0) {
            const vex = x86_64.VEX{
                .pp = pp,
                .mmmmm = mmmmm,
                .w = w,
                .l = l,
                .vvvv = vvvv,
            };
            const encoded = vex.encode2Byte();
            try buffer.appendSlice(allocator, &encoded);
        } else {
            const vex = x86_64.VEX{
                .pp = pp,
                .mmmmm = mmmmm,
                .w = w,
                .l = l,
                .vvvv = vvvv,
            };
            const encoded = vex.encode3Byte();
            try buffer.appendSlice(allocator, &encoded);
        }
        try buffer.append(allocator, opcode);
        try buffer.append(allocator, modrm.encode());
    }

    pub fn encodeEvexOp(self: AvxEncoder, opcode: u8, evex: EvexEncoding, modrm: x86_64.ModRM, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        const encoded = evex.encode();
        try buffer.appendSlice(allocator, &encoded);
        try buffer.append(allocator, opcode);
        try buffer.append(allocator, modrm.encode());
    }

    pub fn encodeVexRm(self: AvxEncoder, opcode: u8, pp: u2, mmmmm: u5, w: bool, l: bool, reg_index: u8, rm_index: u8, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        const modrm = x86_64.ModRM.make(3, x86_64.registerToRM(reg_index), x86_64.registerToRM(rm_index));
        const vvvv: u4 = 0;
        try self.encodeVexOp(opcode, pp, mmmmm, w, l, vvvv, modrm, buffer, allocator);
    }

    pub fn encodeVexRvm(self: AvxEncoder, opcode: u8, pp: u2, mmmmm: u5, w: bool, l: bool, reg_index: u8, v_index: u8, rm_index: u8, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        const modrm = x86_64.ModRM.make(3, x86_64.registerToRM(reg_index), x86_64.registerToRM(rm_index));
        const vvvv: u4 = @truncate(u4, v_index);
        try self.encodeVexOp(opcode, pp, mmmmm, w, l, vvvv, modrm, buffer, allocator);
    }

    pub fn encodeVexMv(self: AvxEncoder, opcode: u8, pp: u2, mmmmm: u5, w: bool, l: bool, reg_index: u8, v_index: u8, rm_index: u8, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        const modrm = x86_64.ModRM.make(3, x86_64.registerToRM(rm_index), x86_64.registerToRM(reg_index));
        const vvvv: u4 = @truncate(u4, v_index);
        try self.encodeVexOp(opcode, pp, mmmmm, w, l, vvvv, modrm, buffer, allocator);
    }
};

pub fn isAvxInstruction(mnemonic: []const u8) bool {
    return std.ascii.startsWithIgnoreCase(mnemonic, "v") or
        std.ascii.eqIgnoreCase(mnemonic, "vmovaps") or
        std.ascii.eqIgnoreCase(mnemonic, "vmovdqa") or
        std.ascii.eqIgnoreCase(mnemonic, "vaddps") or
        std.ascii.eqIgnoreCase(mnemonic, "vsubps") or
        std.ascii.eqIgnoreCase(mnemonic, "vmulps") or
        std.ascii.eqIgnoreCase(mnemonic, "vdivps") or
        std.ascii.eqIgnoreCase(mnemonic, "vaddpd") or
        std.ascii.eqIgnoreCase(mnemonic, "vsubpd") or
        std.ascii.eqIgnoreCase(mnemonic, "vmulpd") or
        std.ascii.eqIgnoreCase(mnemonic, "vdivpd") or
        std.ascii.eqIgnoreCase(mnemonic, "vxorps") or
        std.ascii.eqIgnoreCase(mnemonic, "vorps") or
        std.ascii.eqIgnoreCase(mnemonic, "vandps") or
        std.ascii.eqIgnoreCase(mnemonic, "vfmadd") or
        std.ascii.eqIgnoreCase(mnemonic, "vfmsub") or
        std.ascii.eqIgnoreCase(mnemonic, "vfnmadd") or
        std.ascii.eqIgnoreCase(mnemonic, "vfnmsub") or
        std.ascii.eqIgnoreCase(mnemonic, "vbroadcast") or
        std.ascii.eqIgnoreCase(mnemonic, "vextract") or
        std.ascii.eqIgnoreCase(mnemonic, "vinsert") or
        std.ascii.eqIgnoreCase(mnemonic, "vperm") or
        std.ascii.eqIgnoreCase(mnemonic, "vpshuf") or
        std.ascii.eqIgnoreCase(mnemonic, "vunpck") or
        std.ascii.eqIgnoreCase(mnemonic, "vpblend") or
        std.ascii.eqIgnoreCase(mnemonic, "vgather") or
        std.ascii.eqIgnoreCase(mnemonic, "vscatter");
}

test "AVX instruction detection" {
    try std.testing.expect(isAvxInstruction("vaddps"));
    try std.testing.expect(isAvxInstruction("vmovaps"));
    try std.testing.expect(!isAvxInstruction("movaps"));
}

test "VEX RVM encoding" {
    var encoder = AvxEncoder{};
    var buffer = std.ArrayListUnmanaged(u8){};
    defer buffer.deinit(std.testing.allocator);

    try encoder.encodeVexRvm(0x58, 0, 1, false, false, 0, 1, 2, &buffer, std.testing.allocator);
    try std.testing.expect(buffer.items.len > 0);
}

test "EVEX encoding structure" {
    const evex = EvexEncoding{
        .p = 1,
        .ll = 2,
        .w = true,
    };
    const encoded = evex.encode();
    try std.testing.expectEqual(@as(u8, 0x62), encoded[0]);
}
