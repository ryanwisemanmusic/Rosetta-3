const std = @import("std");

pub const MspackError = error{
    InvalidErrorCode,
    InvalidVersionEntity,
    InvalidOpenMode,
    InvalidSeekMode,
    InvalidSystemStructSize,
    InvalidFileStructSize,
    InvalidSystemMemberOffset,
    InvalidOffSize,
    InvalidTypeWidth,
};

/// Pseudo-Windows snapshot. All constants and struct layouts sourced
/// from mspack.h (libmspack, LGPL). On Windows LLP64, `off_t` is
/// 4 bytes (long), whereas on macOS LP64, `off_t` is 8 bytes. This
/// is the primary ABI divergence point, detected by MSPACK_SYS_SELFTEST.
pub const WindowsMspackSpec = struct {
    // ── Error codes ────────────────────────────────────────────────
    pub const MSPACK_ERR_OK: i32 = 0;
    pub const MSPACK_ERR_ARGS: i32 = 1;
    pub const MSPACK_ERR_OPEN: i32 = 2;
    pub const MSPACK_ERR_READ: i32 = 3;
    pub const MSPACK_ERR_WRITE: i32 = 4;
    pub const MSPACK_ERR_SEEK: i32 = 5;
    pub const MSPACK_ERR_NOMEMORY: i32 = 6;
    pub const MSPACK_ERR_SIGNATURE: i32 = 7;
    pub const MSPACK_ERR_DATAFORMAT: i32 = 8;
    pub const MSPACK_ERR_CHECKSUM: i32 = 9;
    pub const MSPACK_ERR_CRUNCH: i32 = 10;
    pub const MSPACK_ERR_DECRUNCH: i32 = 11;

    // ── Version entities ───────────────────────────────────────────
    pub const MSPACK_VER_LIBRARY: i32 = 0;
    pub const MSPACK_VER_SYSTEM: i32 = 1;
    pub const MSPACK_VER_MSCABD: i32 = 2;
    pub const MSPACK_VER_MSCABC: i32 = 3;
    pub const MSPACK_VER_MSCHMD: i32 = 4;
    pub const MSPACK_VER_MSCHMC: i32 = 5;
    pub const MSPACK_VER_MSLITD: i32 = 6;
    pub const MSPACK_VER_MSLITC: i32 = 7;
    pub const MSPACK_VER_MSHLPD: i32 = 8;
    pub const MSPACK_VER_MSHLPC: i32 = 9;
    pub const MSPACK_VER_MSSZDDD: i32 = 10;
    pub const MSPACK_VER_MSSZDDC: i32 = 11;
    pub const MSPACK_VER_MSKWAJD: i32 = 12;
    pub const MSPACK_VER_MSKWAJC: i32 = 13;
    pub const MSPACK_VER_MSOABD: i32 = 14;
    pub const MSPACK_VER_MSOABC: i32 = 15;

    // ── Open modes ─────────────────────────────────────────────────
    pub const MSPACK_SYS_OPEN_READ: i32 = 0;
    pub const MSPACK_SYS_OPEN_WRITE: i32 = 1;
    pub const MSPACK_SYS_OPEN_UPDATE: i32 = 2;
    pub const MSPACK_SYS_OPEN_APPEND: i32 = 3;

    // ── Seek modes ─────────────────────────────────────────────────
    pub const MSPACK_SYS_SEEK_START: i32 = 0;
    pub const MSPACK_SYS_SEEK_CUR: i32 = 1;
    pub const MSPACK_SYS_SEEK_END: i32 = 2;

    // ── mspack_system struct layout (LLP64) ────────────────────────
    // 11 members, all pointers (8 bytes each on 64-bit):
    //   open, close, read, write, seek, tell, message, alloc, free, copy, null_ptr
    pub const MSPACK_SYSTEM_MEMBER_COUNT: u32 = 11;
    pub const sizeof_mspack_system: comptime_int = 88;

    pub const offsetof_open: comptime_int = 0;
    pub const offsetof_close: comptime_int = 8;
    pub const offsetof_read: comptime_int = 16;
    pub const offsetof_write: comptime_int = 24;
    pub const offsetof_seek: comptime_int = 32;
    pub const offsetof_tell: comptime_int = 40;
    pub const offsetof_message: comptime_int = 48;
    pub const offsetof_alloc: comptime_int = 56;
    pub const offsetof_free: comptime_int = 64;
    pub const offsetof_copy: comptime_int = 72;
    pub const offsetof_null_ptr: comptime_int = 80;

    // ── mspack_file struct layout ──────────────────────────────────
    pub const sizeof_mspack_file: comptime_int = 4;
    pub const offsetof_dummy: comptime_int = 0;

    // ── off_t width ────────────────────────────────────────────────
    // Windows LLP64: off_t = long = 4 bytes
    pub const sizeof_off_t: comptime_int = 4;
};

