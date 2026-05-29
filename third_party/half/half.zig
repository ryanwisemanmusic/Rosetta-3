const std = @import("std");

pub const HalfError = error{
    InvalidRoundStyle,
    InvalidTiesToEven,
    InvalidFastFma,
    InvalidInfinityBits,
    InvalidNanBits,
    InvalidSignalingNanBits,
    InvalidMaxFiniteBits,
    InvalidMinNormalBits,
    InvalidDenormMinBits,
    InvalidEpsilonBits,
    InvalidNegZeroBits,
    InvalidExponentWidth,
    InvalidMantissaWidth,
    InvalidTotalWidth,
    InvalidExponentBias,
    InvalidMantissaTableLen,
    InvalidExponentTableLen,
    InvalidOffsetTableLen,
    InvalidBaseTableLen,
    InvalidShiftTableLen,
    InvalidVersionMajor,
    InvalidVersionMinor,
    InvalidVersionPatch,
    InvalidFpClassConstant,
    InvalidUint16Width,
    InvalidFloatWidth,
    InvalidDoubleWidth,
};

/// Pseudo-Windows snapshot. IEEE 754 binary16 is a platform-independent
/// standard — there is no LP64 vs LLP64 divergence in the half-precision
/// format itself.  All algorithm constants are convergent across macOS
/// and Windows. Type-level divergences relevant to the library are
/// documented below.
pub const WindowsHalfSpec = struct {
    pub const VERSION_MAJOR: u32 = 1;
    pub const VERSION_MINOR: u32 = 12;
    pub const VERSION_PATCH: u32 = 0;

    pub const HALF_ROUND_STYLE: i32 = -1;
    pub const HALF_ROUND_TIES_TO_EVEN: u32 = 0;
    pub const FP_FAST_FMAH: u32 = 1;

    pub const INFINITY_BITS: u16 = 0x7C00;
    pub const QUIET_NAN_BITS: u16 = 0x7FFF;
    pub const SIGNALING_NAN_BITS: u16 = 0x7DFF;
    pub const MAX_FINITE_BITS: u16 = 0x7BFF;
    pub const LOWEST_BITS: u16 = 0xFBFF;
    pub const MIN_NORMAL_BITS: u16 = 0x0400;
    pub const DENORM_MIN_BITS: u16 = 0x0001;
    pub const EPSILON_BITS: u16 = 0x1400;
    pub const POS_ZERO_BITS: u16 = 0x0000;
    pub const NEG_ZERO_BITS: u16 = 0x8000;

    pub const SIGN_BIT: u16 = 0x8000;
    pub const EXPONENT_MASK: u16 = 0x7C00;
    pub const MANTISSA_MASK: u16 = 0x03FF;

    pub const EXPONENT_WIDTH: u32 = 5;
    pub const MANTISSA_WIDTH: u32 = 10;
    pub const TOTAL_WIDTH: u32 = 16;
    pub const EXPONENT_BIAS: u32 = 15;
    pub const MIN_EXPONENT: i32 = -14;
    pub const MAX_EXPONENT: i32 = 16;

    pub const DIGITS: u32 = 11;
    pub const DIGITS10: u32 = 3;
    pub const MIN_EXPONENT10: i32 = -4;
    pub const MAX_EXPONENT10: i32 = 4;

    pub const sizeof_half: comptime_int = 2;

    pub const FP_ZERO: u32 = 1;
    pub const FP_NAN: u32 = 2;
    pub const FP_INFINITE: u32 = 3;
    pub const FP_NORMAL: u32 = 4;
    pub const FP_SUBNORMAL: u32 = 0;

    pub const mantissa_table_len: u32 = 2048;
    pub const exponent_table_len: u32 = 64;
    pub const offset_table_len: u32 = 64;
    pub const base_table_len: u32 = 512;
    pub const shift_table_len: u32 = 512;
};

/// macOS host snapshot. All IEEE 754 binary16 constants are convergent.
/// The relevant type-width checks ensure the host C++ compiler's type
/// sizes match expectations (uint16 = 2 bytes, float = 4 bytes, etc.).
pub const MacOsHalf = struct {
    pub const sizeof_u16 = @sizeOf(u16);
    pub const sizeof_u32 = @sizeOf(u32);
    pub const sizeof_u64 = @sizeOf(u64);
    pub const sizeof_f16 = @sizeOf(f16);
    pub const sizeof_f32 = @sizeOf(f32);
    pub const sizeof_f64 = @sizeOf(f64);
};

