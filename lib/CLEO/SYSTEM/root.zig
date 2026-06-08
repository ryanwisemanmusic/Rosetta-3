pub const LDTILECFG = @import("LDTILECFG.zig");
pub const LOADIWKEY = @import("LOADIWKEY.zig");
pub const MOVDIR64B = @import("MOVDIR64B.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    LDTILECFG.meta,
    LOADIWKEY.meta,
    MOVDIR64B.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
