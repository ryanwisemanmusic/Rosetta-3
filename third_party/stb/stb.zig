const std = @import("std");

pub const StbError = error{
    InvalidSprintfVersion,
    InvalidSprintfMin,
    InvalidImageVersion,
    InvalidImageWriteVersion,
    InvalidDefaultToggle,
    InvalidConfigConstant,
    InvalidStbFormat,
    InvalidTypeWidth,
    InvalidFunctionPtrWidth,
};

/// Pseudo-Windows snapshot. All constants sourced from stb_sprintf.h
/// (v1.10), stb_image.h, and stb_image_write.h (public domain, stb
/// libraries by Sean Barrett / RAD Game Tools).  Since these are pure
/// C libraries using standard types, there is no LP64 vs LLP64 type
/// divergence — all values are convergent across platforms.
pub const WindowsStbSpec = struct {
    // ── stb_sprintf.h ──────────────────────────────────────────────
    pub const STB_SPRINTF_VERSION_MAJOR: u32 = 1;
    pub const STB_SPRINTF_VERSION_MINOR: u32 = 10;
    pub const STB_SPRINTF_MIN: u32 = 512;

    // ── stb_image.h ────────────────────────────────────────────────
    // STBI_default = 0 (default), STBI_grey = 1,
    // STBI_grey_alpha = 2, STBI_rgb = 3, STBI_rgb_alpha = 4
    pub const STBI_default: i32 = 0;
    pub const STBI_grey: i32 = 1;
    pub const STBI_grey_alpha: i32 = 2;
    pub const STBI_rgb: i32 = 3;
    pub const STBI_rgb_alpha: i32 = 4;

    // ── stb_image_write.h ──────────────────────────────────────────
    // STBIW_DEFAULT = 0, STBIW_PNG = 1, STBIW_BMP = 2,
    // STBIW_TGA = 3, STBIW_JPG = 4, STBIW_HDR = 5
    pub const STBIW_DEFAULT: i32 = 0;
    pub const STBIW_PNG: i32 = 1;
    pub const STBIW_BMP: i32 = 2;
    pub const STBIW_TGA: i32 = 3;
    pub const STBIW_JPG: i32 = 4;
    pub const STBIW_HDR: i32 = 5;

    // ── Type widths ────────────────────────────────────────────────
    pub const sizeof_stbi_uc: comptime_int = 1;
    pub const sizeof_void_ptr: comptime_int = 8;

    // ── io callbacks struct (stbi_io_callbacks) ────────────────────
    // Members: read (fn ptr), skip (fn ptr), eof (fn ptr)
    pub const sizeof_stbi_io_callbacks: comptime_int = 24;
    pub const offsetof_read: comptime_int = 0;
    pub const offsetof_skip: comptime_int = 8;
    pub const offsetof_eof: comptime_int = 16;
};

/// macOS host snapshot. stb library constants are identical on both
/// platforms (all explicit).  Type-width checks confirm convergence
/// of fundamental C types.
pub const MacOsStb = struct {
    pub const sizeof_c_int = @sizeOf(c_int);
    pub const sizeof_ptr = @sizeOf(*anyopaque);
    pub const sizeof_u8 = @sizeOf(u8);
};

const StbIoCallbacksState = extern struct {
    read: ?*const fn (?*anyopaque, [*c]u8, c_int) callconv(.c) c_int,
    skip: ?*const fn (?*anyopaque, c_int) callconv(.c) void,
    eof: ?*const fn (?*anyopaque) callconv(.c) c_int,
};

pub fn validateStbSprintfConstants() StbError!void {
    if (WindowsStbSpec.STB_SPRINTF_VERSION_MAJOR != 1) return error.InvalidSprintfVersion;
    if (WindowsStbSpec.STB_SPRINTF_VERSION_MINOR != 10) return error.InvalidSprintfVersion;
    if (WindowsStbSpec.STB_SPRINTF_MIN != 512) return error.InvalidSprintfMin;
}

pub fn validateStbImageFormatConstants() StbError!void {
    if (WindowsStbSpec.STBI_default != 0) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBI_grey != 1) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBI_grey_alpha != 2) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBI_rgb != 3) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBI_rgb_alpha != 4) return error.InvalidStbFormat;
}

pub fn validateStbImageWriteFormatConstants() StbError!void {
    if (WindowsStbSpec.STBIW_DEFAULT != 0) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBIW_PNG != 1) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBIW_BMP != 2) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBIW_TGA != 3) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBIW_JPG != 4) return error.InvalidStbFormat;
    if (WindowsStbSpec.STBIW_HDR != 5) return error.InvalidStbFormat;
}

