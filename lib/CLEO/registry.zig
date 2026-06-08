const std = @import("std");
const types = @import("types.zig");
pub const AVX = @import("AVX/root.zig");
pub const AVX2 = @import("AVX2/root.zig");
pub const AVX512F = @import("AVX512F/root.zig");
pub const AVX512DQ = @import("AVX512DQ/root.zig");
pub const AVX512BW = @import("AVX512BW/root.zig");
pub const SYSTEM = @import("SYSTEM/root.zig");

pub const metas = [_]types.InstructionMeta{
    AVX.ADDPS.meta,
    AVX.ADDSUBPD.meta,
    AVX.ADDSUBPS.meta,
    AVX.LDDQU.meta,
    AVX.MOVAPD.meta,
    AVX.MOVAPS.meta,
    AVX.MOVDDUP.meta,
    AVX.MOVMSKPD.meta,
    AVX.MOVMSKPS.meta,
    AVX.MOVNTPD.meta,
    AVX.MOVNTPS.meta,
    AVX.MOVSHDUP.meta,
    AVX.MOVSLDUP.meta,
    AVX.MOVUPD.meta,
    AVX.MOVUPS.meta,
    AVX.VMOVAPD.meta,
    AVX.VMOVAPS.meta,
    AVX.VMOVDDUP.meta,
    AVX.VMOVMSKPD.meta,
    AVX.VMOVMSKPS.meta,
    AVX.VMOVNTPD.meta,
    AVX.VMOVNTPS.meta,
    AVX.VMOVSHDUP.meta,
    AVX.VMOVSLDUP.meta,
    AVX.VMOVUPD.meta,
    AVX.VMOVUPS.meta,
    AVX2.MOVDQA.meta,
    AVX2.MOVDQU.meta,
    AVX2.MOVNTDQ.meta,
    AVX2.MOVNTDQA.meta,
    AVX2.VMOVDQA.meta,
    AVX2.VMOVDQU.meta,
    AVX2.VMOVNTDQ.meta,
    AVX2.VMOVNTDQA.meta,
    AVX512F.ADDPD.meta,
    AVX512F.VMOVDQA32.meta,
    AVX512F.VMOVDQA64.meta,
    AVX512F.VMOVDQU32.meta,
    AVX512F.VMOVDQU64.meta,
    AVX512F.SUBPD.meta,
    AVX512F.SUBPS.meta,
    AVX512DQ.ORPD.meta,
    AVX512DQ.ORPS.meta,
    AVX512DQ.XORPD.meta,
    AVX512DQ.XORPS.meta,
    AVX512BW.VMOVDQU8.meta,
    AVX512BW.VMOVDQU16.meta,
    SYSTEM.LDTILECFG.meta,
    SYSTEM.LOADIWKEY.meta,
    SYSTEM.MOVDIR64B.meta,
};

pub fn tableCount() usize {
    return metas.len;
}

pub fn findByName(name: []const u8) ?types.InstructionMeta {
    for (metas) |meta| if (std.ascii.eqlIgnoreCase(meta.name, name)) return meta;
    return null;
}

pub fn validateAll() types.SafetyError!void {
    for (metas) |meta| try types.validateMeta(meta);
}

pub fn completedCount(features: types.FeatureSet) usize {
    var count: usize = 0;
    for (metas) |meta| {
        if (types.safetyReport(meta, features).ok()) count += 1;
    }
    return count;
}

pub fn progressPermille(features: types.FeatureSet) u16 {
    if (metas.len == 0) return 0;
    return @intCast((completedCount(features) * 1000) / metas.len);
}

test "CLEO registry covers current wide ISA tables" {
    try std.testing.expectEqual(@as(usize, 50), tableCount());
    try validateAll();
    const features = types.FeatureSet.cleoEmulated();
    try std.testing.expectEqual(tableCount(), completedCount(features));
    try std.testing.expectEqual(@as(u16, 1000), progressPermille(features));
    try std.testing.expect(findByName("VADDPS") == null);
    try std.testing.expect(findByName("ADDPS") != null);
}
