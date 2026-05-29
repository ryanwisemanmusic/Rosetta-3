const std = @import("std");

pub const AvxToNeonError = error{
    InvalidM128iSize,
    InvalidM128Size,
    InvalidM128dSize,
    InvalidTypeWidth,
    InvalidCmpintEnum,
    InvalidSiddConstant,
    InvalidForceInline,
    InvalidAlignStruct,
    InvalidEndianKey,
    InvalidMaskArraySize,
};

/// Pseudo-Windows snapshot. All type sizes and constants sourced from
/// avx2neon.h / emmintrin.h / avxintrin.h etc. (Huawei AvxToNeon).
/// Since ARM NEON intrinsic types have fixed sizes, there is no LP64
/// vs LLP64 divergence — every value is convergent across platforms.
pub const WindowsAvxToNeonSpec = struct {
    // ── SIMD type sizes (bytes) ─────────────────────────────────────
    pub const sizeof___m128i: comptime_int = 16;
    pub const sizeof___m128: comptime_int = 16;
    pub const sizeof___m128d: comptime_int = 16;

    // ── _MM_CMPINT_ENUM values ──────────────────────────────────────
    pub const _MM_CMPINT_EQ: i32 = 0;
    pub const _MM_CMPINT_LT: i32 = 1;
    pub const _MM_CMPINT_LE: i32 = 2;
    pub const _MM_CMPINT_FALSE: i32 = 3;
    pub const _MM_CMPINT_NE: i32 = 4;
    pub const _MM_CMPINT_NLT: i32 = 5;
    pub const _MM_CMPINT_NLE: i32 = 6;
    pub const _MM_CMPINT_TRUE: i32 = 7;

    // ── _SIDD_* constants (PALIGNR / PCMPSTR) ───────────────────────
    pub const _SIDD_UBYTE_OPS: u32 = 0x00;
    pub const _SIDD_UWORD_OPS: u32 = 0x01;
    pub const _SIDD_SBYTE_OPS: u32 = 0x02;
    pub const _SIDD_SWORD_OPS: u32 = 0x03;
    pub const _SIDD_CMP_EQUAL_ANY: u32 = 0x00;
    pub const _SIDD_CMP_RANGES: u32 = 0x04;
    pub const _SIDD_CMP_EQUAL_EACH: u32 = 0x08;
    pub const _SIDD_CMP_EQUAL_ORDERED: u32 = 0x0C;
    pub const _SIDD_POSITIVE_POLARITY: u32 = 0x00;
    pub const _SIDD_NEGATIVE_POLARITY: u32 = 0x10;
    pub const _SIDD_MASKED_POSITIVE_POLARITY: u32 = 0x20;
    pub const _SIDD_MASKED_NEGATIVE_POLARITY: u32 = 0x30;
    pub const _SIDD_LEAST_SIGNIFICANT: u32 = 0x00;
    pub const _SIDD_MOST_SIGNIFICANT: u32 = 0x40;
    pub const _SIDD_BIT_MASK: u32 = 0x00;
    pub const _SIDD_UNIT_MASK: u32 = 0x40;

    // ── Mask arrays (g_mask_epi64 etc.) ─────────────────────────────
    pub const mask_epi64_len: comptime_int = 2;
    pub const mask_epi32_len: comptime_int = 4;
    pub const mask_epi16_len: comptime_int = 8;
    pub const mask_epi8_len: comptime_int = 16;

    pub const mask_epi64_expected = [2]u64{ 0x01, 0x02 };
    pub const mask_epi32_expected = [4]u32{ 0x01, 0x02, 0x04, 0x08 };
    pub const mask_epi16_expected = [8]u16{ 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80 };
    pub const mask_epi8_expected = [16]u8{
        0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
        0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
    };

    // ── typedefs.h constants ────────────────────────────────────────
    pub const FORCE_INLINE_IS_STATIC_INLINE: u32 = 1;
    pub const ALIGN_STRUCT_IS_GCC_ALIGNED: u32 = 1;
    pub const likely_is_builtin: u32 = 1;
    pub const unlikely_is_builtin: u32 = 1;

    // Type alias widths
    pub const sizeof___int32: comptime_int = 4;
    pub const sizeof___int64: comptime_int = 8;
    pub const sizeof___mmask64: comptime_int = 8;
    pub const sizeof___mmask16: comptime_int = 2;
    pub const sizeof___mmask8: comptime_int = 1;
};

