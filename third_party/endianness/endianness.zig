const std = @import("std");
const builtin = @import("builtin");

pub const EndiannessError = error{
    InvalidTypeWidth,
    InvalidEndiannessDetection,
    InvalidByteSwap16,
    InvalidByteSwap32,
    InvalidByteSwap64,
    InvalidBigEndianRoundtrip,
    InvalidLoadStore,
};

/// Pseudo-Windows snapshot. All values sourced from endianness.h which
/// follows the Win32 x64 LLP64 convention. Since endianness operates on
/// fixed-width types (uint16_t/uint32_t/uint64_t), there is no LP64 vs
/// LLP64 divergence here — every check is convergent on both platforms.
pub const WindowsEndianSpec = struct {
    pub const sizeof_uint16: comptime_int = 2;
    pub const sizeof_uint32: comptime_int = 4;
    pub const sizeof_uint64: comptime_int = 8;

    pub const is_little_endian: bool = true;

    pub const byte_swap_16_input: u16 = 0x1234;
    pub const byte_swap_16_expected: u16 = 0x3412;

    pub const byte_swap_32_input: u32 = 0x12345678;
    pub const byte_swap_32_expected: u32 = 0x78563412;

    pub const byte_swap_64_input: u64 = 0x123456789ABCDEF0;
    pub const byte_swap_64_expected: u64 = 0xF0DEBC9A78563412;

    pub const be_roundtrip_input: u32 = 0x12345678;
    pub const be_stored_bytes = [4]u8{ 0x12, 0x34, 0x56, 0x78 };

    pub const mask_b0: u32 = 0x000000FF;
    pub const mask_b1: u32 = 0x0000FF00;
    pub const mask_b2: u32 = 0x00FF0000;
    pub const mask_b3: u32 = 0xFF000000;

    pub const mask64_b0: u64 = 0x00000000000000FF;
    pub const mask64_b1: u64 = 0x000000000000FF00;
    pub const mask64_b2: u64 = 0x0000000000FF0000;
    pub const mask64_b3: u64 = 0x00000000FF000000;
    pub const mask64_b4: u64 = 0x000000FF00000000;
    pub const mask64_b5: u64 = 0x0000FF0000000000;
    pub const mask64_b6: u64 = 0x00FF000000000000;
    pub const mask64_b7: u64 = 0xFF00000000000000;
};

/// macOS host snapshot. Since fixed-width types are used throughout,
/// all values are convergent with the Windows spec. Both macOS ARM64
/// and Windows x64 are little-endian, and u16/u32/u64 have identical
/// sizes on both platforms.
pub const MacOsEndian = struct {
    pub const sizeof_uint16 = @sizeOf(u16);
    pub const sizeof_uint32 = @sizeOf(u32);
    pub const sizeof_uint64 = @sizeOf(u64);
    pub const endianness = builtin.cpu.arch.endian();
};

pub fn validateEndiannessTypes() EndiannessError!void {
    if (MacOsEndian.sizeof_uint16 != WindowsEndianSpec.sizeof_uint16)
        return error.InvalidTypeWidth;
    if (MacOsEndian.sizeof_uint32 != WindowsEndianSpec.sizeof_uint32)
        return error.InvalidTypeWidth;
    if (MacOsEndian.sizeof_uint64 != WindowsEndianSpec.sizeof_uint64)
        return error.InvalidTypeWidth;
}

pub fn validateEndiannessDetection() EndiannessError!void {
    if (MacOsEndian.endianness != .little)
        return error.InvalidEndiannessDetection;
}

/// Validates byte swap correctness for 16, 32, and 64-bit values.
/// Tests the same operation implemented in endianness.h byte_swap<T>().
pub fn validateByteSwapOperations() EndiannessError!void {
    const input16: u16 = WindowsEndianSpec.byte_swap_16_input;
    const result16 = @byteSwap(input16);
    if (result16 != WindowsEndianSpec.byte_swap_16_expected)
        return error.InvalidByteSwap16;

    const input32: u32 = WindowsEndianSpec.byte_swap_32_input;
    const result32 = @byteSwap(input32);
    if (result32 != WindowsEndianSpec.byte_swap_32_expected)
        return error.InvalidByteSwap32;

    const input64: u64 = WindowsEndianSpec.byte_swap_64_input;
    const result64 = @byteSwap(input64);
    if (result64 != WindowsEndianSpec.byte_swap_64_expected)
        return error.InvalidByteSwap64;
}

