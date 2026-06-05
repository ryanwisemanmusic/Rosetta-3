const std = @import("std");

const windows_base = @import("windows_base");
const behavior_api = @import("behavior_api");
const behavior_mod = @import("behavior");

const atomic_abi = @import("atomic");
const dbghelp_abi = @import("dbghelp");
const dds_abi = @import("dds");
const fiber_abi = @import("fiber");
const intrin_abi = @import("intrin");
const file_abi = @import("file");
const gdi_abi = @import("gdi");
const io_abi = @import("io");
const process_abi = @import("process");
const synchapi_abi = @import("synchapi");
const threads_abi = @import("threads");
const window_abi = @import("window");
const console_window_abi = @import("console_window_abi");
const x86_asm = @import("x86_asm");

comptime {
    _ = x86_asm;
}

pub const WindowsAbiError = error{
    // Constant ranges (MINCHAR/MAXCHAR/... macros).
    InvalidCharRange,
    InvalidShortRange,
    InvalidLongRange,
    InvalidByteRange,
    InvalidWordRange,
    InvalidDwordRange,
    // Scalar widths (typedefs that get used as immediate operands or as
    // register slots in translated assembly).
    InvalidCharWidth,
    InvalidShortWidth,
    InvalidIntWidth,
    InvalidLongWidth,
    InvalidLongLongWidth,
    InvalidFloatWidth,
    InvalidWCharWidth,
    InvalidBoolWidth,
    InvalidByteWidth,
    InvalidWordWidth,
    InvalidDwordWidth,
    InvalidInt32Width,
    InvalidInt64Width,
    InvalidDword64Width,
    InvalidUlong64Width,
    // Pointer-derived widths (LONG_PTR / INT_PTR / ULONG_PTR / SIZE_T / ...).
    InvalidPointerWidth,
    // Struct sizes (offsets baked into translated mov/lea immediates).
    InvalidOverlappedLayout,
    InvalidSecurityAttributesLayout,
    InvalidLargeIntegerLayout,
    InvalidFileTimeLayout,
    InvalidGuidLayout,
    InvalidBytePackingMacro,
    InvalidBitExtractionMacro,
    InvalidHresultMacro,
};

/// macOS host snapshot. Values derived from the macOS C runtime and Zig's
/// native types. For types whose width is LP64 vs LLP64 dependent (LONG,
/// DWORD, WCHAR), this records what the *native macOS* type would be — not
/// what the shim is supposed to be. The divergence is intentional and is
/// what the three-way checks below let you actually see.
pub const MacOsAbi = struct {
    pub const MINCHAR = bitPatternOfMin(i8);
    pub const MAXCHAR = std.math.maxInt(i8);
    pub const MINSHORT = bitPatternOfMin(i16);
    pub const MAXSHORT = std.math.maxInt(i16);
    pub const MINLONG = bitPatternOfMin(i32);
    pub const MAXLONG = std.math.maxInt(i32);
    pub const MAXBYTE = std.math.maxInt(u8);
    pub const MAXWORD = std.math.maxInt(u16);
    pub const MAXDWORD = std.math.maxInt(u32);

    // Scalar widths (host C types).
    pub const sizeof_CHAR = @sizeOf(c_char);
    pub const sizeof_SHORT = @sizeOf(c_short);
    pub const sizeof_INT = @sizeOf(c_int);
    pub const sizeof_LONG = @sizeOf(c_long); // LP64: 8 on macOS
    pub const sizeof_LONGLONG = @sizeOf(c_longlong);
    pub const sizeof_FLOAT = @sizeOf(f32);
    pub const sizeof_WCHAR = 4; // macOS native wchar_t is 32-bit
    pub const sizeof_BOOL = @sizeOf(c_int);
    pub const sizeof_BYTE = @sizeOf(u8);
    pub const sizeof_WORD = @sizeOf(u16);
    pub const sizeof_DWORD = @sizeOf(c_ulong); // LP64: 8 on macOS (native ulong)
    pub const sizeof_INT32 = @sizeOf(i32);
    pub const sizeof_INT64 = @sizeOf(i64);
    pub const sizeof_DWORD64 = @sizeOf(u64);
    pub const sizeof_ULONG64 = @sizeOf(u64);
    pub const sizeof_LONG_PTR = @sizeOf(isize);
    pub const sizeof_INT_PTR = @sizeOf(isize);
    pub const sizeof_ULONG_PTR = @sizeOf(usize);
    pub const sizeof_SIZE_T = @sizeOf(usize);
};

