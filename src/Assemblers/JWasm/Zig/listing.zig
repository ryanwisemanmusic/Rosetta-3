const std = @import("std");
const jwasm = @import("jwasm_core.zig");

const Allocator = std.mem.Allocator;

pub const ListingState = struct {
    active: bool = true,
    listing_all: bool = false,
    suppress_all: bool = false,
    cref_active: bool = true,
    list_macro: jwasm.listmacro = .nolistmacro,
    listif: bool = false,
    list_generated_code: bool = false,
    page_length: u8 = 50,
    page_width: u8 = 80,
    current_page: u32 = 1,
    current_line: u32 = 0,
    title: []const u8 = "",
    subtitle: []const u8 = "",

    pub fn emitLine(self: *ListingState, allocator: Allocator, line: []const u8, address: u64, bytes: []const u8) !void {
        _ = allocator;
        _ = line;
        _ = address;
        _ = bytes;
        _ = self;
    }

    pub fn pageBreak(self: *ListingState) void {
        self.current_page += 1;
        self.current_line = 0;
    }

    pub fn setTitle(self: *ListingState, title_val: []const u8) void {
        self.title = title_val;
    }

    pub fn setSubtitle(self: *ListingState, subtitle_val: []const u8) void {
        self.subtitle = subtitle_val;
    }

    pub fn setPageSize(self: *ListingState, length: u8, width: u8) void {
        if (length > 0) self.page_length = length;
        if (width > 0) self.page_width = width;
    }

    pub fn setListMacro(self: *ListingState, mode: jwasm.listmacro) void {
        self.list_macro = mode;
    }

    pub fn setListIf(self: *ListingState, enabled: bool) void {
        self.listif = enabled;
    }

    pub fn toggleCrefl(self: *ListingState) void {
        self.cref_active = !self.cref_active;
    }
};

pub const CrossReference = struct {
    entries: std.StringHashMap(XrefEntry),
    current_line: u32 = 0,

    const XrefEntry = struct {
        name: []const u8,
        defined_at: u32,
        references: std.ArrayListUnmanaged(u32) = .{ .items = &.{}, .capacity = 0 },
    };

    pub fn init(allocator: Allocator) CrossReference {
        return CrossReference{
            .entries = std.StringHashMap(XrefEntry).init(allocator),
        };
    }

    pub fn deinit(self: *CrossReference) void {
        var it = self.entries.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.references.deinit(std.heap.page_allocator);
        }
        self.entries.deinit();
    }

    pub fn addReference(self: *CrossReference, name: []const u8, line: u32) !void {
        const gop = try self.entries.getOrPut(name);
        if (!gop.found_existing) {
            gop.value_ptr.* = XrefEntry{
                .name = name,
                .defined_at = 0,
            };
        }
        try gop.value_ptr.references.append(std.heap.page_allocator, line);
    }

    pub fn setDefinition(self: *CrossReference, name: []const u8, line: u32) !void {
        const gop = try self.entries.getOrPut(name);
        gop.value_ptr.defined_at = line;
        if (!gop.found_existing) {
            gop.value_ptr.* = XrefEntry{
                .name = name,
                .defined_at = line,
            };
        } else {
            gop.value_ptr.defined_at = line;
        }
    }
};

test "listing state page break" {
    var ls = ListingState{};
    ls.setPageSize(60, 132);
    try std.testing.expectEqual(@as(u8, 60), ls.page_length);
}

test "listing macro mode" {
    var ls = ListingState{};
    ls.setListMacro(.listmacroall);
    try std.testing.expectEqual(@as(jwasm.listmacro, .listmacroall), ls.list_macro);
}

test "cross reference tracking" {
    var xref = CrossReference.init(std.testing.allocator);
    defer xref.deinit();

    try xref.setDefinition("main", 10);
    try xref.addReference("main", 20);
    try xref.addReference("main", 30);

    const entry = xref.entries.get("main").?;
    try std.testing.expectEqual(@as(u32, 10), entry.defined_at);
    try std.testing.expectEqual(@as(usize, 2), entry.references.items.len);
}

test "listing if flag" {
    var ls = ListingState{};
    ls.setListIf(true);
    try std.testing.expect(ls.listif);
    ls.setListIf(false);
    try std.testing.expect(!ls.listif);
}

test "cref toggle" {
    var ls = ListingState{};
    try std.testing.expect(ls.cref_active);
    ls.toggleCrefl();
    try std.testing.expect(!ls.cref_active);
}
