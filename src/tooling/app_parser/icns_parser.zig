const std = @import("std");

pub const icns_magic: u32 = 0x69636E73;

pub const IconType = enum(u32) {
    ic07 = 0x69633037,
    ic08 = 0x69633038,
    ic09 = 0x69633039,
    ic10 = 0x69633130,
    ic11 = 0x69633131,
    ic12 = 0x69633132,
    ic13 = 0x69633133,
    ic14 = 0x69633134,
    ic04 = 0x69633034,
    ic05 = 0x69633035,
    TOC = 0x544F4320,
    icon = 0x69636F6E,
    i8mk = 0x69386D6B,
    il32 = 0x696C3332,
    l8mk = 0x6C386D6B,
    is32 = 0x69733332,
    s8mk = 0x73386D6B,
    icp4 = 0x69637034,
    icp5 = 0x69637035,
    icp6 = 0x69637036,
    ic07_ = 0x69633720,
    ic08_ = 0x69633820,
    ic09_ = 0x69633920,
    ic10_ = 0x69633, // often ic10 padded

    pub fn description(self: IconType) []const u8 {
        return switch (self) {
            .ic07 => "128x128 PNG",
            .ic08 => "256x256 PNG",
            .ic09 => "512x512 PNG",
            .ic10 => "512x512@2x PNG",
            .ic11 => "16x16@2x PNG",
            .ic12 => "32x32@2x PNG",
            .ic13 => "128x128@2x PNG",
            .ic14 => "256x256@2x PNG",
            .ic04 => "16x16 16-colour",
            .ic05 => "32x32 16-colour",
            .TOC => "Table of Contents",
            .icon => "Small icon",
            .i8mk => "8-bit mask",
            .il32 => "32x32 24-bit",
            .l8mk => "8-bit mask",
            .is32 => "16x16 24-bit",
            .s8mk => "8-bit mask",
            .icp4 => "16x16 JPEG 2000",
            .icp5 => "32x32 JPEG 2000",
            .icp6 => "64x64 JPEG 2000",
            .ic07_ => "128x128 JPEG 2000",
            .ic08_ => "256x256 JPEG 2000",
            .ic09_ => "512x512 JPEG 2000",
            .ic10_ => "512x512@2x JPEG 2000",
        };
    }

    pub fn is32BitOnly(self: IconType) bool {
        return switch (self) {
            .ic04, .ic05, .icon, .i8mk, .il32, .l8mk, .is32, .s8mk => true,
            else => false,
        };
    }
};

pub const IconFamilyEntry = struct {
    icon_type: IconType,
    offset: u32,
    size: u32,
    data: []const u8,
};

pub const IconFamily = struct {
    entries: []IconFamilyEntry,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *IconFamily) void {
        self.allocator.free(self.entries);
    }

    pub fn needsConversion(self: IconFamily) bool {
        for (self.entries) |e| {
            if (e.icon_type.is32BitOnly()) return true;
        }
        return false;
    }
};

pub fn parseIconFamily(allocator: std.mem.Allocator, data: []const u8) !IconFamily {
    if (data.len < 8) return error.InvalidIconFamily;
    const magic = std.mem.readInt(u32, data[0..4], .big);
    if (magic != icns_magic) return error.InvalidIconFamily;
    const total_size = std.mem.readInt(u32, data[4..8], .big);
    if (total_size > data.len) return error.IconFamilyTruncated;

    var entries: std.ArrayList(IconFamilyEntry) = .empty;
    errdefer entries.deinit(allocator);

    var pos: usize = 8;
    while (pos + 8 <= data.len) {
        const icon_type_val = std.mem.readInt(u32, data[pos..][0..4], .big);
        const entry_size = std.mem.readInt(u32, data[pos..][4..8], .big);
        if (entry_size < 8) break;
        const actual_size = entry_size - 8;
        const entry_data = if (actual_size > 0) data[pos + 8 .. pos + 8 + actual_size] else data[0..0];

        const icon_type: IconType = @enumFromInt(icon_type_val);
        try entries.append(allocator, .{
            .icon_type = icon_type,
            .offset = @intCast(pos),
            .size = entry_size,
            .data = entry_data,
        });
        pos += entry_size;
    }

    return .{
        .entries = try entries.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

test "parse minimal ICNS" {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(std.testing.allocator);
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, icns_magic, .big);
        try buf.appendSlice(std.testing.allocator, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, @as(u32, @intCast(buf.items.len + 4)), .big);
        try buf.appendSlice(std.testing.allocator, &be);
    }

    var family = try parseIconFamily(std.testing.allocator, buf.items);
    defer family.deinit();
    try std.testing.expectEqual(@as(usize, 0), family.entries.len);
    try std.testing.expect(!family.needsConversion());
}

test "parse ICNS with single entry" {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(std.testing.allocator);
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, icns_magic, .big);
        try buf.appendSlice(std.testing.allocator, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 8 + 8 + 16, .big);
        try buf.appendSlice(std.testing.allocator, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, @intFromEnum(IconType.ic07), .big);
        try buf.appendSlice(std.testing.allocator, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 8 + 16, .big);
        try buf.appendSlice(std.testing.allocator, &be);
    }
    try buf.appendSlice(std.testing.allocator, "PNG data here!!!"[0..16]);

    var family = try parseIconFamily(std.testing.allocator, buf.items);
    defer family.deinit();
    try std.testing.expectEqual(@as(usize, 1), family.entries.len);
    try std.testing.expectEqual(IconType.ic07, family.entries[0].icon_type);
    try std.testing.expect(!family.needsConversion());
}