/// Pseudo-Windows snapshot. Values are hardcoded from the Win32 x64 LLP64
/// specification, independent of host types and independent of what the
/// translated windows_base.h actually declared. With three independent
/// corners (header, host, spec) every assertion can be a three-way check
/// where convergence is required, or shim-vs-spec only where macOS native
/// is allowed to differ by design.
pub const WindowsAbi = struct {
    pub const MINCHAR: comptime_int = 0x80;
    pub const MAXCHAR: comptime_int = 0x7f;
    pub const MINSHORT: comptime_int = 0x8000;
    pub const MAXSHORT: comptime_int = 0x7fff;
    pub const MINLONG: comptime_int = 0x80000000;
    pub const MAXLONG: comptime_int = 0x7fffffff;
    pub const MAXBYTE: comptime_int = 0xff;
    pub const MAXWORD: comptime_int = 0xffff;
    pub const MAXDWORD: comptime_int = 0xffffffff;

    // Win32 x64 LLP64: int = 4, long = 4, long long = 8, pointer = 8,
    // wchar_t = 2. Floats follow IEEE-754.
    pub const sizeof_CHAR: comptime_int = 1;
    pub const sizeof_SHORT: comptime_int = 2;
    pub const sizeof_INT: comptime_int = 4;
    pub const sizeof_LONG: comptime_int = 4;
    pub const sizeof_LONGLONG: comptime_int = 8;
    pub const sizeof_FLOAT: comptime_int = 4;
    pub const sizeof_WCHAR: comptime_int = 2;
    pub const sizeof_BOOL: comptime_int = 4;
    pub const sizeof_BYTE: comptime_int = 1;
    pub const sizeof_WORD: comptime_int = 2;
    pub const sizeof_DWORD: comptime_int = 4;
    pub const sizeof_INT32: comptime_int = 4;
    pub const sizeof_INT64: comptime_int = 8;
    pub const sizeof_DWORD64: comptime_int = 8;
    pub const sizeof_ULONG64: comptime_int = 8;
    pub const sizeof_LONG_PTR: comptime_int = 8;
    pub const sizeof_INT_PTR: comptime_int = 8;
    pub const sizeof_ULONG_PTR: comptime_int = 8;
    pub const sizeof_SIZE_T: comptime_int = 8;

    // Struct sizes from the Win32 x64 ABI (natural alignment, no packing).
    //   LARGE_INTEGER / ULARGE_INTEGER:   8  (i64-aligned union)
    //   FILETIME:                          8  (two DWORDs)
    //   OVERLAPPED:                       32  (ULONG_PTR x2 + 8-byte union + HANDLE)
    //   SECURITY_ATTRIBUTES:              24  (DWORD + pad + LPVOID + BOOL + pad)
    //   GUID:                             16  (DWORD + WORD + WORD + 8 bytes)
    pub const sizeof_LARGE_INTEGER: comptime_int = 8;
    pub const sizeof_ULARGE_INTEGER: comptime_int = 8;
    pub const sizeof_FILETIME: comptime_int = 8;
    pub const sizeof_OVERLAPPED: comptime_int = 32;
    pub const sizeof_SECURITY_ATTRIBUTES: comptime_int = 24;
    pub const sizeof_GUID: comptime_int = 16;
};

fn bitPatternOfMin(comptime T: type) comptime_int {
    const U = std.meta.Int(.unsigned, @bitSizeOf(T));
    const min_val: T = std.math.minInt(T);
    const bits: U = @bitCast(min_val);
    return bits;
}

pub fn validateWindowsConstants() WindowsAbiError!void {
    if (windows_base.MINCHAR != MacOsAbi.MINCHAR or
        windows_base.MINCHAR != WindowsAbi.MINCHAR) return error.InvalidCharRange;
    if (windows_base.MAXCHAR != MacOsAbi.MAXCHAR or
        windows_base.MAXCHAR != WindowsAbi.MAXCHAR) return error.InvalidCharRange;

    if (windows_base.MINSHORT != MacOsAbi.MINSHORT or
        windows_base.MINSHORT != WindowsAbi.MINSHORT) return error.InvalidShortRange;
    if (windows_base.MAXSHORT != MacOsAbi.MAXSHORT or
        windows_base.MAXSHORT != WindowsAbi.MAXSHORT) return error.InvalidShortRange;

    if (windows_base.MINLONG != MacOsAbi.MINLONG or
        windows_base.MINLONG != WindowsAbi.MINLONG) return error.InvalidLongRange;
    if (windows_base.MAXLONG != MacOsAbi.MAXLONG or
        windows_base.MAXLONG != WindowsAbi.MAXLONG) return error.InvalidLongRange;

    if (windows_base.MAXBYTE != MacOsAbi.MAXBYTE or
        windows_base.MAXBYTE != WindowsAbi.MAXBYTE) return error.InvalidByteRange;
    if (windows_base.MAXWORD != MacOsAbi.MAXWORD or
        windows_base.MAXWORD != WindowsAbi.MAXWORD) return error.InvalidWordRange;
    if (windows_base.MAXDWORD != MacOsAbi.MAXDWORD or
        windows_base.MAXDWORD != WindowsAbi.MAXDWORD) return error.InvalidDwordRange;
}

