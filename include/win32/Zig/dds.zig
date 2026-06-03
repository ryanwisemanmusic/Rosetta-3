const std = @import("std");

const win32_all = @import("win32_pending");

pub const DdsAbiError = error{
    InvalidFourCcDds,
    InvalidDdpfFourCc,
    InvalidFmtDx10,
    InvalidFmtDxt1,
    InvalidFmtDxt3,
    InvalidFmtDxt5,
    InvalidDdsdCaps,
    InvalidDdsdHeight,
    InvalidDdsdWidth,
    InvalidDdsdPitch,
    InvalidDdsdPixelFormat,
    InvalidDdsdMipMapCount,
    InvalidDdsdLinearSize,
    InvalidDdsdDepth,
    InvalidDdscapsComplex,
    InvalidDdscapsMipMap,
    InvalidDdscapsTexture,
    InvalidBlockSizeDxt1,
    InvalidBlockSizeDxt3,
    InvalidBlockSizeDxt5,
    InvalidDdsPixelFormatSize,
    InvalidDdsHeaderSize,
    InvalidDdsHeaderDxt10Size,
    InvalidDxgiFormatUnknown,
    InvalidDxgiFormatR32G32B32A32Float,
    InvalidDxgiFormatR8G8B8A8Unorm,
    InvalidDxgiFormatBc1Unorm,
    InvalidDxgiFormatBc3Unorm,
    InvalidDxgiFormatBc7Unorm,
    InvalidDxgiFormatForceUint,
};

pub const WindowsDdsSpec = struct {
    pub const FOURCC_DDS: comptime_int = 0x20534444;
    pub const DDPF_FOURCC: comptime_int = 0x00000004;
    pub const FMT_DX10: comptime_int = 0x30315844;
    pub const FMT_DXT1: comptime_int = 0x31545844;
    pub const FMT_DXT3: comptime_int = 0x33545844;
    pub const FMT_DXT5: comptime_int = 0x35545844;

    pub const DDSD_CAPS: comptime_int = 0x00000001;
    pub const DDSD_HEIGHT: comptime_int = 0x00000002;
    pub const DDSD_WIDTH: comptime_int = 0x00000004;
    pub const DDSD_PITCH: comptime_int = 0x00000008;
    pub const DDSD_PIXELFORMAT: comptime_int = 0x00001000;
    pub const DDSD_MIPMAPCOUNT: comptime_int = 0x00020000;
    pub const DDSD_LINEARSIZE: comptime_int = 0x00080000;
    pub const DDSD_DEPTH: comptime_int = 0x00800000;

    pub const DDSCAPS_COMPLEX: comptime_int = 0x00000008;
    pub const DDSCAPS_MIPMAP: comptime_int = 0x04000000;
    pub const DDSCAPS_TEXTURE: comptime_int = 0x00001000;

    pub const BLOCKSIZE_DXT1: comptime_int = 0x8;
    pub const BLOCKSIZE_DXT3: comptime_int = 0x10;
    pub const BLOCKSIZE_DXT5: comptime_int = 0x10;

    pub const sizeof_DDS_PIXELFORMAT: comptime_int = 32;
    pub const sizeof_DDS_HEADER: comptime_int = 124;
    pub const sizeof_DDS_HEADER_DXT10: comptime_int = 20;

    pub const DXGI_FORMAT_UNKNOWN: comptime_int = 0;
    pub const DXGI_FORMAT_R32G32B32A32_FLOAT: comptime_int = 2;
    pub const DXGI_FORMAT_R8G8B8A8_UNORM: comptime_int = 28;
    pub const DXGI_FORMAT_BC1_UNORM: comptime_int = 71;
    pub const DXGI_FORMAT_BC3_UNORM: comptime_int = 78;
    pub const DXGI_FORMAT_BC7_UNORM: comptime_int = 98;
    pub const DXGI_FORMAT_FORCE_UINT: comptime_int = 0xffffffff;
};

