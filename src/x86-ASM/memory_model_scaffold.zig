const std = @import("std");

pub const CpuMemoryMode = enum {
    protected_mode,
    long_mode_flat,
};

pub const SegmentationModel = struct {
    enabled: bool,
    fs_base_later: bool = false,
    gs_base_later: bool = false,
    legacy_selectors_visible: bool = true,
};

pub const PagingModel = struct {
    enabled: bool,
    pae_like: bool = false,
    nx_later: bool = false,
};

pub const MemoryModel = struct {
    mode: CpuMemoryMode,
    segmentation: SegmentationModel,
    paging: PagingModel,
};

pub fn ia32ProtectedDefaults() MemoryModel {
    return .{
        .mode = .protected_mode,
        .segmentation = .{ .enabled = true },
        .paging = .{ .enabled = false },
    };
}

pub fn x64LongModeDefaults() MemoryModel {
    return .{
        .mode = .long_mode_flat,
        .segmentation = .{ .enabled = false, .fs_base_later = true, .gs_base_later = true },
        .paging = .{ .enabled = true, .pae_like = true, .nx_later = true },
    };
}

test "memory model defaults separate protected and long mode assumptions" {
    try std.testing.expect(ia32ProtectedDefaults().segmentation.enabled);
    try std.testing.expect(x64LongModeDefaults().paging.enabled);
}
