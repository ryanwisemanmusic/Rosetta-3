const std = @import("std");
const nasm = @import("nasm_core.zig");

const Allocator = std.mem.Allocator;

pub const Section = struct {
    name: []const u8,
    seg_align: u32 = 0,
    use32: bool = false,
    address: u64 = 0,
    size: u64 = 0,
    data: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },
    flags: u32 = 0,
    index: u32 = 0,

    pub fn deinit(self: *Section, allocator: Allocator) void {
        allocator.free(self.name);
        self.data.deinit(allocator);
    }
};

pub const SegmentState = struct {
    bits: nasm.bits_mode = .bits_16,
    current_section: ?u32 = null,
    origin: u64 = 0,
    initialized: bool = false,
};

pub const SegmentManager = struct {
    allocator: Allocator,
    sections: std.ArrayListUnmanaged(Section) = .{ .items = &.{}, .capacity = 0 },
    state: SegmentState = .{},
    org_value: u64 = 0,
    bits_value: u8 = 16,

    pub fn init(allocator: Allocator) SegmentManager {
        return SegmentManager{ .allocator = allocator };
    }

    pub fn deinit(self: *SegmentManager) void {
        for (self.sections.items) |*sec| sec.deinit(self.allocator);
        self.sections.deinit(self.allocator);
    }

    pub fn addSection(self: *SegmentManager, name: []const u8, align_val: u32, use32: bool) !u32 {
        for (self.sections.items, 0..) |sec, i| {
            if (std.ascii.eqlIgnoreCase(sec.name, name)) return @as(u32, @intCast(i));
        }
        const idx = @as(u32, @intCast(self.sections.items.len));
        try self.sections.append(self.allocator, Section{
            .name = try self.allocator.dupe(u8, name),
            .seg_align = align_val,
            .use32 = use32,
            .index = idx,
        });
        return idx;
    }

    pub fn findSection(self: *const SegmentManager, name: []const u8) ?u32 {
        for (self.sections.items, 0..) |sec, i| {
            if (std.ascii.eqlIgnoreCase(sec.name, name)) return @as(u32, @intCast(i));
        }
        return null;
    }

    pub fn setBits(self: *SegmentManager, bits: u8) !void {
        if (bits != 16 and bits != 32 and bits != 64) return error.InvalidBits;
        self.bits_value = bits;
    }

    pub fn emit(self: *SegmentManager, bytes: []const u8) !void {
        const idx = self.state.current_section orelse {
            _ = try self.addSection(".text", 16, self.bits_value == 32);
            self.state.current_section = @as(u32, @intCast(self.sections.items.len - 1));
            return self.emit(bytes);
        };
        try self.sections.items[idx].data.appendSlice(self.allocator, bytes);
        self.sections.items[idx].address += bytes.len;
        self.sections.items[idx].size += bytes.len;
    }
};

test "section management" {
    var sm = SegmentManager.init(std.testing.allocator);
    defer sm.deinit();

    const idx = try sm.addSection(".text", 16, true);
    try std.testing.expectEqual(@as(u32, 0), idx);
    try std.testing.expect(sm.findSection(".text") != null);
}

test "section re-add returns same index" {
    var sm = SegmentManager.init(std.testing.allocator);
    defer sm.deinit();

    _ = try sm.addSection(".text", 16, true);
    const idx2 = try sm.addSection(".text", 16, true);
    try std.testing.expectEqual(@as(u32, 0), idx2);
}

test "bits mode switching" {
    var sm = SegmentManager.init(std.testing.allocator);
    defer sm.deinit();

    try sm.setBits(64);
    try std.testing.expectEqual(@as(u8, 64), sm.bits_value);
}