pub const TypeEntry = struct {
    name: []const u8,
    macos_host_size: usize,
    windows_spec_size: usize,
    zig_translated_size: usize,
    is_divergent: bool,
};

pub const type_table = [_]TypeEntry{
    .{ .name = "CHAR", .macos_host_size = MacOsAbi.sizeof_CHAR, .windows_spec_size = WindowsAbi.sizeof_CHAR, .zig_translated_size = @sizeOf(windows_base.CHAR), .is_divergent = false },
    .{ .name = "SHORT", .macos_host_size = MacOsAbi.sizeof_SHORT, .windows_spec_size = WindowsAbi.sizeof_SHORT, .zig_translated_size = @sizeOf(windows_base.SHORT), .is_divergent = false },
    .{ .name = "INT", .macos_host_size = MacOsAbi.sizeof_INT, .windows_spec_size = WindowsAbi.sizeof_INT, .zig_translated_size = @sizeOf(windows_base.INT), .is_divergent = false },
    .{ .name = "LONG", .macos_host_size = MacOsAbi.sizeof_LONG, .windows_spec_size = WindowsAbi.sizeof_LONG, .zig_translated_size = @sizeOf(windows_base.LONG), .is_divergent = true },
    .{ .name = "ULONG", .macos_host_size = @sizeOf(c_ulong), .windows_spec_size = 4, .zig_translated_size = @sizeOf(windows_base.ULONG), .is_divergent = true },
    .{ .name = "LONGLONG", .macos_host_size = MacOsAbi.sizeof_LONGLONG, .windows_spec_size = WindowsAbi.sizeof_LONGLONG, .zig_translated_size = @sizeOf(windows_base.LONGLONG), .is_divergent = false },
    .{ .name = "FLOAT", .macos_host_size = MacOsAbi.sizeof_FLOAT, .windows_spec_size = WindowsAbi.sizeof_FLOAT, .zig_translated_size = @sizeOf(windows_base.FLOAT), .is_divergent = false },
    .{ .name = "WCHAR", .macos_host_size = MacOsAbi.sizeof_WCHAR, .windows_spec_size = WindowsAbi.sizeof_WCHAR, .zig_translated_size = @sizeOf(windows_base.WCHAR), .is_divergent = true },
    .{ .name = "BOOL", .macos_host_size = MacOsAbi.sizeof_BOOL, .windows_spec_size = WindowsAbi.sizeof_BOOL, .zig_translated_size = @sizeOf(windows_base.BOOL), .is_divergent = false },
    .{ .name = "BYTE", .macos_host_size = MacOsAbi.sizeof_BYTE, .windows_spec_size = WindowsAbi.sizeof_BYTE, .zig_translated_size = @sizeOf(windows_base.BYTE), .is_divergent = false },
    .{ .name = "WORD", .macos_host_size = MacOsAbi.sizeof_WORD, .windows_spec_size = WindowsAbi.sizeof_WORD, .zig_translated_size = @sizeOf(windows_base.WORD), .is_divergent = false },
    .{ .name = "DWORD", .macos_host_size = MacOsAbi.sizeof_DWORD, .windows_spec_size = WindowsAbi.sizeof_DWORD, .zig_translated_size = @sizeOf(windows_base.DWORD), .is_divergent = true },
    .{ .name = "INT32", .macos_host_size = MacOsAbi.sizeof_INT32, .windows_spec_size = WindowsAbi.sizeof_INT32, .zig_translated_size = @sizeOf(windows_base.INT32), .is_divergent = false },
    .{ .name = "INT64", .macos_host_size = MacOsAbi.sizeof_INT64, .windows_spec_size = WindowsAbi.sizeof_INT64, .zig_translated_size = @sizeOf(windows_base.INT64), .is_divergent = false },
    .{ .name = "DWORD64", .macos_host_size = MacOsAbi.sizeof_DWORD64, .windows_spec_size = WindowsAbi.sizeof_DWORD64, .zig_translated_size = @sizeOf(windows_base.DWORD64), .is_divergent = false },
    .{ .name = "ULONG64", .macos_host_size = MacOsAbi.sizeof_ULONG64, .windows_spec_size = WindowsAbi.sizeof_ULONG64, .zig_translated_size = @sizeOf(windows_base.ULONG64), .is_divergent = false },
    .{ .name = "LONG_PTR", .macos_host_size = MacOsAbi.sizeof_LONG_PTR, .windows_spec_size = WindowsAbi.sizeof_LONG_PTR, .zig_translated_size = @sizeOf(windows_base.LONG_PTR), .is_divergent = false },
    .{ .name = "INT_PTR", .macos_host_size = MacOsAbi.sizeof_INT_PTR, .windows_spec_size = WindowsAbi.sizeof_INT_PTR, .zig_translated_size = @sizeOf(windows_base.INT_PTR), .is_divergent = false },
    .{ .name = "ULONG_PTR", .macos_host_size = MacOsAbi.sizeof_ULONG_PTR, .windows_spec_size = WindowsAbi.sizeof_ULONG_PTR, .zig_translated_size = @sizeOf(windows_base.ULONG_PTR), .is_divergent = false },
    .{ .name = "SIZE_T", .macos_host_size = MacOsAbi.sizeof_SIZE_T, .windows_spec_size = WindowsAbi.sizeof_SIZE_T, .zig_translated_size = @sizeOf(windows_base.SIZE_T), .is_divergent = false },
};

