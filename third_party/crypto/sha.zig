const std = @import("std");

pub const ShaAbiError = error{
    InvalidSha1InitDigest,
    InvalidSha1BlockSize,
    InvalidSha1DigestSize,
    InvalidSha1Layout,
    InvalidSha256InitDigest,
    InvalidSha256BlockSize,
    InvalidSha256DigestSize,
    InvalidSha256Layout,
    InvalidTypeWidth,
};

/// Pseudo-Windows snapshot. Constants and layouts sourced from
/// TinySHA1.hpp and sha256.h (LLP64 assumptions; convergent on macOS).
pub const WindowsShaSpec = struct {
    // SHA1 initial digest constants
    pub const SHA1_INIT = [5]u32{
        0x67452301,
        0xefcdab89,
        0x98badcfe,
        0x10325476,
        0xc3d2e1f0,
    };
    pub const SHA1_BLOCK_BYTES: comptime_int = 64;
    pub const SHA1_DIGEST_WORDS: comptime_int = 5;
    pub const SHA1_DIGEST_BYTES: comptime_int = 20;

    // SHA256 initial digest constants
    pub const SHA256_INIT = [8]u32{
        0x6a09e667,
        0xbb67ae85,
        0x3c6ef372,
        0xa54ff53a,
        0x510e527f,
        0x9b05688c,
        0x1f83d9ab,
        0x5be0cd19,
    };
    pub const SHA256_BLOCK_BYTES: comptime_int = 64;
    pub const SHA256_DIGEST_WORDS: comptime_int = 8;
    pub const SHA256_DIGEST_BYTES: comptime_int = 32;

    pub const sizeof_uint32: comptime_int = 4;
    pub const sizeof_uint64: comptime_int = 8;
    pub const sizeof_size_t: comptime_int = 8;

    // SHA1 class layout (TinySHA1.hpp)
    pub const sizeof_SHA1: comptime_int = 104;
    pub const offsetof_sha1_digest: comptime_int = 0;
    pub const offsetof_sha1_block: comptime_int = 20;
    pub const offsetof_sha1_block_index: comptime_int = 88;
    pub const offsetof_sha1_byte_count: comptime_int = 96;

    // SHA256 class layout (sha256.h)
    pub const sizeof_SHA256: comptime_int = 112;
    pub const offsetof_sha256_num_bytes: comptime_int = 0;
    pub const offsetof_sha256_buffer_size: comptime_int = 8;
    pub const offsetof_sha256_buffer: comptime_int = 16;
    pub const offsetof_sha256_hash: comptime_int = 80;
};

/// macOS host snapshot. These should match the Windows spec.
pub const MacOsSha = struct {
    pub const sizeof_u32 = @sizeOf(u32);
    pub const sizeof_u64 = @sizeOf(u64);
    pub const sizeof_size_t = @sizeOf(usize);
};

const Sha1State = extern struct {
    m_digest: [5]u32,
    m_block: [64]u8,
    m_blockByteIndex: usize,
    m_byteCount: usize,
};

const Sha256State = extern struct {
    m_numBytes: u64,
    m_bufferSize: usize,
    m_buffer: [64]u8,
    m_hash: [8]u32,
};

pub fn validateShaConstants() ShaAbiError!void {
    if (WindowsShaSpec.SHA1_INIT[0] != 0x67452301) return error.InvalidSha1InitDigest;
    if (WindowsShaSpec.SHA1_INIT[4] != 0xc3d2e1f0) return error.InvalidSha1InitDigest;
    if (WindowsShaSpec.SHA1_BLOCK_BYTES != 64) return error.InvalidSha1BlockSize;
    if (WindowsShaSpec.SHA1_DIGEST_WORDS != 5) return error.InvalidSha1DigestSize;
    if (WindowsShaSpec.SHA1_DIGEST_BYTES != 20) return error.InvalidSha1DigestSize;

    if (WindowsShaSpec.SHA256_INIT[0] != 0x6a09e667) return error.InvalidSha256InitDigest;
    if (WindowsShaSpec.SHA256_INIT[7] != 0x5be0cd19) return error.InvalidSha256InitDigest;
    if (WindowsShaSpec.SHA256_BLOCK_BYTES != 64) return error.InvalidSha256BlockSize;
    if (WindowsShaSpec.SHA256_DIGEST_WORDS != 8) return error.InvalidSha256DigestSize;
    if (WindowsShaSpec.SHA256_DIGEST_BYTES != 32) return error.InvalidSha256DigestSize;
}

pub fn validateShaTypeWidths() ShaAbiError!void {
    if (MacOsSha.sizeof_u32 != WindowsShaSpec.sizeof_uint32) return error.InvalidTypeWidth;
    if (MacOsSha.sizeof_u64 != WindowsShaSpec.sizeof_uint64) return error.InvalidTypeWidth;
    if (MacOsSha.sizeof_size_t != WindowsShaSpec.sizeof_size_t) return error.InvalidTypeWidth;
}

