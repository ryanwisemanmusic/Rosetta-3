const std = @import("std");
const reg_map = @import("register_mapping.zig");

pub const MemoryChange = struct {
    address: u64,
    before: []const u8,
    after: []const u8,
};

pub const CpuSnapshot32 = struct {
    regs: reg_map.RegisterFile = .{},
};

pub const ExpectedFlags = struct {
    cf: ?u1 = null,
    pf: ?u1 = null,
    af: ?u1 = null,
    zf: ?u1 = null,
    sf: ?u1 = null,
    of: ?u1 = null,
};

pub const InstructionCase32 = struct {
    name: []const u8,
    bytes: []const u8,
    before: CpuSnapshot32,
    after: CpuSnapshot32,
    memory_changes: []const MemoryChange,
    expected_flags: ExpectedFlags = .{},
};

pub fn minimalCase(name: []const u8, bytes: []const u8) InstructionCase32 {
    return .{
        .name = name,
        .bytes = bytes,
        .before = .{},
        .after = .{},
        .memory_changes = &[_]MemoryChange{},
    };
}

test "instruction harness keeps bytes and case name" {
    const case_ = minimalCase("add eax, 1", &[_]u8{ 0x83, 0xC0, 0x01 });
    try std.testing.expectEqualStrings("add eax, 1", case_.name);
    try std.testing.expectEqual(@as(usize, 3), case_.bytes.len);
}
