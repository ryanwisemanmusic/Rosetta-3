const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const SectionZero = struct {
    offset: u32,
    size: u32,
    label: []const u8 = "bss",
};

pub fn applyBssSections(comptime domain: []const u8, memory: []u8, sections: []const SectionZero) void {
    for (sections) |section| {
        const start: usize = @intCast(section.offset);
        const size: usize = @intCast(section.size);
        const end = start + size;
        if (end > memory.len) {
            runtime_abi.common.violation(
                domain,
                "bss_bounds",
                "{s}: offset=0x{x} size={d} memory={d}",
                .{ section.label, section.offset, section.size, memory.len },
            );
        }
        @memset(memory[start..end], 0);
    }
}

test "zeros bss sections" {
    var memory = [_]u8{0xFF} ** 16;
    const sections = [_]SectionZero{
        .{ .offset = 2, .size = 6, .label = "state" },
    };
    applyBssSections("test-bss", &memory, &sections);
    try std.testing.expectEqual(@as(u8, 0), memory[2]);
    try std.testing.expectEqual(@as(u8, 0), memory[7]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[1]);
}
