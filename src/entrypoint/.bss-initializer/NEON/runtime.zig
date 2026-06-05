const common = @import("entrypoint_bss_init_common");

pub const SectionZero = common.SectionZero;

pub fn apply(memory: []u8, sections: []const SectionZero) void {
    const zero16: @Vector(16, u8) = @splat(0);
    const zero_block: [16]u8 = @bitCast(zero16);
    for (sections) |section| {
        const start: usize = @intCast(section.offset);
        const size: usize = @intCast(section.size);
        const end = start + size;
        if (end > memory.len) {
            common.applyBssSections("entrypoint-neon-bss", memory, sections);
            return;
        }

        var i: usize = 0;
        while (i + 16 <= size) : (i += 16) {
            @memcpy(memory[start + i .. start + i + 16], &zero_block);
        }
        while (i < size) : (i += 1) {
            memory[start + i] = 0;
        }
    }
}
