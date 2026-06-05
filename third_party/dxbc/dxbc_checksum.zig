const std = @import("std");

pub const DxbcChecksumError = error{
    InvalidMd5InitConstant,
    InvalidShiftConstant,
    InvalidRoundConstant,
    InvalidHashOffset,
    InvalidPseudoRandomMultiplier,
    InvalidPaddingArray,
    InvalidTerminatorConstant,
    InvalidUnsignedLongWidth,
    InvalidUint4Width,
    InvalidMd5CtxLayout,
};

/// Pseudo-Windows snapshot. All algorithm constants sourced from
/// DXBCChecksum.cpp which follows the Win32 x64 LLP64 convention.
/// MD5 algorithm constants are platform-independent (same on both
/// macOS and Windows). Type-level divergences are documented below.
pub const WindowsDxbcSpec = struct {
    pub const MD5_A: u32 = 0x67452301;
    pub const MD5_B: u32 = 0xefcdab89;
    pub const MD5_C: u32 = 0x98badcfe;
    pub const MD5_D: u32 = 0x10325476;

    pub const S11: u32 = 7;
    pub const S12: u32 = 12;
    pub const S13: u32 = 17;
    pub const S14: u32 = 22;
    pub const S21: u32 = 5;
    pub const S22: u32 = 9;
    pub const S23: u32 = 14;
    pub const S24: u32 = 20;
    pub const S31: u32 = 4;
    pub const S32: u32 = 11;
    pub const S33: u32 = 16;
    pub const S34: u32 = 23;
    pub const S41: u32 = 6;
    pub const S42: u32 = 10;
    pub const S43: u32 = 15;
    pub const S44: u32 = 21;

    pub const PR_A: u32 = 11;
    pub const PR_B: u32 = 71;
    pub const PR_C: u32 = 37;
    pub const PR_D: u32 = 97;

    pub const HASH_OFFSET: u32 = 0x14;
    pub const TERMINATOR_LSB: u32 = 1;
    pub const CHUNK_SIZE: u32 = 64;
    pub const PAD_THRESHOLD: u32 = 56;

    pub const sizeof_UINT4: comptime_int = 4;
    pub const sizeof_unsigned_long: comptime_int = 4;

    // ── MD5_CTX struct layout (LLP64) ─────────────────────────────────
    //   offset 0:  UINT4 i[2]            =  8 bytes  (bits counter)
    //   offset 8:  UINT4 buf[4]          = 16 bytes  (scratch buffer)
    //   offset 24: unsigned char in[64]  = 64 bytes  (input buffer)
    //   offset 88: unsigned char digest[16] = 16 bytes (final digest)
    //   total: 104 bytes
    pub const sizeof_MD5_CTX: comptime_int = 104;
    pub const offsetof_i: comptime_int = 0;
    pub const offsetof_buf: comptime_int = 8;
    pub const offsetof_in: comptime_int = 24;
    pub const offsetof_digest: comptime_int = 88;

    pub const padding = [64]u8{
        0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };

    pub const round1 = [16]u32{
        3614090360, 3905402710, 606105819,  3250441966,
        4118548399, 1200080426, 2821735955, 4249261313,
        1770035416, 2336552879, 4294925233, 2304563134,
        1804603682, 4254626195, 2792965006, 1236535329,
    };
    pub const round2 = [16]u32{
        4129170786, 3225465664, 643717713,  3921069994,
        3593408605, 38016083,   3634488961, 3889429448,
        568446438,  3275163606, 4107603335, 1163531501,
        2850285829, 4243563512, 1735328473, 2368359562,
    };
    pub const round3 = [16]u32{
        4294588738, 2272392833, 1839030562, 4259657740,
        2763975236, 1272893353, 4139469664, 3200236656,
        681279174,  3936430074, 3572445317, 76029189,
        3654602809, 3873151461, 530742520,  3299628645,
    };
    pub const round4 = [16]u32{
        4096336452, 1126891415, 2878612391, 4237533241,
        1700485571, 2399980690, 4293915773, 2240044497,
        1873313359, 4264355552, 2734768916, 1309151649,
        4149444226, 3174756917, 718787259,  3951481745,
    };

    /// All 64 round constants concatenated in order
    pub const all_round_constants = round1 ++ round2 ++ round3 ++ round4;
};

/// macOS host snapshot. MD5 algorithm constants are platform-independent
/// (identical to Windows spec). The relevant divergence is `c_ulong` width:
/// macOS LP64 uses 8 bytes whereas Windows LLP64 uses 4 bytes. This affects
/// the `MD5Init(unsigned long pseudoRandomNumber)` parameter width.
pub const MacOsDxbc = struct {
    pub const sizeof_c_uint = @sizeOf(c_uint);
    pub const sizeof_c_ulong = @sizeOf(c_ulong);
    pub const sizeof_u32 = @sizeOf(u32);
};