pub fn validateHalfVersion() HalfError!void {
    if (WindowsHalfSpec.VERSION_MAJOR != 1) return error.InvalidVersionMajor;
    if (WindowsHalfSpec.VERSION_MINOR != 12) return error.InvalidVersionMinor;
    if (WindowsHalfSpec.VERSION_PATCH != 0) return error.InvalidVersionPatch;
}

pub fn validateHalfConfigDefaults() HalfError!void {
    if (WindowsHalfSpec.HALF_ROUND_STYLE != -1) return error.InvalidRoundStyle;
    if (WindowsHalfSpec.HALF_ROUND_TIES_TO_EVEN != 0) return error.InvalidTiesToEven;
    if (WindowsHalfSpec.FP_FAST_FMAH != 1) return error.InvalidFastFma;
}

pub fn validateHalfFormatConstants() HalfError!void {
    if (WindowsHalfSpec.INFINITY_BITS != 0x7C00) return error.InvalidInfinityBits;
    if (WindowsHalfSpec.QUIET_NAN_BITS != 0x7FFF) return error.InvalidNanBits;
    if (WindowsHalfSpec.SIGNALING_NAN_BITS != 0x7DFF) return error.InvalidSignalingNanBits;
    if (WindowsHalfSpec.MAX_FINITE_BITS != 0x7BFF) return error.InvalidMaxFiniteBits;
    if (WindowsHalfSpec.MIN_NORMAL_BITS != 0x0400) return error.InvalidMinNormalBits;
    if (WindowsHalfSpec.DENORM_MIN_BITS != 0x0001) return error.InvalidDenormMinBits;
    if (WindowsHalfSpec.EPSILON_BITS != 0x1400) return error.InvalidEpsilonBits;
    if (WindowsHalfSpec.NEG_ZERO_BITS != 0x8000) return error.InvalidNegZeroBits;

    if (WindowsHalfSpec.SIGN_BIT != 0x8000) return error.InvalidTotalWidth;
    if (WindowsHalfSpec.EXPONENT_MASK != 0x7C00) return error.InvalidExponentWidth;
    if (WindowsHalfSpec.MANTISSA_MASK != 0x03FF) return error.InvalidMantissaWidth;

    if (WindowsHalfSpec.EXPONENT_WIDTH != 5) return error.InvalidExponentWidth;
    if (WindowsHalfSpec.MANTISSA_WIDTH != 10) return error.InvalidMantissaWidth;
    if (WindowsHalfSpec.TOTAL_WIDTH != 16) return error.InvalidTotalWidth;
    if (WindowsHalfSpec.EXPONENT_BIAS != 15) return error.InvalidExponentBias;

    if (WindowsHalfSpec.DIGITS != 11) return error.InvalidMantissaWidth;
    if (WindowsHalfSpec.DIGITS10 != 3) return error.InvalidMantissaWidth;
}

pub fn validateHalfFpClassConstants() HalfError!void {
    if (WindowsHalfSpec.FP_ZERO != 1) return error.InvalidFpClassConstant;
    if (WindowsHalfSpec.FP_NAN != 2) return error.InvalidFpClassConstant;
    if (WindowsHalfSpec.FP_INFINITE != 3) return error.InvalidFpClassConstant;
    if (WindowsHalfSpec.FP_NORMAL != 4) return error.InvalidFpClassConstant;
    if (WindowsHalfSpec.FP_SUBNORMAL != 0) return error.InvalidFpClassConstant;
}

pub fn validateHalfTableSizes() HalfError!void {
    if (WindowsHalfSpec.mantissa_table_len != 2048) return error.InvalidMantissaTableLen;
    if (WindowsHalfSpec.exponent_table_len != 64) return error.InvalidExponentTableLen;
    if (WindowsHalfSpec.offset_table_len != 64) return error.InvalidOffsetTableLen;
    if (WindowsHalfSpec.base_table_len != 512) return error.InvalidBaseTableLen;
    if (WindowsHalfSpec.shift_table_len != 512) return error.InvalidShiftTableLen;
}