pub fn validateShaLayouts() ShaAbiError!void {
    if (@sizeOf(Sha1State) != WindowsShaSpec.sizeof_SHA1) return error.InvalidSha1Layout;
    if (@offsetOf(Sha1State, "m_digest") != WindowsShaSpec.offsetof_sha1_digest)
        return error.InvalidSha1Layout;
    if (@offsetOf(Sha1State, "m_block") != WindowsShaSpec.offsetof_sha1_block)
        return error.InvalidSha1Layout;
    if (@offsetOf(Sha1State, "m_blockByteIndex") != WindowsShaSpec.offsetof_sha1_block_index)
        return error.InvalidSha1Layout;
    if (@offsetOf(Sha1State, "m_byteCount") != WindowsShaSpec.offsetof_sha1_byte_count)
        return error.InvalidSha1Layout;

    if (@sizeOf(Sha256State) != WindowsShaSpec.sizeof_SHA256) return error.InvalidSha256Layout;
    if (@offsetOf(Sha256State, "m_numBytes") != WindowsShaSpec.offsetof_sha256_num_bytes)
        return error.InvalidSha256Layout;
    if (@offsetOf(Sha256State, "m_bufferSize") != WindowsShaSpec.offsetof_sha256_buffer_size)
        return error.InvalidSha256Layout;
    if (@offsetOf(Sha256State, "m_buffer") != WindowsShaSpec.offsetof_sha256_buffer)
        return error.InvalidSha256Layout;
    if (@offsetOf(Sha256State, "m_hash") != WindowsShaSpec.offsetof_sha256_hash)
        return error.InvalidSha256Layout;
}

pub fn validateAll() ShaAbiError!void {
    try validateShaConstants();
    try validateShaTypeWidths();
    try validateShaLayouts();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosette_validate_sha() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidSha1InitDigest => 1,
        error.InvalidSha1BlockSize => 2,
        error.InvalidSha1DigestSize => 3,
        error.InvalidSha1Layout => 4,
        error.InvalidSha256InitDigest => 5,
        error.InvalidSha256BlockSize => 6,
        error.InvalidSha256DigestSize => 7,
        error.InvalidSha256Layout => 8,
        error.InvalidTypeWidth => 9,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosette_sha_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidSha1InitDigest",
        2 => "InvalidSha1BlockSize",
        3 => "InvalidSha1DigestSize",
        4 => "InvalidSha1Layout",
        5 => "InvalidSha256InitDigest",
        6 => "InvalidSha256BlockSize",
        7 => "InvalidSha256DigestSize",
        8 => "InvalidSha256Layout",
        9 => "InvalidTypeWidth",
        else => "UnknownShaFailure",
    };
}

pub fn reportShaSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ SHA ABI Specification Table
        \\================================================================================
        \\ SHA1:
        \\   init digest = 0x{x:0>8} 0x{x:0>8} 0x{x:0>8} 0x{x:0>8} 0x{x:0>8}
        \\   block bytes = {d}
        \\   digest bytes = {d}
        \\
        \\ SHA256:
        \\   init digest = 0x{x:0>8} 0x{x:0>8} 0x{x:0>8} 0x{x:0>8}
        \\                 0x{x:0>8} 0x{x:0>8} 0x{x:0>8} 0x{x:0>8}
        \\   block bytes = {d}
        \\   digest bytes = {d}
        \\
        \\ Layouts (LLP64):
        \\   sizeof(SHA1)   = {d}
        \\   sizeof(SHA256) = {d}
        \\
    , .{
        WindowsShaSpec.SHA1_INIT[0],        WindowsShaSpec.SHA1_INIT[1],
        WindowsShaSpec.SHA1_INIT[2],        WindowsShaSpec.SHA1_INIT[3],
        WindowsShaSpec.SHA1_INIT[4],        WindowsShaSpec.SHA1_BLOCK_BYTES,
        WindowsShaSpec.SHA1_DIGEST_BYTES,   WindowsShaSpec.SHA256_INIT[0],
        WindowsShaSpec.SHA256_INIT[1],      WindowsShaSpec.SHA256_INIT[2],
        WindowsShaSpec.SHA256_INIT[3],      WindowsShaSpec.SHA256_INIT[4],
        WindowsShaSpec.SHA256_INIT[5],      WindowsShaSpec.SHA256_INIT[6],
        WindowsShaSpec.SHA256_INIT[7],      WindowsShaSpec.SHA256_BLOCK_BYTES,
        WindowsShaSpec.SHA256_DIGEST_BYTES, WindowsShaSpec.sizeof_SHA1,
        WindowsShaSpec.sizeof_SHA256,
    });
}

/// print the full SHA ABI spec table.
pub export fn rosette_print_sha_spec() void {
    reportShaSpec();
}

test "SHA ABI spec matches expected values" {
    reportShaSpec();
    try validateAll();
}