pub fn validateDdsConstants() DdsAbiError!void {
    if (win32_all.FOURCC_DDS != WindowsDdsSpec.FOURCC_DDS)
        return error.InvalidFourCcDds;

    if (win32_all.DDPF_FOURCC != WindowsDdsSpec.DDPF_FOURCC)
        return error.InvalidDdpfFourCc;

    if (win32_all.FMT_DX10 != WindowsDdsSpec.FMT_DX10)
        return error.InvalidFmtDx10;
    if (win32_all.FMT_DXT1 != WindowsDdsSpec.FMT_DXT1)
        return error.InvalidFmtDxt1;
    if (win32_all.FMT_DXT3 != WindowsDdsSpec.FMT_DXT3)
        return error.InvalidFmtDxt3;
    if (win32_all.FMT_DXT5 != WindowsDdsSpec.FMT_DXT5)
        return error.InvalidFmtDxt5;

    if (win32_all.DDSD_CAPS != WindowsDdsSpec.DDSD_CAPS)
        return error.InvalidDdsdCaps;
    if (win32_all.DDSD_HEIGHT != WindowsDdsSpec.DDSD_HEIGHT)
        return error.InvalidDdsdHeight;
    if (win32_all.DDSD_WIDTH != WindowsDdsSpec.DDSD_WIDTH)
        return error.InvalidDdsdWidth;
    if (win32_all.DDSD_PITCH != WindowsDdsSpec.DDSD_PITCH)
        return error.InvalidDdsdPitch;
    if (win32_all.DDSD_PIXELFORMAT != WindowsDdsSpec.DDSD_PIXELFORMAT)
        return error.InvalidDdsdPixelFormat;
    if (win32_all.DDSD_MIPMAPCOUNT != WindowsDdsSpec.DDSD_MIPMAPCOUNT)
        return error.InvalidDdsdMipMapCount;
    if (win32_all.DDSD_LINEARSIZE != WindowsDdsSpec.DDSD_LINEARSIZE)
        return error.InvalidDdsdLinearSize;
    if (win32_all.DDSD_DEPTH != WindowsDdsSpec.DDSD_DEPTH)
        return error.InvalidDdsdDepth;

    if (win32_all.DDSCAPS_COMPLEX != WindowsDdsSpec.DDSCAPS_COMPLEX)
        return error.InvalidDdscapsComplex;
    if (win32_all.DDSCAPS_MIPMAP != WindowsDdsSpec.DDSCAPS_MIPMAP)
        return error.InvalidDdscapsMipMap;
    if (win32_all.DDSCAPS_TEXTURE != WindowsDdsSpec.DDSCAPS_TEXTURE)
        return error.InvalidDdscapsTexture;

    if (win32_all.BLOCKSIZE_DXT1 != WindowsDdsSpec.BLOCKSIZE_DXT1)
        return error.InvalidBlockSizeDxt1;
    if (win32_all.BLOCKSIZE_DXT3 != WindowsDdsSpec.BLOCKSIZE_DXT3)
        return error.InvalidBlockSizeDxt3;
    if (win32_all.BLOCKSIZE_DXT5 != WindowsDdsSpec.BLOCKSIZE_DXT5)
        return error.InvalidBlockSizeDxt5;

    if (win32_all.DXGI_FORMAT_UNKNOWN != WindowsDdsSpec.DXGI_FORMAT_UNKNOWN)
        return error.InvalidDxgiFormatUnknown;
    if (win32_all.DXGI_FORMAT_R32G32B32A32_FLOAT != WindowsDdsSpec.DXGI_FORMAT_R32G32B32A32_FLOAT)
        return error.InvalidDxgiFormatR32G32B32A32Float;
    if (win32_all.DXGI_FORMAT_R8G8B8A8_UNORM != WindowsDdsSpec.DXGI_FORMAT_R8G8B8A8_UNORM)
        return error.InvalidDxgiFormatR8G8B8A8Unorm;
    if (win32_all.DXGI_FORMAT_BC1_UNORM != WindowsDdsSpec.DXGI_FORMAT_BC1_UNORM)
        return error.InvalidDxgiFormatBc1Unorm;
    if (win32_all.DXGI_FORMAT_BC3_UNORM != WindowsDdsSpec.DXGI_FORMAT_BC3_UNORM)
        return error.InvalidDxgiFormatBc3Unorm;
    if (win32_all.DXGI_FORMAT_BC7_UNORM != WindowsDdsSpec.DXGI_FORMAT_BC7_UNORM)
        return error.InvalidDxgiFormatBc7Unorm;
    if (win32_all.DXGI_FORMAT_FORCE_UINT != WindowsDdsSpec.DXGI_FORMAT_FORCE_UINT)
        return error.InvalidDxgiFormatForceUint;
}

pub fn validateDdsStructSizes() DdsAbiError!void {
    if (@sizeOf(win32_all.DDS_PIXELFORMAT) != WindowsDdsSpec.sizeof_DDS_PIXELFORMAT)
        return error.InvalidDdsPixelFormatSize;
    if (@sizeOf(win32_all.DDS_HEADER) != WindowsDdsSpec.sizeof_DDS_HEADER)
        return error.InvalidDdsHeaderSize;
    if (@sizeOf(win32_all.DDS_HEADER_DXT10) != WindowsDdsSpec.sizeof_DDS_HEADER_DXT10)
        return error.InvalidDdsHeaderDxt10Size;
}

