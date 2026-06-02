const std = @import("std");
const cpu_mod = @import("cpu_state.zig");

pub const RealModeMemory = struct {
    allocator: std.mem.Allocator,
    bytes: []u8,

    pub fn init(allocator: std.mem.Allocator, size: usize) !RealModeMemory {
        const bytes = try allocator.alloc(u8, size);
        @memset(bytes, 0);
        return .{
            .allocator = allocator,
            .bytes = bytes,
        };
    }

    pub fn initDefault(allocator: std.mem.Allocator) !RealModeMemory {
        return init(allocator, 1024 * 1024);
    }

    pub fn deinit(self: *RealModeMemory) void {
        self.allocator.free(self.bytes);
    }

    pub fn physicalAddress(self: RealModeMemory, segment: u16, offset: u16) !usize {
        const linear = cpu_mod.CpuState.linearAddress(.{}, segment, offset);
        if (linear >= self.bytes.len) return error.AddressOutOfRange;
        return @intCast(linear);
    }

    pub fn read8(self: RealModeMemory, segment: u16, offset: u16) !u8 {
        return self.bytes[try self.physicalAddress(segment, offset)];
    }

    pub fn write8(self: *RealModeMemory, segment: u16, offset: u16, value: u8) !void {
        self.bytes[try self.physicalAddress(segment, offset)] = value;
    }

    pub fn read16(self: RealModeMemory, segment: u16, offset: u16) !u16 {
        const lo = try self.read8(segment, offset);
        const hi = try self.read8(segment, offset +% 1);
        return lo | (@as(u16, hi) << 8);
    }

    pub fn write16(self: *RealModeMemory, segment: u16, offset: u16, value: u16) !void {
        try self.write8(segment, offset, @truncate(value));
        try self.write8(segment, offset +% 1, @truncate(value >> 8));
    }

    pub fn sliceZ(self: RealModeMemory, segment: u16, offset: u16, terminator: u8) ![]const u8 {
        const start = try self.physicalAddress(segment, offset);
        var end = start;
        while (end < self.bytes.len and self.bytes[end] != terminator) : (end += 1) {}
        return self.bytes[start..end];
    }

    pub fn writeBytes(self: *RealModeMemory, segment: u16, offset: u16, data: []const u8) !void {
        const start = try self.physicalAddress(segment, offset);
        if (start + data.len > self.bytes.len) return error.AddressOutOfRange;
        @memcpy(self.bytes[start .. start + data.len], data);
    }

    pub fn fill(self: *RealModeMemory, segment: u16, offset: u16, count: usize, value: u8) !void {
        const start = try self.physicalAddress(segment, offset);
        if (start + count > self.bytes.len) return error.AddressOutOfRange;
        @memset(self.bytes[start .. start + count], value);
    }
};

test "real mode memory reads and writes words" {
    var mem = try RealModeMemory.initDefault(std.testing.allocator);
    defer mem.deinit();

    try mem.write16(0x1234, 0x0010, 0xBEEF);
    try std.testing.expectEqual(@as(u16, 0xBEEF), try mem.read16(0x1234, 0x0010));
}
