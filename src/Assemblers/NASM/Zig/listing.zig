const std = @import("std");

const Allocator = std.mem.Allocator;

pub const ListingState = struct {
    allocator: Allocator,
    page: u32 = 1,
    line_count: u32 = 0,
    page_len: u32 = 60,
    page_width: u32 = 132,
    title: []const u8 = "",
    subtitle: []const u8 = "",
    lines: std.ArrayListUnmanaged(ListingLine) = .{ .items = &.{}, .capacity = 0 },

    const ListingLine = struct {
        line_number: u32,
        offset: u64,
        bytes: []const u8,
        text: []const u8,
    };

    pub fn init(allocator: Allocator) ListingState {
        return ListingState{ .allocator = allocator };
    }

    pub fn deinit(self: *ListingState) void {
        for (self.lines.items) |line| {
            self.allocator.free(line.text);
        }
        self.lines.deinit(self.allocator);
    }

    pub fn emitLine(self: *ListingState, line_number: u32, offset: u64, bytes: []const u8, text: []const u8) !void {
        try self.lines.append(self.allocator, ListingLine{
            .line_number = line_number,
            .offset = offset,
            .bytes = bytes,
            .text = try self.allocator.dupe(u8, text),
        });
        self.line_count += 1;
    }

    pub fn pageBreak(self: *ListingState) void {
        self.page += 1;
        self.line_count = 0;
    }

    pub fn setPageSize(self: *ListingState, lines: u32, width: u32) void {
        self.page_len = lines;
        self.page_width = width;
    }

    pub fn setTitle(self: *ListingState, title_val: []const u8) void {
        self.title = title_val;
    }
};

pub const CrossReference = struct {
    allocator: Allocator,
    entries: std.ArrayListUnmanaged(XrefEntry) = .{ .items = &.{}, .capacity = 0 },

    const XrefEntry = struct {
        name: []const u8,
        def_line: u32 = 0,
        ref_lines: std.ArrayListUnmanaged(u32) = .{ .items = &.{}, .capacity = 0 },
    };

    pub fn init(allocator: Allocator) CrossReference {
        return CrossReference{ .allocator = allocator };
    }

    pub fn deinit(self: *CrossReference) void {
        for (self.entries.items) |*entry| {
            self.allocator.free(entry.name);
            entry.ref_lines.deinit(self.allocator);
        }
        self.entries.deinit(self.allocator);
    }

    pub fn addDefinition(self: *CrossReference, name: []const u8, line: u32) !void {
        const duped = try self.allocator.dupe(u8, name);
        try self.entries.append(self.allocator, XrefEntry{
            .name = duped,
            .def_line = line,
            .ref_lines = .{ .items = &.{}, .capacity = 0 },
        });
    }

    pub fn addReference(self: *CrossReference, name: []const u8, line: u32) !void {
        for (self.entries.items) |*entry| {
            if (std.mem.eql(u8, entry.name, name)) {
                try entry.ref_lines.append(self.allocator, line);
                return;
            }
        }
    }
};

test "listing state page break" {
    var ls = ListingState.init(std.testing.allocator);
    defer ls.deinit();

    ls.pageBreak();
    try std.testing.expectEqual(@as(u32, 2), ls.page);
}

test "cross reference tracking" {
    var xr = CrossReference.init(std.testing.allocator);
    defer xr.deinit();

    try xr.addDefinition("foo", 10);
    try xr.addReference("foo", 20);
    try std.testing.expectEqual(@as(usize, 1), xr.entries.items.len);
}
