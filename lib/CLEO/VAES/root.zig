pub const AESDEC = @import("AESDEC.zig");
pub const AESDECLAST = @import("AESDECLAST.zig");
pub const AESENC = @import("AESENC.zig");
pub const AESENCLAST = @import("AESENCLAST.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    AESDEC.meta,
    AESDECLAST.meta,
    AESENC.meta,
    AESENCLAST.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
