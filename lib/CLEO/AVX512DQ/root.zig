pub const ORPD = @import("ORPD.zig");
pub const ORPS = @import("ORPS.zig");
pub const XORPD = @import("XORPD.zig");
pub const XORPS = @import("XORPS.zig");
pub const ANDPS = @import("ANDPS.zig");
pub const ANDPD = @import("ANDPD.zig");
pub const ANDNPS = @import("ANDNPS.zig");
pub const ANDNPD = @import("ANDNPD.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    ORPD.meta,
    ORPS.meta,
    XORPD.meta,
    XORPS.meta,
    ANDPS.meta,
    ANDPD.meta,
    ANDNPS.meta,
    ANDNPD.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
