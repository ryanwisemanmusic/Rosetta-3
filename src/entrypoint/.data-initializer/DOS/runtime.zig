const common = @import("entrypoint_data_init_common");

pub const SectionCopy = common.SectionCopy;

pub fn apply(memory: []u8, sections: []const SectionCopy) void {
    common.applyDataSections("entrypoint-dos-data", memory, sections);
}