pub const StructEntry = struct {
    name: []const u8,
    windows_spec_size: usize,
    zig_translated_size: usize,
};

/// Here we want to create a standard of the Windows spec to compare macOS against
pub const struct_table = [_]StructEntry{
    .{ .name = "LARGE_INTEGER", .windows_spec_size = WindowsAbi.sizeof_LARGE_INTEGER, .zig_translated_size = @sizeOf(windows_base.LARGE_INTEGER) },
    .{ .name = "ULARGE_INTEGER", .windows_spec_size = WindowsAbi.sizeof_ULARGE_INTEGER, .zig_translated_size = @sizeOf(windows_base.ULARGE_INTEGER) },
    .{ .name = "FILETIME", .windows_spec_size = WindowsAbi.sizeof_FILETIME, .zig_translated_size = @sizeOf(windows_base.FILETIME) },
    .{ .name = "OVERLAPPED", .windows_spec_size = WindowsAbi.sizeof_OVERLAPPED, .zig_translated_size = @sizeOf(windows_base.OVERLAPPED) },
    .{ .name = "SECURITY_ATTRIBUTES", .windows_spec_size = WindowsAbi.sizeof_SECURITY_ATTRIBUTES, .zig_translated_size = @sizeOf(windows_base.SECURITY_ATTRIBUTES) },
    .{ .name = "GUID", .windows_spec_size = WindowsAbi.sizeof_GUID, .zig_translated_size = @sizeOf(windows_base.GUID) },
};

