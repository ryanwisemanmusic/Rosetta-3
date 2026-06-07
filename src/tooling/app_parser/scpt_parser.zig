const std = @import("std");

pub const ScptMagic: u32 = 0x73637470;
pub const ScptMagic2: u32 = 0x53434F62;

pub const ScptFormat = enum {
    asd_compiled,
    asd_binary,
    unknown,
};

pub const ScptHeader = packed struct {
    magic: u32,
    version: u32,
    data_offset: u32,
    data_size: u32,
};

pub const ScptDocument = struct {
    format: ScptFormat,
    header: ScptHeader,
    script_data: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ScptDocument) void {
        self.allocator.free(self.script_data);
    }
};

pub fn parseScpt(allocator: std.mem.Allocator, data: []const u8) !ScptDocument {
    if (data.len < 4) return error.TruncatedScpt;

    const magic = std.mem.readInt(u32, data[0..4], .big);
    const format: ScptFormat = if (magic == ScptMagic) .asd_compiled else if (magic == ScptMagic2) .asd_binary else .unknown;

    if (format == .unknown) return error.NotScptFile;

    var header: ScptHeader = undefined;
    if (data.len >= @sizeOf(ScptHeader)) {
        header.magic = std.mem.readInt(u32, data[0..4], .big);
        header.version = std.mem.readInt(u32, data[4..8], .big);
        header.data_offset = if (data.len >= 12) std.mem.readInt(u32, data[8..12], .big) else 0;
        header.data_size = if (data.len >= 16) std.mem.readInt(u32, data[12..16], .big) else 0;
    } else {
        return error.TruncatedScptHeader;
    }

    const script_data = if (header.data_offset + header.data_size <= data.len and header.data_offset >= @sizeOf(ScptHeader))
        try allocator.dupe(u8, data[header.data_offset .. header.data_offset + header.data_size])
    else
        try allocator.dupe(u8, data[@sizeOf(ScptHeader)..]);

    return ScptDocument{
        .format = format,
        .header = header,
        .script_data = script_data,
        .allocator = allocator,
    };
}

test "parse ASD compiled script header" {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(std.testing.allocator);
    const W = std.testing.allocator;
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, ScptMagic, .big);
        try buf.appendSlice(W, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 0x0100, .big);
        try buf.appendSlice(W, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, @sizeOf(ScptHeader), .big);
        try buf.appendSlice(W, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 4, .big);
        try buf.appendSlice(W, &be);
    }
    try buf.appendSlice(W, &[_]u8{ 0x41, 0x42, 0x43, 0x44 });

    var doc = try parseScpt(std.testing.allocator, buf.items);
    defer doc.deinit();
    try std.testing.expectEqual(ScptFormat.asd_compiled, doc.format);
    try std.testing.expectEqualStrings("ABCD", doc.script_data);
}

test "reject non-SCPT data" {
    const data = "NotAScript";
    const result = parseScpt(std.testing.allocator, data);
    try std.testing.expectError(error.NotScptFile, result);
}