/// macOS host snapshot.  The primary divergence is `off_t` width:
/// LP64 uses 8 bytes whereas LLP64 uses 4 bytes.  This is detected
/// by MSPACK_SYS_SELFTEST which compares sizeof(off_t).
pub const MacOsMspack = struct {
    pub const sizeof_off_t = @sizeOf(c_long);
    pub const sizeof_ptr = @sizeOf(*anyopaque);
    pub const sizeof_c_int = @sizeOf(c_int);
};

const MspackSystemState = extern struct {
    open: ?*const fn (?*anyopaque, [*:0]const u8, c_int) callconv(.c) ?*anyopaque,
    close: ?*const fn (?*anyopaque) callconv(.c) void,
    read: ?*const fn (?*anyopaque, ?*anyopaque, c_int) callconv(.c) c_int,
    write: ?*const fn (?*anyopaque, ?*anyopaque, c_int) callconv(.c) c_int,
    seek: ?*const fn (?*anyopaque, c_long, c_int) callconv(.c) c_int,
    tell: ?*const fn (?*anyopaque) callconv(.c) c_long,
    message: ?*const fn (?*anyopaque, [*:0]const u8, ...) callconv(.c) void,
    alloc: ?*const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque,
    free: ?*const fn (?*anyopaque) callconv(.c) void,
    copy: ?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.c) void,
    null_ptr: ?*anyopaque,
};

const MspackFileState = extern struct {
    dummy: c_int,
};

pub fn validateMspackErrorCodes() MspackError!void {
    if (WindowsMspackSpec.MSPACK_ERR_OK != 0) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_ARGS != 1) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_OPEN != 2) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_READ != 3) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_WRITE != 4) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_SEEK != 5) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_NOMEMORY != 6) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_SIGNATURE != 7) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_DATAFORMAT != 8) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_CHECKSUM != 9) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_CRUNCH != 10) return error.InvalidErrorCode;
    if (WindowsMspackSpec.MSPACK_ERR_DECRUNCH != 11) return error.InvalidErrorCode;
}

pub fn validateMspackVersionEntities() MspackError!void {
    if (WindowsMspackSpec.MSPACK_VER_LIBRARY != 0) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_SYSTEM != 1) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSCABD != 2) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSCABC != 3) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSCHMD != 4) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSCHMC != 5) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSLITD != 6) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSLITC != 7) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSHLPD != 8) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSHLPC != 9) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSSZDDD != 10) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSSZDDC != 11) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSKWAJD != 12) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSKWAJC != 13) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSOABD != 14) return error.InvalidVersionEntity;
    if (WindowsMspackSpec.MSPACK_VER_MSOABC != 15) return error.InvalidVersionEntity;
}

pub fn validateMspackOpenSeekModes() MspackError!void {
    if (WindowsMspackSpec.MSPACK_SYS_OPEN_READ != 0) return error.InvalidOpenMode;
    if (WindowsMspackSpec.MSPACK_SYS_OPEN_WRITE != 1) return error.InvalidOpenMode;
    if (WindowsMspackSpec.MSPACK_SYS_OPEN_UPDATE != 2) return error.InvalidOpenMode;
    if (WindowsMspackSpec.MSPACK_SYS_OPEN_APPEND != 3) return error.InvalidOpenMode;

    if (WindowsMspackSpec.MSPACK_SYS_SEEK_START != 0) return error.InvalidSeekMode;
    if (WindowsMspackSpec.MSPACK_SYS_SEEK_CUR != 1) return error.InvalidSeekMode;
    if (WindowsMspackSpec.MSPACK_SYS_SEEK_END != 2) return error.InvalidSeekMode;
}