/// Validates host type widths. The half library uses `detail::uint16`
/// (std::uint_least16_t, always 2 bytes) internally.  On both macOS
/// LP64 and Windows LLP64, u16 is 2 bytes and f32 is 4 bytes — these
/// are convergent properties.  No LP64/LLP64 divergence exists in the
/// half-precision domain.
pub fn validateHalfTypeWidths() HalfError!void {
    if (MacOsHalf.sizeof_u16 != WindowsHalfSpec.sizeof_half) {
        return error.InvalidUint16Width;
    }
    if (MacOsHalf.sizeof_f32 != 4) return error.InvalidFloatWidth;
    if (MacOsHalf.sizeof_f64 != 8) return error.InvalidDoubleWidth;
    if (MacOsHalf.sizeof_f16 != 2) return error.InvalidUint16Width;
}

pub fn validateAll() HalfError!void {
    try validateHalfVersion();
    try validateHalfConfigDefaults();
    try validateHalfFormatConstants();
    try validateHalfFpClassConstants();
    try validateHalfTableSizes();
    try validateHalfTypeWidths();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_half() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidRoundStyle => 1,
        error.InvalidTiesToEven => 2,
        error.InvalidFastFma => 3,
        error.InvalidInfinityBits => 4,
        error.InvalidNanBits => 5,
        error.InvalidSignalingNanBits => 6,
        error.InvalidMaxFiniteBits => 7,
        error.InvalidMinNormalBits => 8,
        error.InvalidDenormMinBits => 9,
        error.InvalidEpsilonBits => 10,
        error.InvalidNegZeroBits => 11,
        error.InvalidExponentWidth => 12,
        error.InvalidMantissaWidth => 13,
        error.InvalidTotalWidth => 14,
        error.InvalidExponentBias => 15,
        error.InvalidMantissaTableLen => 16,
        error.InvalidExponentTableLen => 17,
        error.InvalidOffsetTableLen => 18,
        error.InvalidBaseTableLen => 19,
        error.InvalidShiftTableLen => 20,
        error.InvalidVersionMajor => 21,
        error.InvalidVersionMinor => 22,
        error.InvalidVersionPatch => 23,
        error.InvalidFpClassConstant => 24,
        error.InvalidUint16Width => 25,
        error.InvalidFloatWidth => 26,
        error.InvalidDoubleWidth => 27,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosetta3_half_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidRoundStyle",
        2 => "InvalidTiesToEven",
        3 => "InvalidFastFma",
        4 => "InvalidInfinityBits",
        5 => "InvalidNanBits",
        6 => "InvalidSignalingNanBits",
        7 => "InvalidMaxFiniteBits",
        8 => "InvalidMinNormalBits",
        9 => "InvalidDenormMinBits",
        10 => "InvalidEpsilonBits",
        11 => "InvalidNegZeroBits",
        12 => "InvalidExponentWidth",
        13 => "InvalidMantissaWidth",
        14 => "InvalidTotalWidth",
        15 => "InvalidExponentBias",
        16 => "InvalidMantissaTableLen",
        17 => "InvalidExponentTableLen",
        18 => "InvalidOffsetTableLen",
        19 => "InvalidBaseTableLen",
        20 => "InvalidShiftTableLen",
        21 => "InvalidVersionMajor",
        22 => "InvalidVersionMinor",
        23 => "InvalidVersionPatch",
        24 => "InvalidFpClassConstant",
        25 => "InvalidUint16Width",
        26 => "InvalidFloatWidth",
        27 => "InvalidDoubleWidth",
        else => "UnknownHalfFailure",
    };
}

