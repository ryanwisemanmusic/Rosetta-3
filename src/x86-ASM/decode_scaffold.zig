const std = @import("std");
const core = @import("family_core.zig");

pub const SegmentOverride = enum {
    cs,
    ds,
    es,
    fs,
    gs,
    ss,
};

pub const LegacyPrefixes = struct {
    lock: bool = false,
    rep: bool = false,
    repe: bool = false,
    repne: bool = false,
    operand_size_override: bool = false,
    address_size_override: bool = false,
    segment_override: ?SegmentOverride = null,
};

pub const ModRm = packed struct(u8) {
    rm: u3,
    reg: u3,
    mod: u2,
};

pub const Sib = packed struct(u8) {
    base: u3,
    index: u3,
    scale: u2,
};

pub const DecodedDisplacement = struct {
    width: core.OperandWidth,
    value: i32,
};

pub const DecodedImmediate = struct {
    width: core.OperandWidth,
    value: u64,
};

pub const InstructionEnvelope = struct {
    legacy_prefixes: LegacyPrefixes = .{},
    rex_seen: bool = false,
    opcode_bytes: [3]u8 = [_]u8{0} ** 3,
    opcode_len: u8 = 0,
    modrm: ?ModRm = null,
    sib: ?Sib = null,
    displacement: ?DecodedDisplacement = null,
    immediate: ?DecodedImmediate = null,
};

pub const DecodeCursor = struct {
    bytes: []const u8,
    offset: usize = 0,

    pub fn remaining(self: *const DecodeCursor) usize {
        return self.bytes.len -| self.offset;
    }

    pub fn readU8(self: *DecodeCursor) !u8 {
        if (self.offset >= self.bytes.len) return error.EndOfStream;
        defer self.offset += 1;
        return self.bytes[self.offset];
    }

    pub fn readModRm(self: *DecodeCursor) !ModRm {
        return @bitCast(try self.readU8());
    }

    pub fn readSib(self: *DecodeCursor) !Sib {
        return @bitCast(try self.readU8());
    }

    pub fn readDisplacement(self: *DecodeCursor, width: core.OperandWidth) !DecodedDisplacement {
        return switch (width) {
            .byte => .{ .width = .byte, .value = @as(i32, @as(i8, @bitCast(try self.readU8()))) },
            .dword => .{
                .width = .dword,
                .value = @bitCast(@as(u32, @truncate(try readUnsigned(self, .dword)))),
            },
            else => error.UnsupportedWidth,
        };
    }

    pub fn readImmediate(self: *DecodeCursor, width: core.OperandWidth) !DecodedImmediate {
        return .{
            .width = width,
            .value = try readUnsigned(self, width),
        };
    }
};

fn readUnsigned(cursor: *DecodeCursor, width: core.OperandWidth) !u64 {
    return switch (width) {
        .byte => try cursor.readU8(),
        .word => blk: {
            const lo = try cursor.readU8();
            const hi = try cursor.readU8();
            break :blk @as(u64, lo) | (@as(u64, hi) << 8);
        },
        .dword => blk: {
            var result: u64 = 0;
            for (0..4) |shift| {
                result |= @as(u64, try cursor.readU8()) << @intCast(shift * 8);
            }
            break :blk result;
        },
        .qword => blk: {
            var result: u64 = 0;
            for (0..8) |shift| {
                result |= @as(u64, try cursor.readU8()) << @intCast(shift * 8);
            }
            break :blk result;
        },
        else => error.UnsupportedWidth,
    };
}

test "decode cursor parses modrm sib and immediates" {
    var cursor = DecodeCursor{
        .bytes = &[_]u8{ 0x44, 0x24, 0x08 },
    };
    const modrm = try cursor.readModRm();
    const sib = try cursor.readSib();
    const disp = try cursor.readDisplacement(.byte);

    try std.testing.expectEqual(@as(u3, 0b100), modrm.rm);
    try std.testing.expectEqual(@as(u3, 0b000), modrm.reg);
    try std.testing.expectEqual(@as(u2, 0b01), modrm.mod);
    try std.testing.expectEqual(@as(u3, 0b100), sib.base);
    try std.testing.expectEqual(@as(i32, 8), disp.value);
}