pub fn validateWindowsTypeSizes() WindowsAbiError!void {
    inline for (type_table) |entry| {
        // 1. Check Zig translated shim size vs Windows specification size
        if (entry.zig_translated_size != entry.windows_spec_size) {
            if (std.mem.eql(u8, entry.name, "LONG")) return error.InvalidLongWidth;
            if (std.mem.eql(u8, entry.name, "CHAR")) return error.InvalidCharWidth;
            if (std.mem.eql(u8, entry.name, "SHORT")) return error.InvalidShortWidth;
            if (std.mem.eql(u8, entry.name, "INT")) return error.InvalidIntWidth;
            if (std.mem.eql(u8, entry.name, "LONGLONG")) return error.InvalidLongLongWidth;
            if (std.mem.eql(u8, entry.name, "FLOAT")) return error.InvalidFloatWidth;
            if (std.mem.eql(u8, entry.name, "WCHAR")) return error.InvalidWCharWidth;
            if (std.mem.eql(u8, entry.name, "BOOL")) return error.InvalidBoolWidth;
            if (std.mem.eql(u8, entry.name, "BYTE")) return error.InvalidByteWidth;
            if (std.mem.eql(u8, entry.name, "WORD")) return error.InvalidWordWidth;
            if (std.mem.eql(u8, entry.name, "DWORD")) return error.InvalidDwordWidth;
            if (std.mem.eql(u8, entry.name, "INT32")) return error.InvalidInt32Width;
            if (std.mem.eql(u8, entry.name, "INT64")) return error.InvalidInt64Width;
            if (std.mem.eql(u8, entry.name, "DWORD64")) return error.InvalidDword64Width;
            if (std.mem.eql(u8, entry.name, "ULONG64")) return error.InvalidUlong64Width;
            return error.InvalidPointerWidth;
        }

        // 2. If types are convergent (not divergent), we ensure macOS becomes said size needed

        if (!entry.is_divergent) {
            if (entry.macos_host_size != entry.windows_spec_size) {
                if (std.mem.eql(u8, entry.name, "LONG_PTR") or
                    std.mem.eql(u8, entry.name, "INT_PTR") or
                    std.mem.eql(u8, entry.name, "ULONG_PTR") or
                    std.mem.eql(u8, entry.name, "SIZE_T"))
                {
                    return error.InvalidPointerWidth;
                }
                if (std.mem.eql(u8, entry.name, "CHAR")) return error.InvalidCharWidth;
                if (std.mem.eql(u8, entry.name, "SHORT")) return error.InvalidShortWidth;
                if (std.mem.eql(u8, entry.name, "INT")) return error.InvalidIntWidth;
                if (std.mem.eql(u8, entry.name, "LONGLONG")) return error.InvalidLongLongWidth;
                if (std.mem.eql(u8, entry.name, "FLOAT")) return error.InvalidFloatWidth;
                if (std.mem.eql(u8, entry.name, "BOOL")) return error.InvalidBoolWidth;
                if (std.mem.eql(u8, entry.name, "BYTE")) return error.InvalidByteWidth;
                if (std.mem.eql(u8, entry.name, "WORD")) return error.InvalidWordWidth;
                if (std.mem.eql(u8, entry.name, "INT32")) return error.InvalidInt32Width;
                if (std.mem.eql(u8, entry.name, "INT64")) return error.InvalidInt64Width;
                if (std.mem.eql(u8, entry.name, "DWORD64")) return error.InvalidDword64Width;
                if (std.mem.eql(u8, entry.name, "ULONG64")) return error.InvalidUlong64Width;
                return error.InvalidPointerWidth;
            }
        }
    }
}

pub fn validateWindowsStructLayouts() WindowsAbiError!void {
    inline for (struct_table) |entry| {
        if (entry.zig_translated_size != entry.windows_spec_size) {
            if (std.mem.eql(u8, entry.name, "LARGE_INTEGER") or
                std.mem.eql(u8, entry.name, "ULARGE_INTEGER")) return error.InvalidLargeIntegerLayout;
            if (std.mem.eql(u8, entry.name, "FILETIME")) return error.InvalidFileTimeLayout;
            if (std.mem.eql(u8, entry.name, "OVERLAPPED")) return error.InvalidOverlappedLayout;
            if (std.mem.eql(u8, entry.name, "SECURITY_ATTRIBUTES")) return error.InvalidSecurityAttributesLayout;
            if (std.mem.eql(u8, entry.name, "GUID")) return error.InvalidGuidLayout;
        }
    }
}

