const common = @import("entrypoint_data_init_common");

pub const SectionCopy = common.SectionCopy;

pub fn apply(memory: []u8, sections: []const SectionCopy) void {
    for (sections) |section| {
        const start: usize = @intCast(section.offset);
        const end = start + section.bytes.len;
        if (end > memory.len) {
            common.applyDataSections("entrypoint-neon-data", memory, sections);
            return;
        }

        var i: usize = 0;
        while (i + 16 <= section.bytes.len) : (i += 16) {
            const vec: @Vector(16, u8) = section.bytes[i..][0..16].*;
            const block: [16]u8 = @bitCast(vec);
            @memcpy(memory[start + i .. start + i + 16], &block);
        }
        while (i < section.bytes.len) : (i += 1) {
            memory[start + i] = section.bytes[i];
        }
    }
}
