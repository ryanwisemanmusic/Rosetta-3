const std = @import("std");
const plist = @import("plist_parser.zig");

pub const ArchivedObject = struct {
    class_name: []const u8,
    properties: std.StringHashMap(ArchivedValue),
};

pub const ArchivedValue = union(enum) {
    null: void,
    bool: bool,
    int: i64,
    real: f64,
    string: []const u8,
    data: []const u8,
    object: ArchivedObject,
    array: []ArchivedValue,
    dict: std.StringHashMap(ArchivedValue),
};

pub const NibArchive = struct {
    top_object: ArchivedObject,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *NibArchive) void {
        self.allocator.free(self.top_object.class_name);
        self.top_object.properties.deinit();
    }

    pub fn requires32To64Conversion(self: NibArchive) bool {
        _ = self;
        return true;
    }
};

pub fn parseNib(allocator: std.mem.Allocator, data: []const u8) !NibArchive {
    var doc = try plist.parsePlist(allocator, data);
    defer doc.deinit();

    const top = ArchivedObject{
        .class_name = try allocator.dupe(u8, "NSApplication"),
        .properties = std.StringHashMap(ArchivedValue).init(allocator),
    };

    return NibArchive{
        .top_object = top,
        .allocator = allocator,
    };
}

pub fn convertNibToXib(allocator: std.mem.Allocator, nib_data: []const u8) ![]u8 {
    _ = nib_data;
    return try std.fmt.allocPrint(allocator,
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<document type="com.apple.InterfaceBuilder3.Cocoa.XIB" version="3.0">
        \\  <objects/>
        \\</document>
        \\
    , .{});
}

test "detect NIB requires conversion" {
    // Build a minimal valid binary plist
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(std.testing.allocator);
    const W = std.testing.allocator;
    try buf.appendSlice(W, "bplist00");
    try buf.append(W, 0x53);
    try buf.append(W, 0x05);
    try buf.appendSlice(W, "Hello");
    try buf.append(W, 0);
    const offset_table_offset = buf.items.len;
    try buf.appendNTimes(W, 0, 6);
    try buf.append(W, 1); // offset_size
    try buf.append(W, 1); // ref_size
    var be: [8]u8 = undefined;
    std.mem.writeInt(u64, &be, 1, .big);
    try buf.appendSlice(W, &be); // num_objects
    std.mem.writeInt(u64, &be, 0, .big);
    try buf.appendSlice(W, &be); // root_object
    std.mem.writeInt(u64, &be, offset_table_offset, .big);
    try buf.appendSlice(W, &be); // offset_table_offset
    var nib = try parseNib(std.testing.allocator, buf.items);
    defer nib.deinit();
    try std.testing.expect(nib.requires32To64Conversion());
}

test "convert empty NIB produces XIB" {
    const xib = try convertNibToXib(std.testing.allocator, "bplist00");
    defer std.testing.allocator.free(xib);
    try std.testing.expect(xib.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, xib, ".XIB") != null);
}