pub fn validateWindowsMacros() WindowsAbiError!void {
    // 1. Bitwise Extraction & Packing Verification
    const test_val: usize = 0x123456789abcdef0;
    
    // LOWORD / HIWORD (extracting 16-bit components)
    if (windows_base.LOWORD(test_val) != 0xdef0) return error.InvalidBitExtractionMacro;
    if (windows_base.HIWORD(test_val) != 0x9abc) return error.InvalidBitExtractionMacro;
    
    // LOBYTE / HIBYTE (extracting 8-bit components from a word)
    const test_word: u16 = 0x5678;
    if (windows_base.LOBYTE(test_word) != 0x78) return error.InvalidBitExtractionMacro;
    if (windows_base.HIBYTE(test_word) != 0x56) return error.InvalidBitExtractionMacro;
    
    // MAKEWORD / MAKELONG (reconstructing components)
    if (windows_base.MAKEWORD(@as(u8, 0x12), @as(u8, 0x34)) != 0x3412) return error.InvalidBytePackingMacro;
    if (windows_base.MAKELONG(@as(u16, 0x1234), @as(u16, 0x5678)) != 0x56781234) return error.InvalidBytePackingMacro;
    
    // Boundary/all-ones tests
    const all_ones: usize = 0xffffffffffffffff;
    if (windows_base.LOWORD(all_ones) != 0xffff) return error.InvalidBitExtractionMacro;
    if (windows_base.HIWORD(all_ones) != 0xffff) return error.InvalidBitExtractionMacro;
    if (windows_base.LOBYTE(all_ones) != 0xff) return error.InvalidBitExtractionMacro;
    if (windows_base.HIBYTE(all_ones) != 0xff) return error.InvalidBitExtractionMacro;
    
    // 2. HRESULT macros verification
    // Success code: 0
    if (windows_base.HRESULT_IS_FAILURE(0) != false) return error.InvalidHresultMacro;
    
    // Failure code: E_FAIL (0x80004005) or Win32 Error (e.g. 0x80070002)
    const hr_win32 = windows_base.HRESULT_FROM_WIN32(2); // ERROR_FILE_NOT_FOUND
    if (hr_win32 != 0x80070002) return error.InvalidHresultMacro;
    
    if (windows_base.HRESULT_IS_FAILURE(hr_win32) != true) return error.InvalidHresultMacro;
    if (windows_base.HRESULT_IS_WIN32(hr_win32) != false) return error.InvalidHresultMacro; // signed sign-extension and FACILITY_WINDOWS (8) check makes this false
    if (windows_base.HRESULT_FACILITY(hr_win32) != 0x8007) return error.InvalidHresultMacro; // signed right shift sign-extends 0x80070002 to 0xFFFF8007, mask leaves 0x8007
    if (windows_base.HRESULT_CODE(hr_win32) != 2) return error.InvalidHresultMacro;
    
    const hr_sspi = @as(c_int, @bitCast(@as(u32, 0x80090006)));
    if (windows_base.HRESULT_IS_WIN32(hr_sspi) != false) return error.InvalidHresultMacro;
    if (windows_base.HRESULT_FACILITY(hr_sspi) != 0x8009) return error.InvalidHresultMacro;
}

pub fn validateAll() WindowsAbiError!void {
    try validateWindowsConstants();
    try validateWindowsTypeSizes();
    try validateWindowsStructLayouts();
    try validateWindowsMacros();
}

pub fn reportTypeTable() void {
    std.debug.print(
        \\================================================================================
        \\ Rosette Basic Data Types Comparison Table
        \\================================================================================
        \\ Type Name        | macOS Host (LP64) | Win32 Spec (LLP64) | Zig Translated (Shim)
        \\------------------+-------------------+--------------------+--------------------
    , .{});
    inline for (type_table) |entry| {
        std.debug.print(
            \\
            \\ {s:<17} | {d:<17} | {d:<18} | {d:<18}
        , .{ entry.name, entry.macos_host_size, entry.windows_spec_size, entry.zig_translated_size });
    }
    std.debug.print(
        \\
        \\================================================================================
        \\
    , .{});
}

/// Emit the macOS-side values via std.debug.print (writes to stderr, which
/// shows up on the console alongside C-side stdout output).
pub fn reportMacOsAbi() void {
    std.debug.print(
        \\macOS ABI snapshot (certifying that our values are truely our values):
        \\  MINCHAR  = 0x{x}     MAXCHAR  = 0x{x}
        \\  MINSHORT = 0x{x}   MAXSHORT = 0x{x}
        \\  MINLONG  = 0x{x} MAXLONG  = 0x{x}
        \\  MAXBYTE  = 0x{x}     MAXWORD  = 0x{x}   MAXDWORD = 0x{x}
        \\  sizeof(CHAR)      = {d}    sizeof(SHORT)     = {d}    sizeof(INT)       = {d}
        \\  sizeof(LONG)      = {d}    sizeof(LONGLONG)  = {d}    sizeof(FLOAT)     = {d}
        \\  sizeof(WCHAR)     = {d}    sizeof(BOOL)      = {d}    sizeof(BYTE)      = {d}
        \\  sizeof(WORD)      = {d}    sizeof(DWORD)     = {d}    sizeof(INT32)     = {d}
        \\  sizeof(INT64)     = {d}    sizeof(DWORD64)   = {d}    sizeof(ULONG64)   = {d}
        \\  sizeof(LONG_PTR)  = {d}    sizeof(INT_PTR)   = {d}    sizeof(ULONG_PTR) = {d}
        \\  sizeof(SIZE_T)    = {d}
        \\
    , .{
        MacOsAbi.MINCHAR,          MacOsAbi.MAXCHAR,
        MacOsAbi.MINSHORT,         MacOsAbi.MAXSHORT,
        MacOsAbi.MINLONG,          MacOsAbi.MAXLONG,
        MacOsAbi.MAXBYTE,          MacOsAbi.MAXWORD,
        MacOsAbi.MAXDWORD,         MacOsAbi.sizeof_CHAR,
        MacOsAbi.sizeof_SHORT,     MacOsAbi.sizeof_INT,
        MacOsAbi.sizeof_LONG,      MacOsAbi.sizeof_LONGLONG,
        MacOsAbi.sizeof_FLOAT,     MacOsAbi.sizeof_WCHAR,
        MacOsAbi.sizeof_BOOL,      MacOsAbi.sizeof_BYTE,
        MacOsAbi.sizeof_WORD,      MacOsAbi.sizeof_DWORD,
        MacOsAbi.sizeof_INT32,     MacOsAbi.sizeof_INT64,
        MacOsAbi.sizeof_DWORD64,   MacOsAbi.sizeof_ULONG64,
        MacOsAbi.sizeof_LONG_PTR,  MacOsAbi.sizeof_INT_PTR,
        MacOsAbi.sizeof_ULONG_PTR, MacOsAbi.sizeof_SIZE_T,
    });
}