pub fn validateMspackStructLayouts() MspackError!void {
    // Validate mspack_system size and member offsets
    if (@sizeOf(MspackSystemState) != WindowsMspackSpec.sizeof_mspack_system)
        return error.InvalidSystemStructSize;
    if (@offsetOf(MspackSystemState, "open") != WindowsMspackSpec.offsetof_open)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "close") != WindowsMspackSpec.offsetof_close)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "read") != WindowsMspackSpec.offsetof_read)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "write") != WindowsMspackSpec.offsetof_write)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "seek") != WindowsMspackSpec.offsetof_seek)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "tell") != WindowsMspackSpec.offsetof_tell)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "message") != WindowsMspackSpec.offsetof_message)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "alloc") != WindowsMspackSpec.offsetof_alloc)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "free") != WindowsMspackSpec.offsetof_free)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "copy") != WindowsMspackSpec.offsetof_copy)
        return error.InvalidSystemMemberOffset;
    if (@offsetOf(MspackSystemState, "null_ptr") != WindowsMspackSpec.offsetof_null_ptr)
        return error.InvalidSystemMemberOffset;

    // Validate mspack_file
    if (@sizeOf(MspackFileState) != WindowsMspackSpec.sizeof_mspack_file)
        return error.InvalidFileStructSize;
    if (@offsetOf(MspackFileState, "dummy") != WindowsMspackSpec.offsetof_dummy)
        return error.InvalidSystemMemberOffset;
}

pub fn validateMspackTypeWidths() MspackError!void {
    if (MacOsMspack.sizeof_c_int != 4) return error.InvalidTypeWidth;
    if (MacOsMspack.sizeof_ptr != 8) return error.InvalidTypeWidth;

    // off_t divergence: LP64 = 8, LLP64 = 4
    if (MacOsMspack.sizeof_off_t != WindowsMspackSpec.sizeof_off_t) {
        if (MacOsMspack.sizeof_off_t != 8) return error.InvalidOffSize;
    }
}

pub fn validateAll() MspackError!void {
    try validateMspackErrorCodes();
    try validateMspackVersionEntities();
    try validateMspackOpenSeekModes();
    try validateMspackStructLayouts();
    try validateMspackTypeWidths();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosette_validate_mspack() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidErrorCode => 1,
        error.InvalidVersionEntity => 2,
        error.InvalidOpenMode => 3,
        error.InvalidSeekMode => 4,
        error.InvalidSystemStructSize => 5,
        error.InvalidFileStructSize => 6,
        error.InvalidSystemMemberOffset => 7,
        error.InvalidOffSize => 8,
        error.InvalidTypeWidth => 9,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosette_mspack_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidErrorCode",
        2 => "InvalidVersionEntity",
        3 => "InvalidOpenMode",
        4 => "InvalidSeekMode",
        5 => "InvalidSystemStructSize",
        6 => "InvalidFileStructSize",
        7 => "InvalidSystemMemberOffset",
        8 => "InvalidOffSize",
        9 => "InvalidTypeWidth",
        else => "UnknownMspackFailure",
    };
}

