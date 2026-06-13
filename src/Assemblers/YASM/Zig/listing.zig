const std = @import("std");

const Allocator = std.mem.Allocator;

pub const ListingLine = struct {
    line_number: u32,
    offset: u64,
    text: []const u8,
    byte_count: u32 = 0,
};

pub const ListingState = struct {
    allocator: Allocator,
    lines: std.ArrayListUnmanaged(ListingLine) = .{ .items = &.{}, .capacity = 0 },
    enabled: bool = false,
    path: []const u8 = "",

    pub fn init(allocator: Allocator) ListingState {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *ListingState) void {
        for (self.lines.items) |line| self.allocator.free(line.text);
        self.lines.deinit(self.allocator);
    }

    pub fn enable(self: *ListingState, path: []const u8) void {
        self.enabled = true;
        self.path = path;
    }

    pub fn addLine(self: *ListingState, line_number: u32, offset: u64, byte_count: u32, text: []const u8) !void {
        if (!self.enabled) return;
        try self.lines.append(self.allocator, .{
            .line_number = line_number,
            .offset = offset,
            .byte_count = byte_count,
            .text = try self.allocator.dupe(u8, text),
        });
    }
};

test "listing only records when enabled" {
    var state = ListingState.init(std.testing.allocator);
    defer state.deinit();
    try state.addLine(1, 0, 1, "nop");
    try std.testing.expectEqual(@as(usize, 0), state.lines.items.len);
    state.enable("out.lst");
    try state.addLine(1, 0, 1, "nop");
    try std.testing.expectEqual(@as(usize, 1), state.lines.items.len);
}
