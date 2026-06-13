pub const PMAXSB = @import("PMAXSB.zig");
pub const PMAXSW = @import("PMAXSW.zig");
pub const PMAXUB = @import("PMAXUB.zig");
pub const PMAXUW = @import("PMAXUW.zig");
pub const PMINSB = @import("PMINSB.zig");
pub const PMINSW = @import("PMINSW.zig");
pub const PMINUB = @import("PMINUB.zig");
pub const PMINUW = @import("PMINUW.zig");
pub const VMOVDQU8 = @import("VMOVDQU8.zig");
pub const VMOVDQU16 = @import("VMOVDQU16.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    PMAXSB.meta,
    PMAXSW.meta,
    PMAXUB.meta,
    PMAXUW.meta,
    PMINSB.meta,
    PMINSW.meta,
    PMINUB.meta,
    PMINUW.meta,
    VMOVDQU8.meta,
    VMOVDQU16.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
