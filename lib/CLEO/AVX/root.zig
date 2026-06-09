pub const ADDPS = @import("ADDPS.zig");
pub const ADDSUBPD = @import("ADDSUBPD.zig");
pub const ADDSUBPS = @import("ADDSUBPS.zig");
pub const DIVPD = @import("DIVPD.zig");
pub const DIVPS = @import("DIVPS.zig");
pub const LDDQU = @import("LDDQU.zig");
pub const MOVAPD = @import("MOVAPD.zig");
pub const MOVAPS = @import("MOVAPS.zig");
pub const MOVDDUP = @import("MOVDDUP.zig");
pub const MOVMSKPD = @import("MOVMSKPD.zig");
pub const MOVMSKPS = @import("MOVMSKPS.zig");
pub const MULPD = @import("MULPD.zig");
pub const MULPS = @import("MULPS.zig");
pub const MOVNTPD = @import("MOVNTPD.zig");
pub const MOVNTPS = @import("MOVNTPS.zig");
pub const MOVSHDUP = @import("MOVSHDUP.zig");
pub const MOVSLDUP = @import("MOVSLDUP.zig");
pub const MOVUPD = @import("MOVUPD.zig");
pub const MOVUPS = @import("MOVUPS.zig");
pub const VMOVAPD = @import("VMOVAPD.zig");
pub const VMOVAPS = @import("VMOVAPS.zig");
pub const VMOVDDUP = @import("VMOVDDUP.zig");
pub const VMOVMSKPD = @import("VMOVMSKPD.zig");
pub const VMOVMSKPS = @import("VMOVMSKPS.zig");
pub const VMOVNTPD = @import("VMOVNTPD.zig");
pub const VMOVNTPS = @import("VMOVNTPS.zig");
pub const VMOVSHDUP = @import("VMOVSHDUP.zig");
pub const VMOVSLDUP = @import("VMOVSLDUP.zig");
pub const VMOVUPD = @import("VMOVUPD.zig");
pub const VMOVUPS = @import("VMOVUPS.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    ADDPS.meta,
    ADDSUBPD.meta,
    ADDSUBPS.meta,
    DIVPD.meta,
    DIVPS.meta,
    LDDQU.meta,
    MOVAPD.meta,
    MOVAPS.meta,
    MOVDDUP.meta,
    MOVMSKPD.meta,
    MOVMSKPS.meta,
    MULPD.meta,
    MULPS.meta,
    MOVNTPD.meta,
    MOVNTPS.meta,
    MOVSHDUP.meta,
    MOVSLDUP.meta,
    MOVUPD.meta,
    MOVUPS.meta,
    VMOVAPD.meta,
    VMOVAPS.meta,
    VMOVDDUP.meta,
    VMOVMSKPD.meta,
    VMOVMSKPS.meta,
    VMOVNTPD.meta,
    VMOVNTPS.meta,
    VMOVSHDUP.meta,
    VMOVSLDUP.meta,
    VMOVUPD.meta,
    VMOVUPS.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
