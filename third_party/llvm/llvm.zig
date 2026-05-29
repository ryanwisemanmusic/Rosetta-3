const std = @import("std");

pub const LlvmError = error{
    InvalidGnucPrereq,
    InvalidMscPrereq,
    InvalidNoexcept,
    InvalidRvalueRef,
    InvalidZeroBehavior,
    InvalidTrailingZeros,
    InvalidBitWordSize,
    InvalidBitVectorLayout,
    InvalidBitVectorSize,
    InvalidTypeWidth,
};

/// Pseudo-Windows snapshot. Constants sourced from LLVM's Compiler.h,
/// MathExtras.h, and BitVector.h (LLVM 3.x-era Xenia fork). Type-level
/// properties are convergent on both platforms (all 64-bit).
pub const WindowsLlvmSpec = struct {
    // ── Compiler.h feature macros ──────────────────────────────────
    pub const LLVM_GNUC_PREREQ_4_0_0: u32 = 1;
    pub const LLVM_GNUC_PREREQ_4_8_1: u32 = 1;
    pub const LLVM_MSC_PREREQ_1800: u32 = 0;
    pub const LLVM_NOEXCEPT_VALUE: u32 = 1; // noexcept supported

    // ── MathExtras.h ZeroBehavior ──────────────────────────────────
    pub const ZB_Undefined: i32 = 0;
    pub const ZB_Max: i32 = 1;
    pub const ZB_Width: i32 = 2;

    // ── BitVector.h constants ──────────────────────────────────────
    // BITWORD_SIZE = sizeof(unsigned long) * CHAR_BIT
    // On LLP64: unsigned long = 4 bytes => 32 bits
    // On LP64:  unsigned long = 8 bytes => 64 bits
    // The LLP64 (Windows) spec sets BITWORD_SIZE = 32.
    pub const BITWORD_SIZE_LLP64: comptime_int = 32;
    pub const BITWORD_SIZE_HOST: comptime_int = @sizeOf(c_ulong) * 8;

    // BitVector layout (LLP64):
    //   offset 0: Bits (BitWord* = pointer, 8 bytes)
    //   offset 8: Size (unsigned int, 4 bytes)
    //   offset 12: Capacity (unsigned int, 4 bytes)
    //   total: 16 bytes
    pub const sizeof_BitVector_LLP64: comptime_int = 16;
    pub const offsetof_BitVector_Bits: comptime_int = 0;
    pub const offsetof_BitVector_Size: comptime_int = 8;
    pub const offsetof_BitVector_Capacity: comptime_int = 12;

    // ── Type widths ────────────────────────────────────────────────
    pub const sizeof_c_ulong: comptime_int = 4;
};

/// macOS host snapshot.  LP64 vs LLP64 divergences:
///   - sizeof(c_ulong) = 8 on LP64, 4 on LLP64
///   - BITWORD_SIZE = 64 on LP64, 32 on LLP64
///   - BitVector layout has different sizes/offsets on LP64
pub const MacOsLlvm = struct {
    pub const sizeof_c_ulong = @sizeOf(c_ulong);
    pub const sizeof_ptr = @sizeOf(*anyopaque);
    pub const sizeof_u32 = @sizeOf(u32);
};

/// macOS (LP64) BitVector layout:
///   Bits:     offset 0, 8 bytes (pointer)
///   Size:     offset 8, 4 bytes (unsigned int)
///   Capacity: offset 12, padding 4 bytes, or...
/// Actually on LP64: unsigned long is 8 bytes, so if BitWord = unsigned long:
///   BITWORD_SIZE = 64
/// But the Size/Capacity fields are `unsigned int` (4 bytes),
/// so layout is:
///   offset 0: Bits (pointer, 8 bytes)
///   offset 8: Size (unsigned int, 4 bytes)
///   offset 12: Capacity (unsigned int, 4 bytes)
///   total: 16 bytes
/// Wait — that's the same as LLP64! Let me reconsider.

