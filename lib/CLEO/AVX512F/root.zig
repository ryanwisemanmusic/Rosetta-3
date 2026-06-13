pub const ADDPD = @import("ADDPD.zig");
pub const CMPPD = @import("CMPPD.zig");
pub const CMPPS = @import("CMPPS.zig");
pub const DIVPD = @import("DIVPD.zig");
pub const DIVPS = @import("DIVPS.zig");
pub const MULPD = @import("MULPD.zig");
pub const MULPS = @import("MULPS.zig");
pub const PMAXSD = @import("PMAXSD.zig");
pub const PMAXSQ = @import("PMAXSQ.zig");
pub const PMAXUD = @import("PMAXUD.zig");
pub const PMAXUQ = @import("PMAXUQ.zig");
pub const PMINSD = @import("PMINSD.zig");
pub const PMINSQ = @import("PMINSQ.zig");
pub const PMINUD = @import("PMINUD.zig");
pub const PMINUQ = @import("PMINUQ.zig");
pub const SHUFPD = @import("SHUFPD.zig");
pub const SHUFPS = @import("SHUFPS.zig");
pub const VMOVDQA32 = @import("VMOVDQA32.zig");
pub const VMOVDQA64 = @import("VMOVDQA64.zig");
pub const VMOVDQU32 = @import("VMOVDQU32.zig");
pub const VMOVDQU64 = @import("VMOVDQU64.zig");
pub const SUBPD = @import("SUBPD.zig");
pub const SUBPS = @import("SUBPS.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    ADDPD.meta,
    CMPPD.meta,
    CMPPS.meta,
    DIVPD.meta,
    DIVPS.meta,
    MULPD.meta,
    MULPS.meta,
    PMAXSD.meta,
    PMAXSQ.meta,
    PMAXUD.meta,
    PMAXUQ.meta,
    PMINSD.meta,
    PMINSQ.meta,
    PMINUD.meta,
    PMINUQ.meta,
    SHUFPD.meta,
    SHUFPS.meta,
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
