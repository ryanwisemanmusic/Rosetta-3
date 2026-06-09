pub const ADDPD = @import("ADDPD.zig");
pub const DIVPD = @import("DIVPD.zig");
pub const DIVPS = @import("DIVPS.zig");
pub const MULPD = @import("MULPD.zig");
pub const MULPS = @import("MULPS.zig");
pub const VMOVDQA32 = @import("VMOVDQA32.zig");
pub const VMOVDQA64 = @import("VMOVDQA64.zig");
pub const VMOVDQU32 = @import("VMOVDQU32.zig");
pub const VMOVDQU64 = @import("VMOVDQU64.zig");
pub const SUBPD = @import("SUBPD.zig");
pub const SUBPS = @import("SUBPS.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    ADDPD.meta,
    DIVPD.meta,
    DIVPS.meta,
    MULPD.meta,
    MULPS.meta,
    VMOVDQA32.meta,
    VMOVDQA64.meta,
    VMOVDQU32.meta,
    VMOVDQU64.meta,
    SUBPD.meta,
    SUBPS.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
