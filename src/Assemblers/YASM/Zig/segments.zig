const std = @import("std");
const yasm = @import("yasm_core.zig");

const Allocator = std.mem.Allocator;

pub const SectionFlags = packed struct(u8) {
    alloc: bool = false,
    write: bool = false,
    exec: bool = false,
    bss: bool = false,
    _reserved: u4 = 0,
};

pub const Section = struct {
    name: []const u8,
    align_value: u32 = 1,
    flags: SectionFlags = .{},
    bits: yasm.BitsMode = .bits_64,
    offset: u64 = 0,
    size: u64 = 0,
    data: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },

    pub fn deinit(self: *Section, allocator: Allocator) void {
        allocator.free(self.name);
        self.data.deinit(allocator);
    }
};

pub const SectionManager = struct {
    allocator: Allocator,
    sections: std.ArrayListUnmanaged(Section) = .{ .items = &.{}, .capacity = 0 },
    current_section: ?u32 = null,
    bits: yasm.BitsMode = .bits_64,

    pub fn init(allocator: Allocator) SectionManager {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *SectionManager) void {
        for (self.sections.items) |*section| section.deinit(self.allocator);
        self.sections.deinit(self.allocator);
    }

    pub fn setBits(self: *SectionManager, bits: yasm.BitsMode) void {
        self.bits = bits;
    }

    pub fn beginSection(self: *SectionManager, name: []const u8, flags: SectionFlags, align_value: u32) !u32 {
        if (self.findSection(name)) |idx| {
            self.current_section = idx;
            return idx;
        }
        const idx: u32 = @intCast(self.sections.items.len);
        try self.sections.append(self.allocator, .{
            .name = try self.allocator.dupe(u8, name),
            .align_value = align_value,
            .flags = flags,
            .bits = self.bits,
        });
        self.current_section = idx;
        return idx;
    }

    pub fn ensureText(self: *SectionManager) !u32 {
        return try self.beginSection(".text", sectionFlagsForName(".text"), 16);
    }

    pub fn findSection(self: *const SectionManager, name: []const u8) ?u32 {
        for (self.sections.items, 0..) |section, i| {
            if (std.ascii.eqlIgnoreCase(section.name, name)) return @intCast(i);
        }
        return null;
    }

    pub fn emit(self: *SectionManager, bytes: []const u8) !void {
        const idx = self.current_section orelse try self.ensureText();
        try self.sections.items[idx].data.appendSlice(self.allocator, bytes);
        self.sections.items[idx].offset += bytes.len;
        self.sections.items[idx].size += bytes.len;
    }
};

pub fn sectionFlagsForName(name: []const u8) SectionFlags {
    if (std.ascii.eqlIgnoreCase(name, ".text") or std.ascii.eqlIgnoreCase(name, "text")) {
        return .{ .alloc = true, .exec = true };
    }
    if (std.ascii.eqlIgnoreCase(name, ".data") or std.ascii.eqlIgnoreCase(name, "data")) {
        return .{ .alloc = true, .write = true };
    }
    if (std.ascii.eqlIgnoreCase(name, ".bss") or std.ascii.eqlIgnoreCase(name, "bss")) {
        return .{ .alloc = true, .write = true, .bss = true };
    }
    return .{ .alloc = true };
}

test "section creation and lookup" {
    var manager = SectionManager.init(std.testing.allocator);
    defer manager.deinit();

    const text = try manager.beginSection(".text", sectionFlagsForName(".text"), 16);
    const text_again = try manager.beginSection(".TEXT", sectionFlagsForName(".text"), 16);
    try std.testing.expectEqual(text, text_again);
    try std.testing.expect(manager.findSection(".text") != null);
}