/// Emit the pseudo-Windows snapshot via std.debug.print
pub fn reportWindowsAbi() void {
    std.debug.print(
        \\Pseudo-Windows ABI snapshot (Win32 x64 LLP64 spec):
        \\  MINCHAR  = 0x{x}     MAXCHAR  = 0x{x}
        \\  MINSHORT = 0x{x}   MAXSHORT = 0x{x}
        \\  MINLONG  = 0x{x} MAXLONG  = 0x{x}
        \\  MAXBYTE  = 0x{x}     MAXWORD  = 0x{x}   MAXDWORD = 0x{x}
        \\  sizeof(CHAR)      = {d}    sizeof(SHORT)     = {d}    sizeof(INT)       = {d}
        \\  sizeof(LONG)      = {d}    sizeof(LONGLONG)  = {d}    sizeof(FLOAT)     = {d}
        \\  sizeof(WCHAR)     = {d}    sizeof(BOOL)      = {d}    sizeof(BYTE)      = {d}
        \\  sizeof(WORD)      = {d}    sizeof(DWORD)     = {d}    sizeof(INT32)     = {d}
        \\  sizeof(INT64)     = {d}    sizeof(DWORD64)   = {d}    sizeof(ULONG64)   = {d}
        \\  sizeof(LONG_PTR)  = {d}    sizeof(INT_PTR)   = {d}    sizeof(ULONG_PTR) = {d}
        \\  sizeof(SIZE_T)    = {d}
        \\
    , .{
        WindowsAbi.MINCHAR,          WindowsAbi.MAXCHAR,
        WindowsAbi.MINSHORT,         WindowsAbi.MAXSHORT,
        WindowsAbi.MINLONG,          WindowsAbi.MAXLONG,
        WindowsAbi.MAXBYTE,          WindowsAbi.MAXWORD,
        WindowsAbi.MAXDWORD,         WindowsAbi.sizeof_CHAR,
        WindowsAbi.sizeof_SHORT,     WindowsAbi.sizeof_INT,
        WindowsAbi.sizeof_LONG,      WindowsAbi.sizeof_LONGLONG,
        WindowsAbi.sizeof_FLOAT,     WindowsAbi.sizeof_WCHAR,
        WindowsAbi.sizeof_BOOL,      WindowsAbi.sizeof_BYTE,
        WindowsAbi.sizeof_WORD,      WindowsAbi.sizeof_DWORD,
        WindowsAbi.sizeof_INT32,     WindowsAbi.sizeof_INT64,
        WindowsAbi.sizeof_DWORD64,   WindowsAbi.sizeof_ULONG64,
        WindowsAbi.sizeof_LONG_PTR,  WindowsAbi.sizeof_INT_PTR,
        WindowsAbi.sizeof_ULONG_PTR, WindowsAbi.sizeof_SIZE_T,
    });
    std.debug.print(
        \\  sizeof(LARGE_INTEGER)       = {d}
        \\  sizeof(ULARGE_INTEGER)      = {d}
        \\  sizeof(FILETIME)            = {d}
        \\  sizeof(OVERLAPPED)          = {d}
        \\  sizeof(SECURITY_ATTRIBUTES) = {d}
        \\  sizeof(GUID)                = {d}
        \\
    , .{
        WindowsAbi.sizeof_LARGE_INTEGER,
        WindowsAbi.sizeof_ULARGE_INTEGER,
        WindowsAbi.sizeof_FILETIME,
        WindowsAbi.sizeof_OVERLAPPED,
        WindowsAbi.sizeof_SECURITY_ATTRIBUTES,
        WindowsAbi.sizeof_GUID,
    });
}