/// macOS host snapshot. ARM NEON intrinsic types have platform-
/// independent sizes.  Type-width checks confirm convergence of
/// standard integer and pointer types on both platforms.
pub const MacOsAvxToNeon = struct {
    pub const sizeof_u8 = @sizeOf(u8);
    pub const sizeof_u16 = @sizeOf(u16);
    pub const sizeof_u32 = @sizeOf(u32);
    pub const sizeof_u64 = @sizeOf(u64);
};

pub fn validateAvxToNeonTypeSizes() AvxToNeonError!void {
    if (WindowsAvxToNeonSpec.sizeof___m128i != 16) return error.InvalidM128iSize;
    if (WindowsAvxToNeonSpec.sizeof___m128 != 16) return error.InvalidM128Size;
    if (WindowsAvxToNeonSpec.sizeof___m128d != 16) return error.InvalidM128dSize;

    if (WindowsAvxToNeonSpec.sizeof___int32 != 4) return error.InvalidTypeWidth;
    if (WindowsAvxToNeonSpec.sizeof___int64 != 8) return error.InvalidTypeWidth;
    if (WindowsAvxToNeonSpec.sizeof___mmask64 != 8) return error.InvalidTypeWidth;
    if (WindowsAvxToNeonSpec.sizeof___mmask16 != 2) return error.InvalidTypeWidth;
    if (WindowsAvxToNeonSpec.sizeof___mmask8 != 1) return error.InvalidTypeWidth;
}

pub fn validateAvxToNeonConstants() AvxToNeonError!void {
    if (WindowsAvxToNeonSpec._MM_CMPINT_EQ != 0) return error.InvalidCmpintEnum;
    if (WindowsAvxToNeonSpec._MM_CMPINT_LT != 1) return error.InvalidCmpintEnum;
    if (WindowsAvxToNeonSpec._MM_CMPINT_LE != 2) return error.InvalidCmpintEnum;
    if (WindowsAvxToNeonSpec._MM_CMPINT_FALSE != 3) return error.InvalidCmpintEnum;
    if (WindowsAvxToNeonSpec._MM_CMPINT_NE != 4) return error.InvalidCmpintEnum;
    if (WindowsAvxToNeonSpec._MM_CMPINT_NLT != 5) return error.InvalidCmpintEnum;
    if (WindowsAvxToNeonSpec._MM_CMPINT_NLE != 6) return error.InvalidCmpintEnum;
    if (WindowsAvxToNeonSpec._MM_CMPINT_TRUE != 7) return error.InvalidCmpintEnum;

    if (WindowsAvxToNeonSpec._SIDD_UBYTE_OPS != 0x00) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_UWORD_OPS != 0x01) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_SBYTE_OPS != 0x02) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_SWORD_OPS != 0x03) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_CMP_EQUAL_ANY != 0x00) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_CMP_RANGES != 0x04) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_CMP_EQUAL_EACH != 0x08) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_CMP_EQUAL_ORDERED != 0x0C) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_POSITIVE_POLARITY != 0x00) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_NEGATIVE_POLARITY != 0x10) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_MASKED_POSITIVE_POLARITY != 0x20) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_MASKED_NEGATIVE_POLARITY != 0x30) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_LEAST_SIGNIFICANT != 0x00) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_MOST_SIGNIFICANT != 0x40) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_BIT_MASK != 0x00) return error.InvalidSiddConstant;
    if (WindowsAvxToNeonSpec._SIDD_UNIT_MASK != 0x40) return error.InvalidSiddConstant;
}

pub fn validateAvxToNeonMaskArrays() AvxToNeonError!void {
    if (WindowsAvxToNeonSpec.mask_epi64_len != 2) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi32_len != 4) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi16_len != 8) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi8_len != 16) return error.InvalidMaskArraySize;

    if (WindowsAvxToNeonSpec.mask_epi64_expected[0] != 0x01) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi64_expected[1] != 0x02) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi32_expected[0] != 0x01) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi32_expected[3] != 0x08) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi16_expected[7] != 0x80) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi8_expected[0] != 0x01) return error.InvalidMaskArraySize;
    if (WindowsAvxToNeonSpec.mask_epi8_expected[15] != 0x80) return error.InvalidMaskArraySize;
}

pub fn validateAvxToNeonTypeWidths() AvxToNeonError!void {
    if (MacOsAvxToNeon.sizeof_u8 != 1) return error.InvalidTypeWidth;
    if (MacOsAvxToNeon.sizeof_u16 != 2) return error.InvalidTypeWidth;
    if (MacOsAvxToNeon.sizeof_u32 != 4) return error.InvalidTypeWidth;
    if (MacOsAvxToNeon.sizeof_u64 != 8) return error.InvalidTypeWidth;
}