/// Validates BigEndian load/store roundtrip. This mirrors the behavior
/// of xe::endian::BigEndian<T>::store() and BigEndian<T>::load().
pub fn validateBigEndianRoundtrip() EndiannessError!void {
    const original: u32 = WindowsEndianSpec.be_roundtrip_input;

    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, original, .big);

    if (!std.mem.eql(u8, &buf, &WindowsEndianSpec.be_stored_bytes))
        return error.InvalidLoadStore;

    const loaded = std.mem.readInt(u32, &buf, .big);
    if (loaded != original)
        return error.InvalidBigEndianRoundtrip;
}

pub fn validateAll() EndiannessError!void {
    try validateEndiannessTypes();
    try validateEndiannessDetection();
    try validateByteSwapOperations();
    try validateBigEndianRoundtrip();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_endianness() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidTypeWidth => 1,
        error.InvalidEndiannessDetection => 2,
        error.InvalidByteSwap16 => 3,
        error.InvalidByteSwap32 => 4,
        error.InvalidByteSwap64 => 5,
        error.InvalidBigEndianRoundtrip => 6,
        error.InvalidLoadStore => 7,
    };
    return 0;
}

/// returns a null-terminated string for a failure code.
pub export fn rosetta3_endianness_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidTypeWidth",
        2 => "InvalidEndiannessDetection",
        3 => "InvalidByteSwap16",
        4 => "InvalidByteSwap32",
        5 => "InvalidByteSwap64",
        6 => "InvalidBigEndianRoundtrip",
        7 => "InvalidLoadStore",
        else => "UnknownEndiannessFailure",
    };
}

pub fn reportEndiannessSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ Endianness Specification Table
        \\================================================================================
        \\ Type widths:
        \\   sizeof(uint16) = {d}  (Win32 spec: {d})
        \\   sizeof(uint32) = {d}  (Win32 spec: {d})
        \\   sizeof(uint64) = {d}  (Win32 spec: {d})
        \\
        \\ Endianness:
        \\   Host endianness = {s}  (Win32 spec: little)
        \\
    , .{
        MacOsEndian.sizeof_uint16,        WindowsEndianSpec.sizeof_uint16,
        MacOsEndian.sizeof_uint32,        WindowsEndianSpec.sizeof_uint32,
        MacOsEndian.sizeof_uint64,        WindowsEndianSpec.sizeof_uint64,
        @tagName(MacOsEndian.endianness),
    });

    std.debug.print(
        \\ Byte swap test vectors:
        \\   @byteSwap(0x{x:0>4})     = 0x{x:0>4}     (expected: 0x{x:0>4})
        \\   @byteSwap(0x{x:0>8}) = 0x{x:0>8} (expected: 0x{x:0>8})
        \\   @byteSwap(0x{x:0>16}) = 0x{x:0>16} (expected: 0x{x:0>16})
        \\
        \\ BigEndian roundtrip:
        \\   Original          = 0x{x:0>8}
        \\   Big-endian bytes  = 0x{x:0>2} 0x{x:0>2} 0x{x:0>2} 0x{x:0>2}
        \\   Roundtrip result  = 0x{x:0>8}
        \\
        \\================================================================================
        \\
    , .{
        WindowsEndianSpec.byte_swap_16_input,
        @byteSwap(WindowsEndianSpec.byte_swap_16_input),
        WindowsEndianSpec.byte_swap_16_expected,
        WindowsEndianSpec.byte_swap_32_input,
        @byteSwap(WindowsEndianSpec.byte_swap_32_input),
        WindowsEndianSpec.byte_swap_32_expected,
        WindowsEndianSpec.byte_swap_64_input,
        @byteSwap(WindowsEndianSpec.byte_swap_64_input),
        WindowsEndianSpec.byte_swap_64_expected,
        WindowsEndianSpec.be_roundtrip_input,
        WindowsEndianSpec.be_stored_bytes[0],
        WindowsEndianSpec.be_stored_bytes[1],
        WindowsEndianSpec.be_stored_bytes[2],
        WindowsEndianSpec.be_stored_bytes[3],
        std.mem.readInt(
            u32,
            &WindowsEndianSpec.be_stored_bytes,
            .big,
        ),
    });
}

pub export fn rosetta3_print_endianness_spec() void {
    reportEndiannessSpec();
}

test "Endianness spec matches expected values" {
    reportEndiannessSpec();
    try validateAll();
}