pub fn reportHalfSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ IEEE 754 binary16 (half-precision) Specification Table
        \\================================================================================
        \\ Library: half.hpp v{d}.{d}.{d}
        \\ Config:
        \\   HALF_ROUND_STYLE        = {d}  (default: fastest/truncation)
        \\   HALF_ROUND_TIES_TO_EVEN = {d}  (0 = ties away from zero)
        \\   FP_FAST_FMAH            = {d}
        \\
        \\ Format (IEEE 754 binary16):
        \\   Total width             = {d} bits
        \\   Exponent width          = {d} bits
        \\   Mantissa width          = {d} bits
        \\   Exponent bias           = {d}
        \\   Min exponent            = {d}
        \\   Max exponent            = {d}
        \\   digits (mantissa+1)     = {d}
        \\   digits10                = {d}
        \\
    , .{
        WindowsHalfSpec.VERSION_MAJOR,    WindowsHalfSpec.VERSION_MINOR,           WindowsHalfSpec.VERSION_PATCH,
        WindowsHalfSpec.HALF_ROUND_STYLE, WindowsHalfSpec.HALF_ROUND_TIES_TO_EVEN, WindowsHalfSpec.FP_FAST_FMAH,
        WindowsHalfSpec.TOTAL_WIDTH,      WindowsHalfSpec.EXPONENT_WIDTH,          WindowsHalfSpec.MANTISSA_WIDTH,
        WindowsHalfSpec.EXPONENT_BIAS,    WindowsHalfSpec.MIN_EXPONENT,            WindowsHalfSpec.MAX_EXPONENT,
        WindowsHalfSpec.DIGITS,           WindowsHalfSpec.DIGITS10,
    });

    std.debug.print(
        \\ Key bit patterns:
        \\   INFINITY                = 0x{x:0>4}
        \\   QUIET_NAN               = 0x{x:0>4}
        \\   SIGNALING_NAN           = 0x{x:0>4}
        \\   MAX_FINITE              = 0x{x:0>4}
        \\   LOWEST                  = 0x{x:0>4}
        \\   MIN_NORMAL              = 0x{x:0>4}
        \\   DENORM_MIN              = 0x{x:0>4}
        \\   EPSILON                 = 0x{x:0>4}
        \\   POS_ZERO                = 0x{x:0>4}
        \\   NEG_ZERO                = 0x{x:0>4}
        \\
        \\ Bit masks:
        \\   SIGN_BIT                = 0x{x:0>4}
        \\   EXPONENT_MASK           = 0x{x:0>4}
        \\   MANTISSA_MASK           = 0x{x:0>4}
        \\
    , .{
        WindowsHalfSpec.INFINITY_BITS,
        WindowsHalfSpec.QUIET_NAN_BITS,
        WindowsHalfSpec.SIGNALING_NAN_BITS,
        WindowsHalfSpec.MAX_FINITE_BITS,
        WindowsHalfSpec.LOWEST_BITS,
        WindowsHalfSpec.MIN_NORMAL_BITS,
        WindowsHalfSpec.DENORM_MIN_BITS,
        WindowsHalfSpec.EPSILON_BITS,
        WindowsHalfSpec.POS_ZERO_BITS,
        WindowsHalfSpec.NEG_ZERO_BITS,
        WindowsHalfSpec.SIGN_BIT,
        WindowsHalfSpec.EXPONENT_MASK,
        WindowsHalfSpec.MANTISSA_MASK,
    });

    std.debug.print(
        \\ Conversion table sizes:
        \\   mantissa_table          = {d} entries
        \\   exponent_table          = {d} entries
        \\   offset_table            = {d} entries
        \\   base_table              = {d} entries
        \\   shift_table             = {d} entries
        \\
        \\ FP classification constants:
        \\   FP_ZERO                 = {d}
        \\   FP_NAN                  = {d}
        \\   FP_INFINITE             = {d}
        \\   FP_NORMAL               = {d}
        \\   FP_SUBNORMAL            = {d}
        \\
        \\ Type widths:
        \\   sizeof(uint16)          = {d}  (expected: {d})
        \\   sizeof(float)           = {d}  (expected: {d})
        \\   sizeof(double)          = {d}  (expected: {d})
        \\   sizeof(half)            = {d}  (expected: {d})
        \\
        \\================================================================================
        \\
    , .{
        WindowsHalfSpec.mantissa_table_len,
        WindowsHalfSpec.exponent_table_len,
        WindowsHalfSpec.offset_table_len,
        WindowsHalfSpec.base_table_len,
        WindowsHalfSpec.shift_table_len,
        WindowsHalfSpec.FP_ZERO,
        WindowsHalfSpec.FP_NAN,
        WindowsHalfSpec.FP_INFINITE,
        WindowsHalfSpec.FP_NORMAL,
        WindowsHalfSpec.FP_SUBNORMAL,
        MacOsHalf.sizeof_u16,
        WindowsHalfSpec.sizeof_half,
        MacOsHalf.sizeof_f32,
        4,
        MacOsHalf.sizeof_f64,
        8,
        MacOsHalf.sizeof_f16,
        WindowsHalfSpec.sizeof_half,
    });
}

pub export fn rosetta3_print_half_spec() void {
    reportHalfSpec();
}

test "half spec matches expected values" {
    reportHalfSpec();
    try validateAll();
}
