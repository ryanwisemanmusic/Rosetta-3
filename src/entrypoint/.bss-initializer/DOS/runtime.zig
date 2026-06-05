const common = @import("entrypoint_bss_init_common");

pub const SectionZero = common.SectionZero;

pub fn apply(memory: []u8, sections: []const SectionZero) void {
    common.applyBssSections("entrypoint-dos-bss", memory, sections);
}
