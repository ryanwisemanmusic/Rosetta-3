const std = @import("std");

pub const StringsEntry = struct {
    key: []const u8,
    value: []const u8,
};

pub const StringsFile = struct {
    entries: []StringsEntry,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *StringsFile) void {
        for (self.entries) |e| {
            self.allocator.free(e.key);
            self.allocator.free(e.value);
        }
        self.allocator.free(self.entries);
    }
};

pub fn parseStrings(allocator: std.mem.Allocator, data: []const u8) !StringsFile {
    var entries: std.ArrayList(StringsEntry) = .empty;
    errdefer {
        for (entries.items) |e| {
            allocator.free(e.key);
            allocator.free(e.value);
        }
        entries.deinit(allocator);
    }

    var i: usize = 0;
    while (i < data.len) {
        while (i < data.len and (data[i] == '\n' or data[i] == '\r')) {
            i += 1;
        }
        if (i >= data.len) break;
        if (data[i] == '/') {
            while (i < data.len and data[i] != '\n') i += 1;
            continue;
        }
        const line_start = i;
        while (i < data.len and data[i] != '\n') i += 1;
        const line = data[line_start..i];
        const eq_pos = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const semicolon_pos = std.mem.lastIndexOfScalar(u8, line, ';') orelse line.len;
        const key = std.mem.trim(u8, line[0..eq_pos], " \t\"");
        const raw_val = std.mem.trim(u8, line[eq_pos + 1 .. semicolon_pos], " \t\"");
        const key_copy = try allocator.dupe(u8, key);
        errdefer allocator.free(key_copy);
        const val_copy = try allocator.dupe(u8, raw_val);
        errdefer allocator.free(val_copy);
        try entries.append(allocator, .{ .key = key_copy, .value = val_copy });
    }

    return .{
        .entries = try entries.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

test "parse simple .strings file" {
    const data = "\"greeting\" = \"Hello\";\n\"farewell\" = \"Goodbye\";\n";
    var sf = try parseStrings(std.testing.allocator, data);
    defer sf.deinit();
    try std.testing.expectEqual(@as(usize, 2), sf.entries.len);
    try std.testing.expectEqualStrings("greeting", sf.entries[0].key);
    try std.testing.expectEqualStrings("Hello", sf.entries[0].value);
    try std.testing.expectEqualStrings("farewell", sf.entries[1].key);
    try std.testing.expectEqualStrings("Goodbye", sf.entries[1].value);
}

test "skip comments and blank lines" {
    const data = "// comment\n\n\"key\" = \"val\";\n";
    var sf = try parseStrings(std.testing.allocator, data);
    defer sf.deinit();
    try std.testing.expectEqual(@as(usize, 1), sf.entries.len);
}
