const std = @import("std");
const cpu_mod = @import("cpu_state.zig");
const runtime_abi = @import("runtime_abi_handshake");
const mem_trace = @import("../memory/runtime.zig");
const layout = @import("../memory/layout.zig");

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
        runtime_abi.dos.validateMemoryAccess(.read, self.bytes.len, segment, offset, 1);
        const phys = cpu_mod.CpuState.linearAddress(.{}, segment, offset);
        const wrapped = (@as(u32, segment) << 4) + @as(u32, offset) > 0xFFFFF;
        const meta = layout.classify(phys, 1, 0, wrapped);
        runtime_abi.dos.validateMemorySemantics(.read, phys, 1, meta.permissions, meta.aligned, meta.null_page, meta.stack_access, meta.wraparound, @tagName(meta.region));
        const value = self.bytes[try self.physicalAddress(segment, offset)];
        mem_trace.logRead("read8", segment, offset, 1, value, 0);
        return value;
    }

    pub fn write8(self: *RealModeMemory, segment: u16, offset: u16, value: u8) !void {
        runtime_abi.dos.validateMemoryAccess(.write, self.bytes.len, segment, offset, 1);
        const phys = cpu_mod.CpuState.linearAddress(.{}, segment, offset);
        const wrapped = (@as(u32, segment) << 4) + @as(u32, offset) > 0xFFFFF;
        const meta = layout.classify(phys, 1, 0, wrapped);
        runtime_abi.dos.validateMemorySemantics(.write, phys, 1, meta.permissions, meta.aligned, meta.null_page, meta.stack_access, meta.wraparound, @tagName(meta.region));
        self.bytes[try self.physicalAddress(segment, offset)] = value;
        mem_trace.logWrite("write8", segment, offset, 1, value, 0);
    }

    pub fn read16(self: RealModeMemory, segment: u16, offset: u16) !u16 {
        runtime_abi.dos.validateMemoryAccess(.read, self.bytes.len, segment, offset, 2);
        const phys = cpu_mod.CpuState.linearAddress(.{}, segment, offset);
        const wrapped = (@as(u32, segment) << 4) + @as(u32, offset) > 0xFFFFF;
        const meta = layout.classify(phys, 2, 0, wrapped);
        runtime_abi.dos.validateMemorySemantics(.read, phys, 2, meta.permissions, meta.aligned, meta.null_page, meta.stack_access, meta.wraparound, @tagName(meta.region));
        const start = try self.physicalAddress(segment, offset);
        const value = @as(u16, self.bytes[start]) | (@as(u16, self.bytes[start + 1]) << 8);
        mem_trace.logRead("read16", segment, offset, 2, value, 0);
        return value;
    }

    pub fn write16(self: *RealModeMemory, segment: u16, offset: u16, value: u16) !void {
        runtime_abi.dos.validateMemoryAccess(.write, self.bytes.len, segment, offset, 2);
        const phys = cpu_mod.CpuState.linearAddress(.{}, segment, offset);
        const wrapped = (@as(u32, segment) << 4) + @as(u32, offset) > 0xFFFFF;
        const meta = layout.classify(phys, 2, 0, wrapped);
        runtime_abi.dos.validateMemorySemantics(.write, phys, 2, meta.permissions, meta.aligned, meta.null_page, meta.stack_access, meta.wraparound, @tagName(meta.region));
        const start = try self.physicalAddress(segment, offset);
        self.bytes[start] = @truncate(value);
        self.bytes[start + 1] = @truncate(value >> 8);
        mem_trace.logWrite("write16", segment, offset, 2, value, 0);
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
