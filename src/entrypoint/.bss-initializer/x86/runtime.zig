const common = @import("entrypoint_bss_init_common");
const builtin = @import("builtin");
const neon = @import("entrypoint_bss_init_neon");

pub const SectionZero = common.SectionZero;

pub fn apply(memory: []u8, sections: []const SectionZero) void {
    if (builtin.cpu.arch == .aarch64) {
        neon.apply(memory, sections);
        return;
    }
    common.applyBssSections("entrypoint-x86-bss", memory, sections);
}
