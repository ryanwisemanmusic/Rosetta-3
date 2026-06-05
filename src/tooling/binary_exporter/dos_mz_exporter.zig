const std = @import("std");

pub const MzImage = struct {
    bytes: []u8,
};

pub fn exportTinyMz(allocator: std.mem.Allocator, image_body: []const u8) !MzImage {
    const header_size: usize = 0x40;
    const total_size = header_size + image_body.len;
    const bytes = try allocator.alloc(u8, total_size);
    @memset(bytes, 0);

    std.mem.writeInt(u16, bytes[0x00..0x02], 0x5A4D, .little);
    std.mem.writeInt(u16, bytes[0x02..0x04], @truncate(total_size % 512), .little);
    std.mem.writeInt(u16, bytes[0x04..0x06], @intCast((total_size + 511) / 512), .little);
    std.mem.writeInt(u16, bytes[0x08..0x0A], @intCast(header_size / 16), .little);
    std.mem.writeInt(u16, bytes[0x0E..0x10], 0x0000, .little);
    std.mem.writeInt(u16, bytes[0x10..0x12], 0xFFFE, .little);
    std.mem.writeInt(u16, bytes[0x14..0x16], 0x0000, .little);
    std.mem.writeInt(u16, bytes[0x16..0x18], 0x0000, .little);

    @memcpy(bytes[header_size..], image_body);
    return .{ .bytes = bytes };
}

test "tiny mz exporter writes MZ header" {
    const image = try exportTinyMz(std.testing.allocator, "ABC");
    defer std.testing.allocator.free(image.bytes);
    try std.testing.expectEqual(@as(u8, 'M'), image.bytes[0]);
    try std.testing.expectEqual(@as(u8, 'Z'), image.bytes[1]);
}
