pub const VDPBF16PS = @import("VDPBF16PS.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    VDPBF16PS.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
