const common = @import("entrypoint_data_init_common");
const builtin = @import("builtin");
const neon = @import("entrypoint_data_init_neon");

pub const SectionCopy = common.SectionCopy;

pub fn apply(memory: []u8, sections: []const SectionCopy) void {
    if (builtin.cpu.arch == .aarch64) {
        neon.apply(memory, sections);
        return;
    }
    common.applyDataSections("entrypoint-x86-data", memory, sections);
}
