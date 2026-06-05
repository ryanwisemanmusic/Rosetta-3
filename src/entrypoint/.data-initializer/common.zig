const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const SectionCopy = struct {
    offset: u32,
    bytes: []const u8,
    label: []const u8 = "data",
};

pub fn applyDataSections(comptime domain: []const u8, memory: []u8, sections: []const SectionCopy) void {
    for (sections) |section| {
        const start: usize = @intCast(section.offset);
        const end = start + section.bytes.len;
        if (end > memory.len) {
            runtime_abi.common.violation(
                domain,
                "data_bounds",
                "{s}: offset=0x{x} len={d} memory={d}",
                .{ section.label, section.offset, section.bytes.len, memory.len },
            );
        }
        @memcpy(memory[start..end], section.bytes);
    }
}

test "applies data sections" {
    var memory = [_]u8{0} ** 16;
    const sections = [_]SectionCopy{
        .{ .offset = 4, .bytes = "TEST", .label = "label" },
    };
    applyDataSections("test-data", &memory, &sections);
    try std.testing.expectEqualSlices(u8, "TEST", memory[4..8]);
}