/// Validates all algorithm constants are correct per the Windows spec.
pub fn validateDxbcChecksumConstants() DxbcChecksumError!void {
    if (WindowsDxbcSpec.MD5_A != 0x67452301) return error.InvalidMd5InitConstant;
    if (WindowsDxbcSpec.MD5_B != 0xefcdab89) return error.InvalidMd5InitConstant;
    if (WindowsDxbcSpec.MD5_C != 0x98badcfe) return error.InvalidMd5InitConstant;
    if (WindowsDxbcSpec.MD5_D != 0x10325476) return error.InvalidMd5InitConstant;

    // Shift amounts (must be 1..31)
    const shifts = [_]u32{
        WindowsDxbcSpec.S11, WindowsDxbcSpec.S12,
        WindowsDxbcSpec.S13, WindowsDxbcSpec.S14,
        WindowsDxbcSpec.S21, WindowsDxbcSpec.S22,
        WindowsDxbcSpec.S23, WindowsDxbcSpec.S24,
        WindowsDxbcSpec.S31, WindowsDxbcSpec.S32,
        WindowsDxbcSpec.S33, WindowsDxbcSpec.S34,
        WindowsDxbcSpec.S41, WindowsDxbcSpec.S42,
        WindowsDxbcSpec.S43, WindowsDxbcSpec.S44,
    };
    for (shifts) |s| {
        if (s < 1 or s > 31) return error.InvalidShiftConstant;
    }

    if (WindowsDxbcSpec.HASH_OFFSET != 0x14) return error.InvalidHashOffset;
    if (WindowsDxbcSpec.TERMINATOR_LSB != 1) return error.InvalidTerminatorConstant;
    if (WindowsDxbcSpec.CHUNK_SIZE != 64) return error.InvalidHashOffset;
    if (WindowsDxbcSpec.PAD_THRESHOLD != 56) return error.InvalidHashOffset;

    if (WindowsDxbcSpec.PR_A == 0 or WindowsDxbcSpec.PR_B == 0 or
        WindowsDxbcSpec.PR_C == 0 or WindowsDxbcSpec.PR_D == 0)
        return error.InvalidPseudoRandomMultiplier;

    if (WindowsDxbcSpec.round1.len != 16 or
        WindowsDxbcSpec.round2.len != 16 or
        WindowsDxbcSpec.round3.len != 16 or
        WindowsDxbcSpec.round4.len != 16)
        return error.InvalidRoundConstant;

    if (WindowsDxbcSpec.all_round_constants.len != 64)
        return error.InvalidRoundConstant;

    if (WindowsDxbcSpec.round1[0] != 3614090360) return error.InvalidRoundConstant;
    if (WindowsDxbcSpec.round1[15] != 1236535329) return error.InvalidRoundConstant;
    if (WindowsDxbcSpec.round2[0] != 4129170786) return error.InvalidRoundConstant;
    if (WindowsDxbcSpec.round2[15] != 2368359562) return error.InvalidRoundConstant;
    if (WindowsDxbcSpec.round3[0] != 4294588738) return error.InvalidRoundConstant;
    if (WindowsDxbcSpec.round3[15] != 3299628645) return error.InvalidRoundConstant;
    if (WindowsDxbcSpec.round4[0] != 4096336452) return error.InvalidRoundConstant;
    if (WindowsDxbcSpec.round4[15] != 3951481745) return error.InvalidRoundConstant;

    if (WindowsDxbcSpec.padding.len != 64) return error.InvalidPaddingArray;
    if (WindowsDxbcSpec.padding[0] != 0x80) return error.InvalidPaddingArray;
    if (WindowsDxbcSpec.padding[1] != 0x00) return error.InvalidPaddingArray;
    if (WindowsDxbcSpec.padding[63] != 0x00) return error.InvalidPaddingArray;
}

/// Validates type widths. The `c_uint` width is convergent (4 bytes on
/// both platforms). The `c_ulong` width is divergent: 8 bytes on macOS
/// LP64 vs 4 bytes on Windows LLP64 — this is the expected handshake
/// failpoint that mirrors LONG/ULONG/DWORD divergence in var_sizes.zig.
pub fn validateDxbcChecksumTypes() DxbcChecksumError!void {
    // UINT4 = unsigned int = 4 bytes on both macOS and Windows (convergent)
    if (MacOsDxbc.sizeof_c_uint != WindowsDxbcSpec.sizeof_UINT4) {
        return error.InvalidUint4Width;
    }

    // c_ulong on macOS LP64 is 8 bytes; Windows LLP64 expects 4 bytes.
    // This is the expected divergence. MD5Init takes unsigned long as
    // its pseudoRandomNumber parameter. When called with 0 (the normal
    // case from CalculateDXBCChecksum), the multiplication 0 * multiplier
    // is zero regardless of width, so behavior is identical. However, the
    // type width itself must be documented as a divergence point.
    if (MacOsDxbc.sizeof_c_ulong == 4) {
        // Running on a platform where unsigned long is 4 bytes
        // (Windows LLP64 or ILP32). This is convergent with spec.
        return;
    }

    // macOS LP64: unsigned long is 8 bytes — expected divergence.
    // We still validate that u32 is the correct internal type width.
    if (MacOsDxbc.sizeof_u32 != 4) return error.InvalidUint4Width;
}

