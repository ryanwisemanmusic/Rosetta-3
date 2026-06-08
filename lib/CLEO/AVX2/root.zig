pub const MOVDQA = @import("MOVDQA.zig");
pub const MOVDQU = @import("MOVDQU.zig");
pub const MOVNTDQ = @import("MOVNTDQ.zig");
pub const MOVNTDQA = @import("MOVNTDQA.zig");
pub const VMOVDQA = @import("VMOVDQA.zig");
pub const VMOVDQU = @import("VMOVDQU.zig");
pub const VMOVNTDQ = @import("VMOVNTDQ.zig");
pub const VMOVNTDQA = @import("VMOVNTDQA.zig");

const types = @import("../types.zig");

pub const metas = [_]types.InstructionMeta{
    MOVDQA.meta,
    MOVDQU.meta,
    MOVNTDQ.meta,
    MOVNTDQA.meta,
    VMOVDQA.meta,
    VMOVDQU.meta,
    VMOVNTDQ.meta,
    VMOVNTDQA.meta,
};

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}