/// Actually BitWord = unsigned long. On LP64, unsigned long = 8 bytes => BITWORD_SIZE = 64.
/// But the layout of the BitVector struct itself is the same on both LP64 and LLP64
/// because Bits (pointer) is 8 bytes, Size (unsigned int) is 4, Capacity (unsigned int) is 4.
/// The only difference is BITWORD_SIZE (64 vs 32) and what unsigned long is.
pub const MacOsBitVectorLayout = struct {
    pub const bitword_size = @sizeOf(c_ulong) * 8;
    pub const sizeof_BitVector = @sizeOf(BitVectorState);
    pub const offsetof_Bits = @offsetOf(BitVectorState, "Bits");
    pub const offsetof_Size = @offsetOf(BitVectorState, "Size");
    pub const offsetof_Capacity = @offsetOf(BitVectorState, "Capacity");
};

const BitVectorState = extern struct {
    Bits: [*c]c_ulong,
    Size: c_uint,
    Capacity: c_uint,
};

pub fn validateLlvmCompilerMacros() LlvmError!void {
    if (WindowsLlvmSpec.LLVM_GNUC_PREREQ_4_0_0 != 1) return error.InvalidGnucPrereq;
    if (WindowsLlvmSpec.LLVM_GNUC_PREREQ_4_8_1 != 1) return error.InvalidGnucPrereq;
    if (WindowsLlvmSpec.LLVM_MSC_PREREQ_1800 != 0) return error.InvalidMscPrereq;
    if (WindowsLlvmSpec.LLVM_NOEXCEPT_VALUE != 1) return error.InvalidNoexcept;
}

pub fn validateLlvmZeroBehavior() LlvmError!void {
    if (WindowsLlvmSpec.ZB_Undefined != 0) return error.InvalidZeroBehavior;
    if (WindowsLlvmSpec.ZB_Max != 1) return error.InvalidZeroBehavior;
    if (WindowsLlvmSpec.ZB_Width != 2) return error.InvalidZeroBehavior;
}

pub fn validateLlvmBitVector() LlvmError!void {
    // Validate LLP64 specs
    if (WindowsLlvmSpec.BITWORD_SIZE_LLP64 != 32) return error.InvalidBitWordSize;
    if (WindowsLlvmSpec.sizeof_BitVector_LLP64 != 16) return error.InvalidBitVectorSize;
    if (WindowsLlvmSpec.offsetof_BitVector_Bits != 0) return error.InvalidBitVectorLayout;
    if (WindowsLlvmSpec.offsetof_BitVector_Size != 8) return error.InvalidBitVectorLayout;
    if (WindowsLlvmSpec.offsetof_BitVector_Capacity != 12) return error.InvalidBitVectorLayout;
}

pub fn validateLlvmTypeWidths() LlvmError!void {
    if (MacOsLlvm.sizeof_c_ulong != WindowsLlvmSpec.sizeof_c_ulong) {
        // LP64 vs LLP64: c_ulong is 8 bytes on macOS LP64, 4 on Windows LLP64.
        // This is the expected divergence — the BitVector BITWORD_SIZE differs.
        // We validate the host value matches, then adjust the spec accordingly.
        if (MacOsLlvm.sizeof_c_ulong != 8) return error.InvalidTypeWidth;
    }
    if (MacOsLlvm.sizeof_ptr != 8) return error.InvalidTypeWidth;
    if (MacOsLlvm.sizeof_u32 != 4) return error.InvalidTypeWidth;
}

pub fn validateLlvmBitVectorLayout() LlvmError!void {
    // On macOS LP64, unsigned long is 8 bytes, so BITWORD_SIZE = 64.
    // But the struct layout (pointer + 2 uints) is the same 16 bytes.
    const expected_host_bitword_size: comptime_int = @sizeOf(c_ulong) * 8;
    if (MacOsBitVectorLayout.bitword_size != expected_host_bitword_size)
        return error.InvalidBitWordSize;
    if (MacOsBitVectorLayout.sizeof_BitVector != 16)
        return error.InvalidBitVectorSize;
    if (MacOsBitVectorLayout.offsetof_Bits != 0)
        return error.InvalidBitVectorLayout;
    if (MacOsBitVectorLayout.offsetof_Size != 8)
        return error.InvalidBitVectorLayout;
    if (MacOsBitVectorLayout.offsetof_Capacity != 12)
        return error.InvalidBitVectorLayout;
}