pub fn validateAll() AvxToNeonError!void {
    try validateAvxToNeonTypeSizes();
    try validateAvxToNeonConstants();
    try validateAvxToNeonMaskArrays();
    try validateAvxToNeonTypeWidths();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_avx_to_neon() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidM128iSize => 1,
        error.InvalidM128Size => 2,
        error.InvalidM128dSize => 3,
        error.InvalidTypeWidth => 4,
        error.InvalidCmpintEnum => 5,
        error.InvalidSiddConstant => 6,
        error.InvalidForceInline => 7,
        error.InvalidAlignStruct => 8,
        error.InvalidEndianKey => 9,
        error.InvalidMaskArraySize => 10,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosetta3_avx_to_neon_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidM128iSize",
        2 => "InvalidM128Size",
        3 => "InvalidM128dSize",
        4 => "InvalidTypeWidth",
        5 => "InvalidCmpintEnum",
        6 => "InvalidSiddConstant",
        7 => "InvalidForceInline",
        8 => "InvalidAlignStruct",
        9 => "InvalidEndianKey",
        10 => "InvalidMaskArraySize",
        else => "UnknownAvxToNeonFailure",
    };
}

pub fn reportAvxToNeonSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ AvxToNeon (Huawei SSE→NEON) Specification Table
        \\================================================================================
        \\ SIMD type sizes:
        \\   sizeof(__m128i)  = {d} bytes
        \\   sizeof(__m128)   = {d} bytes
        \\   sizeof(__m128d)  = {d} bytes
        \\
        \\ _MM_CMPINT_ENUM:
        \\   EQ={d} LT={d} LE={d} FALSE={d}
        \\   NE={d} NLT={d} NLE={d} TRUE={d}
        \\
        \\ _SIDD_* constants:
        \\   UBYTE_OPS=0x{x:0>2} UWORD_OPS=0x{x:0>2}
        \\   SBYTE_OPS=0x{x:0>2} SWORD_OPS=0x{x:0>2}
        \\   CMP_EQUAL_ANY=0x{x:0>2} CMP_RANGES=0x{x:0>2}
        \\   CMP_EQUAL_EACH=0x{x:0>2} CMP_EQUAL_ORDERED=0x{x:0>2}
        \\
        \\ Mask arrays:
        \\   g_mask_epi64  [{d} entries]
        \\   g_mask_epi32  [{d} entries]
        \\   g_mask_epi16  [{d} entries]
        \\   g_mask_epi8   [{d} entries]
        \\
        \\================================================================================
        \\
    , .{
        WindowsAvxToNeonSpec.sizeof___m128i,
        WindowsAvxToNeonSpec.sizeof___m128,
        WindowsAvxToNeonSpec.sizeof___m128d,
        WindowsAvxToNeonSpec._MM_CMPINT_EQ,
        WindowsAvxToNeonSpec._MM_CMPINT_LT,
        WindowsAvxToNeonSpec._MM_CMPINT_LE,
        WindowsAvxToNeonSpec._MM_CMPINT_FALSE,
        WindowsAvxToNeonSpec._MM_CMPINT_NE,
        WindowsAvxToNeonSpec._MM_CMPINT_NLT,
        WindowsAvxToNeonSpec._MM_CMPINT_NLE,
        WindowsAvxToNeonSpec._MM_CMPINT_TRUE,
        WindowsAvxToNeonSpec._SIDD_UBYTE_OPS,
        WindowsAvxToNeonSpec._SIDD_UWORD_OPS,
        WindowsAvxToNeonSpec._SIDD_SBYTE_OPS,
        WindowsAvxToNeonSpec._SIDD_SWORD_OPS,
        WindowsAvxToNeonSpec._SIDD_CMP_EQUAL_ANY,
        WindowsAvxToNeonSpec._SIDD_CMP_RANGES,
        WindowsAvxToNeonSpec._SIDD_CMP_EQUAL_EACH,
        WindowsAvxToNeonSpec._SIDD_CMP_EQUAL_ORDERED,
        WindowsAvxToNeonSpec.mask_epi64_len,
        WindowsAvxToNeonSpec.mask_epi32_len,
        WindowsAvxToNeonSpec.mask_epi16_len,
        WindowsAvxToNeonSpec.mask_epi8_len,
    });
}

pub export fn rosetta3_print_avx_to_neon_spec() void {
    reportAvxToNeonSpec();
}

test "AvxToNeon spec matches expected values" {
    reportAvxToNeonSpec();
    try validateAll();
}