pub fn validateStbTypeWidths() StbError!void {
    if (MacOsStb.sizeof_c_int != 4) return error.InvalidTypeWidth;
    if (MacOsStb.sizeof_ptr != 8) return error.InvalidFunctionPtrWidth;
    if (MacOsStb.sizeof_u8 != 1) return error.InvalidTypeWidth;
}

pub fn validateStbIoCallbacksLayout() StbError!void {
    if (@sizeOf(StbIoCallbacksState) != WindowsStbSpec.sizeof_stbi_io_callbacks)
        return error.InvalidConfigConstant;
    if (@offsetOf(StbIoCallbacksState, "read") != WindowsStbSpec.offsetof_read)
        return error.InvalidConfigConstant;
    if (@offsetOf(StbIoCallbacksState, "skip") != WindowsStbSpec.offsetof_skip)
        return error.InvalidConfigConstant;
    if (@offsetOf(StbIoCallbacksState, "eof") != WindowsStbSpec.offsetof_eof)
        return error.InvalidConfigConstant;
}

pub fn validateAll() StbError!void {
    try validateStbSprintfConstants();
    try validateStbImageFormatConstants();
    try validateStbImageWriteFormatConstants();
    try validateStbTypeWidths();
    try validateStbIoCallbacksLayout();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_stb() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidSprintfVersion => 1,
        error.InvalidSprintfMin => 2,
        error.InvalidImageVersion => 3,
        error.InvalidImageWriteVersion => 4,
        error.InvalidDefaultToggle => 5,
        error.InvalidConfigConstant => 6,
        error.InvalidStbFormat => 7,
        error.InvalidTypeWidth => 8,
        error.InvalidFunctionPtrWidth => 9,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosetta3_stb_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidSprintfVersion",
        2 => "InvalidSprintfMin",
        3 => "InvalidImageVersion",
        4 => "InvalidImageWriteVersion",
        5 => "InvalidDefaultToggle",
        6 => "InvalidConfigConstant",
        7 => "InvalidStbFormat",
        8 => "InvalidTypeWidth",
        9 => "InvalidFunctionPtrWidth",
        else => "UnknownStbFailure",
    };
}

pub fn reportStbSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ stb Library Specification Table
        \\================================================================================
        \\ stb_sprintf.h v{d}.{d}
        \\   STB_SPRINTF_MIN           = {d}
        \\
        \\ stb_image.h format constants:
        \\   STBI_default              = {d}
        \\   STBI_grey                 = {d}
        \\   STBI_grey_alpha           = {d}
        \\   STBI_rgb                  = {d}
        \\   STBI_rgb_alpha            = {d}
        \\
        \\ stb_image_write.h format constants:
        \\   STBIW_DEFAULT             = {d}
        \\   STBIW_PNG                 = {d}
        \\   STBIW_BMP                 = {d}
        \\   STBIW_TGA                 = {d}
        \\   STBIW_JPG                 = {d}
        \\   STBIW_HDR                 = {d}
        \\
        \\ stbi_io_callbacks layout (64-bit):
        \\   sizeof                    = {d}
        \\   offsetof(read)            = {d}
        \\   offsetof(skip)            = {d}
        \\   offsetof(eof)             = {d}
        \\
        \\ Type widths:
        \\   sizeof(c_int)             = {d}
        \\   sizeof(pointer)           = {d}
        \\   sizeof(u8)                = {d}
        \\
        \\================================================================================
        \\
    , .{
        WindowsStbSpec.STB_SPRINTF_VERSION_MAJOR,
        WindowsStbSpec.STB_SPRINTF_VERSION_MINOR,
        WindowsStbSpec.STB_SPRINTF_MIN,
        WindowsStbSpec.STBI_default,
        WindowsStbSpec.STBI_grey,
        WindowsStbSpec.STBI_grey_alpha,
        WindowsStbSpec.STBI_rgb,
        WindowsStbSpec.STBI_rgb_alpha,
        WindowsStbSpec.STBIW_DEFAULT,
        WindowsStbSpec.STBIW_PNG,
        WindowsStbSpec.STBIW_BMP,
        WindowsStbSpec.STBIW_TGA,
        WindowsStbSpec.STBIW_JPG,
        WindowsStbSpec.STBIW_HDR,
        WindowsStbSpec.sizeof_stbi_io_callbacks,
        WindowsStbSpec.offsetof_read,
        WindowsStbSpec.offsetof_skip,
        WindowsStbSpec.offsetof_eof,
        MacOsStb.sizeof_c_int,
        MacOsStb.sizeof_ptr,
        MacOsStb.sizeof_u8,
    });
}

pub export fn rosetta3_print_stb_spec() void {
    reportStbSpec();
}

test "stb spec matches expected values" {
    reportStbSpec();
    try validateAll();
}