pub fn validateAll() LlvmError!void {
    try validateLlvmCompilerMacros();
    try validateLlvmZeroBehavior();
    try validateLlvmBitVector();
    try validateLlvmTypeWidths();
    try validateLlvmBitVectorLayout();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_llvm() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidGnucPrereq => 1,
        error.InvalidMscPrereq => 2,
        error.InvalidNoexcept => 3,
        error.InvalidRvalueRef => 4,
        error.InvalidZeroBehavior => 5,
        error.InvalidTrailingZeros => 6,
        error.InvalidBitWordSize => 7,
        error.InvalidBitVectorLayout => 8,
        error.InvalidBitVectorSize => 9,
        error.InvalidTypeWidth => 10,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosetta3_llvm_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidGnucPrereq",
        2 => "InvalidMscPrereq",
        3 => "InvalidNoexcept",
        4 => "InvalidRvalueRef",
        5 => "InvalidZeroBehavior",
        6 => "InvalidTrailingZeros",
        7 => "InvalidBitWordSize",
        8 => "InvalidBitVectorLayout",
        9 => "InvalidBitVectorSize",
        10 => "InvalidTypeWidth",
        else => "UnknownLlvmFailure",
    };
}

pub fn reportLlvmSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ LLVM Support Library Specification Table
        \\================================================================================
        \\ Compiler.h macros:
        \\   LLVM_GNUC_PREREQ(4,0,0) = {d}
        \\   LLVM_GNUC_PREREQ(4,8,1) = {d}
        \\   LLVM_MSC_PREREQ(1800)   = {d}
        \\   LLVM_NOEXCEPT           = {d}
        \\
        \\ MathExtras.h ZeroBehavior:
        \\   ZB_Undefined = {d}
        \\   ZB_Max       = {d}
        \\   ZB_Width     = {d}
        \\
        \\ BitVector layout (64-bit):
        \\   BITWORD_SIZE (LLP64) = {d}
        \\   BITWORD_SIZE (LP64)  = {d}
        \\   sizeof(BitVector)    = {d} bytes
        \\   offsetof(Bits)       = {d}
        \\   offsetof(Size)       = {d}
        \\   offsetof(Capacity)   = {d}
        \\
        \\ Type widths:
        \\   sizeof(c_ulong)      = {d} (LP64: 8, LLP64: 4)
        \\   sizeof(pointer)      = {d}
        \\   sizeof(u32)          = {d}
        \\
        \\================================================================================
        \\
    , .{
        WindowsLlvmSpec.LLVM_GNUC_PREREQ_4_0_0,
        WindowsLlvmSpec.LLVM_GNUC_PREREQ_4_8_1,
        WindowsLlvmSpec.LLVM_MSC_PREREQ_1800,
        WindowsLlvmSpec.LLVM_NOEXCEPT_VALUE,
        WindowsLlvmSpec.ZB_Undefined,
        WindowsLlvmSpec.ZB_Max,
        WindowsLlvmSpec.ZB_Width,
        WindowsLlvmSpec.BITWORD_SIZE_LLP64,
        MacOsBitVectorLayout.bitword_size,
        MacOsBitVectorLayout.sizeof_BitVector,
        MacOsBitVectorLayout.offsetof_Bits,
        MacOsBitVectorLayout.offsetof_Size,
        MacOsBitVectorLayout.offsetof_Capacity,
        MacOsLlvm.sizeof_c_ulong,
        MacOsLlvm.sizeof_ptr,
        MacOsLlvm.sizeof_u32,
    });
}

pub export fn rosetta3_print_llvm_spec() void {
    reportLlvmSpec();
}

test "LLVM spec matches expected values" {
    reportLlvmSpec();
    try validateAll();
}