pub fn reportMspackSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ libmspack Specification Table
        \\================================================================================
        \\ Error codes:
        \\   OK={d} ARGS={d} OPEN={d} READ={d}
        \\   WRITE={d} SEEK={d} NOMEMORY={d}
        \\   SIGNATURE={d} DATAFORMAT={d}
        \\   CHECKSUM={d} CRUNCH={d} DECRUNCH={d}
        \\
    , .{
        WindowsMspackSpec.MSPACK_ERR_OK,
        WindowsMspackSpec.MSPACK_ERR_ARGS,
        WindowsMspackSpec.MSPACK_ERR_OPEN,
        WindowsMspackSpec.MSPACK_ERR_READ,
        WindowsMspackSpec.MSPACK_ERR_WRITE,
        WindowsMspackSpec.MSPACK_ERR_SEEK,
        WindowsMspackSpec.MSPACK_ERR_NOMEMORY,
        WindowsMspackSpec.MSPACK_ERR_SIGNATURE,
        WindowsMspackSpec.MSPACK_ERR_DATAFORMAT,
        WindowsMspackSpec.MSPACK_ERR_CHECKSUM,
        WindowsMspackSpec.MSPACK_ERR_CRUNCH,
        WindowsMspackSpec.MSPACK_ERR_DECRUNCH,
    });

    std.debug.print(
        \\ Version entities (0-15):
        \\   LIBRARY={d} SYSTEM={d} MSCABD={d} MSCABC={d}
        \\   MSCHMD={d} MSCHMC={d} MSLITD={d} MSLITC={d}
        \\   MSHLPD={d} MSHLPC={d} MSSZDDD={d} MSSZDDC={d}
        \\   MSKWAJD={d} MSKWAJC={d} MSOABD={d} MSOABC={d}
        \\
        \\ Open modes:
        \\   READ={d} WRITE={d} UPDATE={d} APPEND={d}
        \\ Seek modes:
        \\   START={d} CUR={d} END={d}
        \\
    , .{
        WindowsMspackSpec.MSPACK_VER_LIBRARY,
        WindowsMspackSpec.MSPACK_VER_SYSTEM,
        WindowsMspackSpec.MSPACK_VER_MSCABD,
        WindowsMspackSpec.MSPACK_VER_MSCABC,
        WindowsMspackSpec.MSPACK_VER_MSCHMD,
        WindowsMspackSpec.MSPACK_VER_MSCHMC,
        WindowsMspackSpec.MSPACK_VER_MSLITD,
        WindowsMspackSpec.MSPACK_VER_MSLITC,
        WindowsMspackSpec.MSPACK_VER_MSHLPD,
        WindowsMspackSpec.MSPACK_VER_MSHLPC,
        WindowsMspackSpec.MSPACK_VER_MSSZDDD,
        WindowsMspackSpec.MSPACK_VER_MSSZDDC,
        WindowsMspackSpec.MSPACK_VER_MSKWAJD,
        WindowsMspackSpec.MSPACK_VER_MSKWAJC,
        WindowsMspackSpec.MSPACK_VER_MSOABD,
        WindowsMspackSpec.MSPACK_VER_MSOABC,
        WindowsMspackSpec.MSPACK_SYS_OPEN_READ,
        WindowsMspackSpec.MSPACK_SYS_OPEN_WRITE,
        WindowsMspackSpec.MSPACK_SYS_OPEN_UPDATE,
        WindowsMspackSpec.MSPACK_SYS_OPEN_APPEND,
        WindowsMspackSpec.MSPACK_SYS_SEEK_START,
        WindowsMspackSpec.MSPACK_SYS_SEEK_CUR,
        WindowsMspackSpec.MSPACK_SYS_SEEK_END,
    });

    std.debug.print(
        \\ mspack_system layout (64-bit, {d} members):
        \\   sizeof = {d} bytes
        \\   offsets: open={d} close={d} read={d} write={d}
        \\            seek={d} tell={d} message={d} alloc={d}
        \\            free={d} copy={d} null_ptr={d}
        \\
        \\ mspack_file layout:
        \\   sizeof = {d} bytes
        \\   offsetof(dummy) = {d}
        \\
        \\ Type widths:
        \\   sizeof(off_t) = {d}  (LP64: 8, LLP64: 4)
        \\   sizeof(c_int) = {d}
        \\   sizeof(ptr)   = {d}
        \\
        \\================================================================================
        \\
    , .{
        WindowsMspackSpec.MSPACK_SYSTEM_MEMBER_COUNT,
        WindowsMspackSpec.sizeof_mspack_system,
        WindowsMspackSpec.offsetof_open,
        WindowsMspackSpec.offsetof_close,
        WindowsMspackSpec.offsetof_read,
        WindowsMspackSpec.offsetof_write,
        WindowsMspackSpec.offsetof_seek,
        WindowsMspackSpec.offsetof_tell,
        WindowsMspackSpec.offsetof_message,
        WindowsMspackSpec.offsetof_alloc,
        WindowsMspackSpec.offsetof_free,
        WindowsMspackSpec.offsetof_copy,
        WindowsMspackSpec.offsetof_null_ptr,
        WindowsMspackSpec.sizeof_mspack_file,
        WindowsMspackSpec.offsetof_dummy,
        MacOsMspack.sizeof_off_t,
        MacOsMspack.sizeof_c_int,
        MacOsMspack.sizeof_ptr,
    });
}

pub export fn rosette_print_mspack_spec() void {
    reportMspackSpec();
}

test "MSPack spec matches expected values" {
    reportMspackSpec();
    try validateAll();
}