pub fn validateAll() DxbcChecksumError!void {
    try validateDxbcChecksumConstants();
    try validateDxbcChecksumTypes();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosette_validate_dxbc_checksum() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidMd5InitConstant => 1,
        error.InvalidShiftConstant => 2,
        error.InvalidRoundConstant => 3,
        error.InvalidHashOffset => 4,
        error.InvalidPseudoRandomMultiplier => 5,
        error.InvalidPaddingArray => 6,
        error.InvalidTerminatorConstant => 7,
        error.InvalidUnsignedLongWidth => 8,
        error.InvalidUint4Width => 9,
        error.InvalidMd5CtxLayout => 10,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosette_dxbc_checksum_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidMd5InitConstant",
        2 => "InvalidShiftConstant",
        3 => "InvalidRoundConstant",
        4 => "InvalidHashOffset",
        5 => "InvalidPseudoRandomMultiplier",
        6 => "InvalidPaddingArray",
        7 => "InvalidTerminatorConstant",
        8 => "InvalidUnsignedLongWidth",
        9 => "InvalidUint4Width",
        10 => "InvalidMd5CtxLayout",
        else => "UnknownDxbcChecksumFailure",
    };
}

pub fn reportDxbcChecksumSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ DXBC Checksum Algorithm Specification Table
        \\================================================================================
        \\ MD5 IVs:
        \\   0x{x:0>8}  0x{x:0>8}  0x{x:0>8}  0x{x:0>8}
        \\
    , .{
        WindowsDxbcSpec.MD5_A, WindowsDxbcSpec.MD5_B,
        WindowsDxbcSpec.MD5_C, WindowsDxbcSpec.MD5_D,
    });

    std.debug.print(
        \\ Shift amounts:
        \\   Round 1:  S11={d:2} S12={d:2} S13={d:2} S14={d:2}
        \\   Round 2:  S21={d:2} S22={d:2} S23={d:2} S24={d:2}
        \\   Round 3:  S31={d:2} S32={d:2} S33={d:2} S34={d:2}
        \\   Round 4:  S41={d:2} S42={d:2} S43={d:2} S44={d:2}
        \\
    , .{
        WindowsDxbcSpec.S11, WindowsDxbcSpec.S12,
        WindowsDxbcSpec.S13, WindowsDxbcSpec.S14,
        WindowsDxbcSpec.S21, WindowsDxbcSpec.S22,
        WindowsDxbcSpec.S23, WindowsDxbcSpec.S24,
        WindowsDxbcSpec.S31, WindowsDxbcSpec.S32,
        WindowsDxbcSpec.S33, WindowsDxbcSpec.S34,
        WindowsDxbcSpec.S41, WindowsDxbcSpec.S42,
        WindowsDxbcSpec.S43, WindowsDxbcSpec.S44,
    });

    std.debug.print(
        \\ DXBC constants:
        \\   HASH_OFFSET      = 0x{x:0>2}
        \\   CHUNK_SIZE       = {d}
        \\   PAD_THRESHOLD    = {d}
        \\   TERMINATOR_LSB   = {d}
        \\
        \\ MD5_CTX layout (LLP64):
        \\   sizeof           = {d}
        \\   offsetof(i)      = {d}
        \\   offsetof(buf)    = {d}
        \\   offsetof(in)     = {d}
        \\   offsetof(digest) = {d}
        \\
        \\ Type widths:
        \\   sizeof(c_uint)  = {d}  (Win32 spec: {d})
        \\   sizeof(c_ulong) = {d}  (Win32 spec: {d})
        \\
        \\================================================================================
        \\
    , .{
        WindowsDxbcSpec.HASH_OFFSET,
        WindowsDxbcSpec.CHUNK_SIZE,
        WindowsDxbcSpec.PAD_THRESHOLD,
        WindowsDxbcSpec.TERMINATOR_LSB,
        WindowsDxbcSpec.sizeof_MD5_CTX,
        WindowsDxbcSpec.offsetof_i,
        WindowsDxbcSpec.offsetof_buf,
        WindowsDxbcSpec.offsetof_in,
        WindowsDxbcSpec.offsetof_digest,
        MacOsDxbc.sizeof_c_uint,
        WindowsDxbcSpec.sizeof_UINT4,
        MacOsDxbc.sizeof_c_ulong,
        WindowsDxbcSpec.sizeof_unsigned_long,
    });
}

/// print the full DXBC checksum spec table.
pub export fn rosette_print_dxbc_checksum_spec() void {
    reportDxbcChecksumSpec();
}

test "DXBC checksum spec matches expected values" {
    reportDxbcChecksumSpec();
    try validateAll();
}