/// Fetch the results of our program
pub export fn rosette_print_abi_report() void {
    reportTypeTable();
    reportMacOsAbi();
    reportWindowsAbi();
}

/// C-callable: run every safety check. Returns 0 on success, a non-zero code
/// per WindowsAbiError variant on failure, so the C side can report exactly
/// which corner of the three-way comparison drifted.
pub export fn rosette_validate_abi() c_int {
    validateAll() catch |err| return switch (err) {
        // Constant ranges (1..6) — same as before.
        error.InvalidCharRange => 1,
        error.InvalidShortRange => 2,
        error.InvalidLongRange => 3,
        error.InvalidByteRange => 4,
        error.InvalidWordRange => 5,
        error.InvalidDwordRange => 6,
        // Pointer-derived widths (7) — same as before.
        error.InvalidPointerWidth => 7,
        // Scalar widths (8..21).
        error.InvalidLongWidth => 8,
        error.InvalidCharWidth => 9,
        error.InvalidShortWidth => 10,
        error.InvalidIntWidth => 11,
        error.InvalidLongLongWidth => 12,
        error.InvalidFloatWidth => 13,
        error.InvalidWCharWidth => 14,
        error.InvalidBoolWidth => 15,
        error.InvalidByteWidth => 16,
        error.InvalidWordWidth => 17,
        error.InvalidDwordWidth => 18,
        error.InvalidInt32Width => 19,
        error.InvalidInt64Width => 20,
        error.InvalidDword64Width => 21,
        error.InvalidUlong64Width => 22,
        // Struct layouts (23..27).
        error.InvalidLargeIntegerLayout => 23,
        error.InvalidFileTimeLayout => 24,
        error.InvalidOverlappedLayout => 25,
        error.InvalidSecurityAttributesLayout => 26,
        error.InvalidGuidLayout => 27,
        // Macro / bitwise safety checks (28..30).
        error.InvalidBytePackingMacro => 28,
        error.InvalidBitExtractionMacro => 29,
        error.InvalidHresultMacro => 30,
    };
    return 0;
}

/// This will tell you if any variable is outside of the proper scope
/// it needs to be. We need foundational data types to be the same else
/// this will create significant issues on macOS
pub export fn rosette_print_sysinfo_report() void {
    reportTypeTable();
    reportMacOsAbi();
    reportWindowsAbi();
}

pub export fn rosette_validate_sysinfo() c_int {
    return rosette_validate_abi();
}

pub export fn rosette_sysinfo_failure_name(code: c_int) [*:0]const u8 {
    return rosette_abi_failure_name(code);
}

pub export fn rosette_abi_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidCharRange",
        2 => "InvalidShortRange",
        3 => "InvalidLongRange",
        4 => "InvalidByteRange",
        5 => "InvalidWordRange",
        6 => "InvalidDwordRange",
        7 => "InvalidPointerWidth",
        8 => "InvalidLongWidth",
        9 => "InvalidCharWidth",
        10 => "InvalidShortWidth",
        11 => "InvalidIntWidth",
        12 => "InvalidLongLongWidth",
        13 => "InvalidFloatWidth",
        14 => "InvalidWCharWidth",
        15 => "InvalidBoolWidth",
        16 => "InvalidByteWidth",
        17 => "InvalidWordWidth",
        18 => "InvalidDwordWidth",
        19 => "InvalidInt32Width",
        20 => "InvalidInt64Width",
        21 => "InvalidDword64Width",
        22 => "InvalidUlong64Width",
        23 => "InvalidLargeIntegerLayout",
        24 => "InvalidFileTimeLayout",
        25 => "InvalidOverlappedLayout",
        26 => "InvalidSecurityAttributesLayout",
        27 => "InvalidGuidLayout",
        28 => "InvalidBytePackingMacro",
        29 => "InvalidBitExtractionMacro",
        30 => "InvalidHresultMacro",
        else => "UnknownAbiFailure",
    };
}

pub export fn rosette_validate_behavior() c_int {
    return behavior_mod.rosette_validate_behavior();
}
pub export fn rosette_behavior_failure_name(code: c_int) [*:0]const u8 {
    return behavior_mod.rosette_behavior_failure_name(code);
}
pub export fn rosette_print_behavior_report() void {
    behavior_mod.rosette_print_behavior_report();
}

test "windows_base.h matches macOS and pseudo-Windows ABI snapshots" {
    reportMacOsAbi();
    reportWindowsAbi();
    try validateAll();
}
