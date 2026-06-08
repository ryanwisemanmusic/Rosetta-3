pub const VMOVDQU8 = @import("VMOVDQU8.zig");
pub const VMOVDQU16 = @import("VMOVDQU16.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    VMOVDQU8.meta,
    VMOVDQU16.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
