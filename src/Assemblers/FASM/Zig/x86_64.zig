const std = @import("std");
const fasm = @import("fasm_core.zig");
const tables = @import("tables.zig");
const errors = @import("errors.zig");

pub const REX = packed struct(u8) {
    w: bool = false,
    r: bool = false,
    x: bool = false,
    b: bool = false,
    _base: u4 = 0x4,

    pub fn encode(self: REX) u8 {
        return @bitCast(u8, self);
    }

    pub fn fromBits(w: bool, r: bool, x: bool, b: bool) REX {
        return REX{
            .w = w,
            .r = r,
            .x = x,
            .b = b,
        };
    }
};

pub const ModRM = packed struct(u8) {
    rm: u3 = 0,
    reg: u3 = 0,
    mod: u2 = 0,

    pub fn encode(self: ModRM) u8 {
        return @bitCast(u8, self);
    }

    pub fn make(mod: u2, reg: u3, rm: u3) ModRM {
        return ModRM{ .mod = mod, .reg = reg, .rm = rm };
    }
};

pub const SIB = packed struct(u8) {
    base: u3 = 0,
    index: u3 = 0,
    scale: u2 = 0,

    pub fn encode(self: SIB) u8 {
        return @bitCast(u8, self);
    }

    pub fn make(scale: u2, index: u3, base: u3) SIB {
        return SIB{ .scale = scale, .index = index, .base = base };
    }
};

pub const VEX = struct {
    prefix: u8 = 0xC5,
    pp: u2 = 0,
    mmmmm: u5 = 1,
    w: bool = false,
    vvvv: u4 = 0,
    r: bool = true,
    l: bool = false,
    b: bool = true,
    x: bool = true,

    pub fn encode2Byte(self: VEX) [2]u8 {
        return .{
            self.prefix,
            @as(u8, @intCast(u8, @as(u1, @boolToInt(!self.r)) << 7) |
                @as(u8, @intCast(u8, self.vvvv << 3)) |
                @as(u8, @intCast(u8, self.l << 2)) |
                @as(u8, @intCast(u8, self.pp))),
        };
    }

    pub fn encode3Byte(self: VEX) [3]u8 {
        return .{
            0xC4,
            @as(u8, @intCast(u8, @as(u1, @boolToInt(!self.r)) << 7) |
                @as(u8, @intCast(u8, @boolToInt(!self.x)) << 6) |
                @as(u8, @intCast(u8, @boolToInt(!self.b)) << 5) |
                @as(u8, @intCast(u8, self.mmmmm))),
            @as(u8, @intCast(u8, @as(u1, @boolToInt(self.w)) << 7) |
                @as(u8, @intCast(u8, self.vvvv << 3)) |
                @as(u8, @intCast(u8, self.l << 2)) |
                @as(u8, @intCast(u8, self.pp))),
        };
    }
};

pub const Encoder = struct {
    code_type: fasm.CodeType = .code_32,

    pub fn encodeRexPrefix(self: Encoder, rex: REX, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        if (self.code_type == .code_64 and rex.encode() != 0x40) {
            try buffer.append(allocator, rex.encode());
        }
    }

    pub fn encodeOpcode(self: Encoder, opcode: u8, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        try buffer.append(allocator, opcode);
    }

    pub fn encodeModRM(self: Encoder, modrm: ModRM, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        try buffer.append(allocator, modrm.encode());
    }

    pub fn encodeSIB(self: Encoder, sib: SIB, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        try buffer.append(allocator, sib.encode());
    }

    pub fn encodeImmediate(self: Encoder, value: u64, size: u8, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        switch (size) {
            1 => try buffer.append(allocator, @truncate(u8, value)),
            2 => {
                const val = @truncate(u16, value);
                try buffer.appendSlice(allocator, std.mem.asBytes(&val));
            },
            4 => {
                const val = @truncate(u32, value);
                try buffer.appendSlice(allocator, std.mem.asBytes(&val));
            },
            8 => try buffer.appendSlice(allocator, std.mem.asBytes(&value)),
            else => {},
        }
    }

    pub fn encodeDisplacement(self: Encoder, disp: i64, size: u8, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        switch (size) {
            1 => try buffer.append(allocator, @bitCast(u8, @truncate(i8, disp))),
            4 => {
                const val = @bitCast(u32, @truncate(i32, disp));
                try buffer.appendSlice(allocator, std.mem.asBytes(&val));
            },
            else => {},
        }
    }

    pub fn encodeRelativeBranch(self: Encoder, opcode: u8, target: u64, current: u64, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        const rel = @bitCast(i64, target -% (current + 2));
        if (rel >= std.math.minInt(i8) and rel <= std.math.maxInt(i8)) {
            try buffer.append(allocator, opcode);
            try buffer.append(allocator, @bitCast(u8, @truncate(i8, rel)));
        } else if (self.code_type == .code_64) {
            try buffer.append(allocator, 0x0F);
            try buffer.append(allocator, opcode | 0x10);
            const rel32 = @bitCast(u32, @truncate(i32, rel));
            try buffer.appendSlice(allocator, std.mem.asBytes(&rel32));
        } else {
            const rel32 = @bitCast(u32, @truncate(i32, rel));
            try buffer.append(allocator, opcode | 0x10);
            try buffer.appendSlice(allocator, std.mem.asBytes(&rel32));
        }
    }

    pub fn encodeNop(self: Encoder, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        if (self.code_type == .code_64) {
            try buffer.appendSlice(allocator, &.{ 0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00 });
        } else {
            try buffer.appendSlice(allocator, &.{ 0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00 });
        }
    }
};

pub fn registerToRM(reg: u8) u3 {
    return @truncate(u3, reg & 0x07);
}

pub fn registerToREX(reg: u8) bool {
    return (reg & 0x08) != 0;
}

pub fn registerSize(reg: u8) tables.OpSize {
    return switch (reg) {
        0...7 => ._8,
        8...15 => ._16,
        16...23 => ._32,
        24...31 => ._64,
        32...39 => ._32,
        40...47 => ._32,
        48...55 => ._16,
        56...63 => ._8,
        64...79 => ._128,
        80...95 => ._256,
        96...111 => ._512,
        else => ._32,
    };
}

test "REX prefix encoding" {
    const rex = REX.fromBits(true, false, false, false);
    try std.testing.expectEqual(@as(u8, 0x48), rex.encode());
}

test "ModRM encoding" {
    const modrm = ModRM.make(3, 0, 0);
    try std.testing.expectEqual(@as(u8, 0xC0), modrm.encode());
}

test "SIB encoding" {
    const sib = SIB.make(0, 4, 4);
    try std.testing.expectEqual(@as(u8, 0x24), sib.encode());
}

test "VEX 2-byte encoding" {
    const vex = VEX{ .pp = 0, .l = false, .vvvv = 0, .r = true };
    const encoded = vex.encode2Byte();
    try std.testing.expectEqual(@as(u8, 0xC5), encoded[0]);
}

test "register to RM" {
    try std.testing.expectEqual(@as(u3, 0), registerToRM(0));
    try std.testing.expectEqual(@as(u3, 3), registerToRM(3));
    try std.testing.expectEqual(@as(u3, 7), registerToRM(7));
}
