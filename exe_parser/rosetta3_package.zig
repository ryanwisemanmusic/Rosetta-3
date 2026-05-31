const std = @import("std");
const pe = @import("pe_parser.zig");

pub const PackageSectionName = ".r3app";

pub const PackageMetadata = struct {
    suite: []const u8 = "",
    launch: []const u8,
    cwd: []const u8,
    interactive: bool = true,
};

pub fn sectionName(section: *const pe.Section) []const u8 {
    return std.mem.sliceTo(&section.name, 0);
}

pub fn rawSectionBytes(image_bytes: []const u8, section: *const pe.Section) []const u8 {
    const start = section.raw_offset;
    const end = start + section.raw_size;
    if (start >= image_bytes.len) return &[_]u8{};
    return image_bytes[start..@min(end, image_bytes.len)];
}

pub fn findSection(image: *const pe.Image, name: []const u8) ?*const pe.Section {
    for (image.sections) |*section| {
        if (std.mem.eql(u8, sectionName(section), name)) return section;
    }
    return null;
}

pub fn encodeMetadata(allocator: std.mem.Allocator, metadata: PackageMetadata) ![]u8 {
    return std.fmt.allocPrint(allocator,
        "kind=rosetta3_app_v1\nsuite={s}\nlaunch={s}\ncwd={s}\ninteractive={s}\n",
        .{
            metadata.suite,
            metadata.launch,
            metadata.cwd,
            if (metadata.interactive) "true" else "false",
        },
    );
}

pub fn parseMetadata(section_bytes: []const u8) !PackageMetadata {
    var end = section_bytes.len;
    while (end > 0 and section_bytes[end - 1] == 0) : (end -= 1) {}
    const trimmed = section_bytes[0..end];
    if (trimmed.len == 0) return error.InvalidMetadata;

    var metadata = PackageMetadata{
        .launch = "",
        .cwd = "",
    };
    var saw_kind = false;

    var iter = std.mem.splitScalar(u8, trimmed, '\n');
    while (iter.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \r\t");
        if (line.len == 0) continue;
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidMetadata;
        const key = line[0..eq];
        const value = line[eq + 1 ..];
        if (std.mem.eql(u8, key, "kind")) {
            if (!std.mem.eql(u8, value, "rosetta3_app_v1")) return error.InvalidMetadata;
            saw_kind = true;
        } else if (std.mem.eql(u8, key, "suite")) {
            metadata.suite = value;
        } else if (std.mem.eql(u8, key, "launch")) {
            metadata.launch = value;
        } else if (std.mem.eql(u8, key, "cwd")) {
            metadata.cwd = value;
        } else if (std.mem.eql(u8, key, "interactive")) {
            metadata.interactive = std.mem.eql(u8, value, "true");
        }
    }

    if (!saw_kind or metadata.launch.len == 0 or metadata.cwd.len == 0) {
        return error.InvalidMetadata;
    }
    return metadata;
}

test "metadata round-trips through text encoding" {
    const allocator = std.testing.allocator;
    const bytes = try encodeMetadata(allocator, .{
        .suite = "basic_snake",
        .launch = "/tmp/basic_snake.host",
        .cwd = "/tmp/basic_snake",
        .interactive = true,
    });
    defer allocator.free(bytes);

    const parsed = try parseMetadata(bytes);
    try std.testing.expectEqualStrings("basic_snake", parsed.suite);
    try std.testing.expectEqualStrings("/tmp/basic_snake.host", parsed.launch);
    try std.testing.expect(parsed.interactive);
}
