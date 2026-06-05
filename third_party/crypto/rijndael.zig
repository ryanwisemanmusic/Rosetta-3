const std = @import("std");

pub const RijndaelAbiError = error{
    InvalidMaxKeyColumnCount,
    InvalidMaxKeyByteCount,
    InvalidMaxRoundCount,
    InvalidTypeWidth,
};

/// Pseudo-Windows snapshot. Constants and type widths derived from
/// rijndael-alg-fst.h (LLP64 assumptions; values are convergent).
pub const WindowsRijndaelSpec = struct {
    pub const MAXKC: comptime_int = 256 / 32; // 8
    pub const MAXKB: comptime_int = 256 / 8; // 32
    pub const MAXNR: comptime_int = 14;

    pub const sizeof_u8: comptime_int = 1;
    pub const sizeof_u16: comptime_int = 2;
    pub const sizeof_u32: comptime_int = 4;
};

/// macOS host snapshot. These should match the Windows spec.
pub const MacOsRijndael = struct {
    pub const sizeof_u8 = @sizeOf(u8);
    pub const sizeof_u16 = @sizeOf(u16);
    pub const sizeof_u32 = @sizeOf(u32);
};

pub fn validateRijndaelConstants() RijndaelAbiError!void {
    if (WindowsRijndaelSpec.MAXKC != 8) return error.InvalidMaxKeyColumnCount;
    if (WindowsRijndaelSpec.MAXKB != 32) return error.InvalidMaxKeyByteCount;
    if (WindowsRijndaelSpec.MAXNR != 14) return error.InvalidMaxRoundCount;
}

pub fn validateRijndaelTypeWidths() RijndaelAbiError!void {
    if (MacOsRijndael.sizeof_u8 != WindowsRijndaelSpec.sizeof_u8)
        return error.InvalidTypeWidth;
    if (MacOsRijndael.sizeof_u16 != WindowsRijndaelSpec.sizeof_u16)
        return error.InvalidTypeWidth;
    if (MacOsRijndael.sizeof_u32 != WindowsRijndaelSpec.sizeof_u32)
        return error.InvalidTypeWidth;
}

pub fn validateAll() RijndaelAbiError!void {
    try validateRijndaelConstants();
    try validateRijndaelTypeWidths();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosette_validate_rijndael() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidMaxKeyColumnCount => 1,
        error.InvalidMaxKeyByteCount => 2,
        error.InvalidMaxRoundCount => 3,
        error.InvalidTypeWidth => 4,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosette_rijndael_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidMaxKeyColumnCount",
        2 => "InvalidMaxKeyByteCount",
        3 => "InvalidMaxRoundCount",
        4 => "InvalidTypeWidth",
        else => "UnknownRijndaelFailure",
    };
}

pub fn reportRijndaelSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ Rijndael (AES) ABI Specification Table
        \\================================================================================
        \\ MAXKC = {d}
        \\ MAXKB = {d}
        \\ MAXNR = {d}
        \\
        \\ Type widths:
        \\   u8  = {d}
        \\   u16 = {d}
        \\   u32 = {d}
        \\
    , .{
        WindowsRijndaelSpec.MAXKC,
        WindowsRijndaelSpec.MAXKB,
        WindowsRijndaelSpec.MAXNR,
        MacOsRijndael.sizeof_u8,
        MacOsRijndael.sizeof_u16,
        MacOsRijndael.sizeof_u32,
    });
}

/// print the full Rijndael ABI spec table.
pub export fn rosette_print_rijndael_spec() void {
    reportRijndaelSpec();
}

test "Rijndael ABI spec matches expected values" {
    reportRijndaelSpec();
    try validateAll();
}