pub fn validateAll() DdsAbiError!void {
    try validateDdsConstants();
    try validateDdsStructSizes();
}

fn reportDdsSizes() void {
    std.debug.print(
        \\================================================================================
        \\ DDS Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "DDS_PIXELFORMAT", .spec = WindowsDdsSpec.sizeof_DDS_PIXELFORMAT, .zig = @sizeOf(win32_all.DDS_PIXELFORMAT) },
        .{ .name = "DDS_HEADER", .spec = WindowsDdsSpec.sizeof_DDS_HEADER, .zig = @sizeOf(win32_all.DDS_HEADER) },
        .{ .name = "DDS_HEADER_DXT10", .spec = WindowsDdsSpec.sizeof_DDS_HEADER_DXT10, .zig = @sizeOf(win32_all.DDS_HEADER_DXT10) },
    };
    inline for (table) |entry| {
        std.debug.print(
            \\ {s:<38} | {d:<10} | {d:<14}
            \\
        , .{ entry.name, entry.spec, entry.zig });
    }
    std.debug.print(
        \\================================================================================
        \\
    , .{});
}

pub export fn rosetta3_validate_dds() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidFourCcDds => 1,
        error.InvalidDdpfFourCc => 2,
        error.InvalidFmtDx10 => 3,
        error.InvalidFmtDxt1 => 4,
        error.InvalidFmtDxt3 => 5,
        error.InvalidFmtDxt5 => 6,
        error.InvalidDdsdCaps => 7,
        error.InvalidDdsdHeight => 8,
        error.InvalidDdsdWidth => 9,
        error.InvalidDdsdPitch => 10,
        error.InvalidDdsdPixelFormat => 11,
        error.InvalidDdsdMipMapCount => 12,
        error.InvalidDdsdLinearSize => 13,
        error.InvalidDdsdDepth => 14,
        error.InvalidDdscapsComplex => 15,
        error.InvalidDdscapsMipMap => 16,
        error.InvalidDdscapsTexture => 17,
        error.InvalidBlockSizeDxt1 => 18,
        error.InvalidBlockSizeDxt3 => 19,
        error.InvalidBlockSizeDxt5 => 20,
        error.InvalidDdsPixelFormatSize => 21,
        error.InvalidDdsHeaderSize => 22,
        error.InvalidDdsHeaderDxt10Size => 23,
        error.InvalidDxgiFormatUnknown => 24,
        error.InvalidDxgiFormatR32G32B32A32Float => 25,
        error.InvalidDxgiFormatR8G8B8A8Unorm => 26,
        error.InvalidDxgiFormatBc1Unorm => 27,
        error.InvalidDxgiFormatBc3Unorm => 28,
        error.InvalidDxgiFormatBc7Unorm => 29,
        error.InvalidDxgiFormatForceUint => 30,
    };
    return 0;
}

pub export fn rosetta3_dds_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidFourCcDds",
        2 => "InvalidDdpfFourCc",
        3 => "InvalidFmtDx10",
        4 => "InvalidFmtDxt1",
        5 => "InvalidFmtDxt3",
        6 => "InvalidFmtDxt5",
        7 => "InvalidDdsdCaps",
        8 => "InvalidDdsdHeight",
        9 => "InvalidDdsdWidth",
        10 => "InvalidDdsdPitch",
        11 => "InvalidDdsdPixelFormat",
        12 => "InvalidDdsdMipMapCount",
        13 => "InvalidDdsdLinearSize",
        14 => "InvalidDdsdDepth",
        15 => "InvalidDdscapsComplex",
        16 => "InvalidDdscapsMipMap",
        17 => "InvalidDdscapsTexture",
        18 => "InvalidBlockSizeDxt1",
        19 => "InvalidBlockSizeDxt3",
        20 => "InvalidBlockSizeDxt5",
        21 => "InvalidDdsPixelFormatSize",
        22 => "InvalidDdsHeaderSize",
        23 => "InvalidDdsHeaderDxt10Size",
        24 => "InvalidDxgiFormatUnknown",
        25 => "InvalidDxgiFormatR32G32B32A32Float",
        26 => "InvalidDxgiFormatR8G8B8A8Unorm",
        27 => "InvalidDxgiFormatBc1Unorm",
        28 => "InvalidDxgiFormatBc3Unorm",
        29 => "InvalidDxgiFormatBc7Unorm",
        30 => "InvalidDxgiFormatForceUint",
        else => "UnknownDdsFailure",
    };
}

pub export fn rosetta3_print_dds_report() void {
    reportDdsSizes();
}

test "dds.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
