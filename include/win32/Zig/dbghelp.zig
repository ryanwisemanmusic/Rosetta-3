const std = @import("std");
const builtin = @import("builtin");
const win32_all = @import("win32_pending");
const dbghelp = win32_all;

pub const DbghelpAbiError = error{
    InvalidExceptionCodes,
    InvalidSnapshottingConstants,
    InvalidSymbolOptions,
    InvalidM128ASize,
    InvalidXSaveFormatSize,
    InvalidContextSize,
    InvalidExceptionRecordSize,
    InvalidExceptionPointersSize,
    InvalidNtTibSize,
    InvalidSymbolInfoSize,
    InvalidSymbolInfoWSize,
    InvalidImagehlpLine64Size,
    InvalidImagehlpLineW64Size,
    InvalidThreadEntry32Size,
    InvalidAddress64Size,
    InvalidKdHelp64Size,
    InvalidStackFrame64Size,
    InvalidLuidSize,
    InvalidLuidAndAttributesSize,
    InvalidTokenPrivilegesSize,
    InvalidVsFixedFileInfoSize,
    InvalidMiniDumpExceptionInformationSize,
    InvalidMiniDumpExceptionInformation64Size,
    InvalidMiniDumpUserStreamSize,
    InvalidMiniDumpUserStreamInformationSize,
};

pub const WindowsDbghelpSpec = struct {
    pub const EXCEPTION_MAXIMUM_PARAMETERS: comptime_int = 15;
    pub const EXCEPTION_EXECUTE_HANDLER: comptime_int = 0x1;
    pub const EXCEPTION_CONTINUE_EXECUTION: comptime_int = 0xFFFFFFFF;
    pub const EXCEPTION_CONTINUE_SEARCH: comptime_int = 0x0;
    pub const EXCEPTION_ACCESS_VIOLATION: comptime_int = 0xC0000005;
    pub const EXCEPTION_BREAKPOINT: comptime_int = 0x80000003;
    pub const EXCEPTION_SINGLE_STEP: comptime_int = 0x80000004;
    pub const EXCEPTION_INT_DIVIDE_BY_ZERO: comptime_int = 0xC0000094;
    pub const EXCEPTION_STACK_OVERFLOW: comptime_int = 0xC00000FD;
    pub const EXCEPTION_ILLEGAL_INSTRUCTION: comptime_int = 0xC000001D;
    pub const EXCEPTION_INVALID_HANDLE: comptime_int = 0xC0000008;
    pub const EXCEPTION_GUARD_PAGE: comptime_int = 0x80000001;
    pub const EXCEPTION_FLT_DIVIDE_BY_ZERO: comptime_int = 0xC000008E;
    pub const EXCEPTION_FLT_OVERFLOW: comptime_int = 0xC0000091;
    pub const EXCEPTION_FLT_UNDERFLOW: comptime_int = 0xC0000093;
    pub const CONTROL_C_EXIT: comptime_int = 0xC000013A;

    pub const TH32CS_SNAPTHREAD: comptime_int = 0x00000004;
    pub const IMAGE_FILE_MACHINE_I386: comptime_int = 0x014c;
    pub const IMAGE_FILE_MACHINE_AMD64: comptime_int = 0x8664;
    pub const CONTEXT_AMD64: comptime_int = 0x100000;

    pub const SYMOPT_CASE_INSENSITIVE: comptime_int = 0x00000001;
    pub const SYMOPT_UNDNAME: comptime_int = 0x00000002;
    pub const SYMOPT_DEBUG: comptime_int = 0x80000000;
    pub const SYMOPT_ALLOW_ZERO_ADDRESS: comptime_int = 0x01000000;

    pub const sizeof_M128A: comptime_int = 16;
    pub const sizeof_XSAVE_FORMAT: comptime_int = if (builtin.target.cpu.arch == .x86_64) 584 else 328;
    pub const sizeof_CONTEXT: comptime_int = if (builtin.target.cpu.arch == .x86_64) 1232 else 716;
    pub const sizeof_EXCEPTION_RECORD: comptime_int = 152;
    pub const sizeof_EXCEPTION_POINTERS: comptime_int = 16;
    pub const sizeof_NT_TIB: comptime_int = if (builtin.target.cpu.arch == .x86_64) 56 else 28;
    pub const sizeof_SYMBOL_INFO: comptime_int = 104;
    pub const sizeof_SYMBOL_INFOW: comptime_int = 104;
    pub const sizeof_IMAGEHLP_LINE64: comptime_int = 32;
    pub const sizeof_IMAGEHLP_LINEW64: comptime_int = 32;
    pub const sizeof_THREADENTRY32: comptime_int = if (builtin.target.cpu.arch == .x86_64) 32 else 28;
    pub const sizeof_ADDRESS64: comptime_int = 16;
    pub const sizeof_KDHELP64: comptime_int = 104;
    pub const sizeof_STACKFRAME64: comptime_int = 184;
    pub const sizeof_LUID: comptime_int = 8;
    pub const sizeof_LUID_AND_ATTRIBUTES: comptime_int = 12;
    pub const sizeof_TOKEN_PRIVILEGES: comptime_int = 16;
    pub const sizeof_VS_FIXEDFILEINFO: comptime_int = 52;
    pub const sizeof_MINIDUMP_EXCEPTION_INFORMATION: comptime_int = if (builtin.target.cpu.arch == .x86_64) 24 else 12;
    pub const sizeof_MINIDUMP_EXCEPTION_INFORMATION64: comptime_int = 32;
    pub const sizeof_MINIDUMP_USER_STREAM: comptime_int = 16;
    pub const sizeof_MINIDUMP_USER_STREAM_INFORMATION: comptime_int = 16;
};

pub fn validateDbghelpConstants() DbghelpAbiError!void {
    if (dbghelp.EXCEPTION_MAXIMUM_PARAMETERS != WindowsDbghelpSpec.EXCEPTION_MAXIMUM_PARAMETERS or
        dbghelp.EXCEPTION_EXECUTE_HANDLER != WindowsDbghelpSpec.EXCEPTION_EXECUTE_HANDLER or
        dbghelp.EXCEPTION_CONTINUE_EXECUTION != WindowsDbghelpSpec.EXCEPTION_CONTINUE_EXECUTION or
        dbghelp.EXCEPTION_CONTINUE_SEARCH != WindowsDbghelpSpec.EXCEPTION_CONTINUE_SEARCH or
        dbghelp.EXCEPTION_ACCESS_VIOLATION != WindowsDbghelpSpec.EXCEPTION_ACCESS_VIOLATION or
        dbghelp.EXCEPTION_BREAKPOINT != WindowsDbghelpSpec.EXCEPTION_BREAKPOINT or
        dbghelp.EXCEPTION_SINGLE_STEP != WindowsDbghelpSpec.EXCEPTION_SINGLE_STEP or
        dbghelp.EXCEPTION_INT_DIVIDE_BY_ZERO != WindowsDbghelpSpec.EXCEPTION_INT_DIVIDE_BY_ZERO or
        dbghelp.EXCEPTION_STACK_OVERFLOW != WindowsDbghelpSpec.EXCEPTION_STACK_OVERFLOW or
        dbghelp.EXCEPTION_ILLEGAL_INSTRUCTION != WindowsDbghelpSpec.EXCEPTION_ILLEGAL_INSTRUCTION or
        dbghelp.EXCEPTION_INVALID_HANDLE != WindowsDbghelpSpec.EXCEPTION_INVALID_HANDLE or
        dbghelp.EXCEPTION_GUARD_PAGE != WindowsDbghelpSpec.EXCEPTION_GUARD_PAGE or
        dbghelp.EXCEPTION_FLT_DIVIDE_BY_ZERO != WindowsDbghelpSpec.EXCEPTION_FLT_DIVIDE_BY_ZERO or
        dbghelp.EXCEPTION_FLT_OVERFLOW != WindowsDbghelpSpec.EXCEPTION_FLT_OVERFLOW or
        dbghelp.EXCEPTION_FLT_UNDERFLOW != WindowsDbghelpSpec.EXCEPTION_FLT_UNDERFLOW or
        dbghelp.CONTROL_C_EXIT != WindowsDbghelpSpec.CONTROL_C_EXIT)
        return error.InvalidExceptionCodes;

    if (dbghelp.TH32CS_SNAPTHREAD != WindowsDbghelpSpec.TH32CS_SNAPTHREAD or
        dbghelp.IMAGE_FILE_MACHINE_I386 != WindowsDbghelpSpec.IMAGE_FILE_MACHINE_I386 or
        dbghelp.IMAGE_FILE_MACHINE_AMD64 != WindowsDbghelpSpec.IMAGE_FILE_MACHINE_AMD64 or
        dbghelp.CONTEXT_AMD64 != WindowsDbghelpSpec.CONTEXT_AMD64)
        return error.InvalidSnapshottingConstants;

    if (dbghelp.SYMOPT_CASE_INSENSITIVE != WindowsDbghelpSpec.SYMOPT_CASE_INSENSITIVE or
        dbghelp.SYMOPT_UNDNAME != WindowsDbghelpSpec.SYMOPT_UNDNAME or
        dbghelp.SYMOPT_DEBUG != WindowsDbghelpSpec.SYMOPT_DEBUG or
        dbghelp.SYMOPT_ALLOW_ZERO_ADDRESS != WindowsDbghelpSpec.SYMOPT_ALLOW_ZERO_ADDRESS)
        return error.InvalidSymbolOptions;
}

pub fn validateDbghelpStructSizes() DbghelpAbiError!void {
    if (@hasDecl(dbghelp, "M128A")) {
        if (@sizeOf(dbghelp.M128A) != WindowsDbghelpSpec.sizeof_M128A)
            return error.InvalidM128ASize;
    }
    if (@hasDecl(dbghelp, "XSAVE_FORMAT")) {
        if (@sizeOf(dbghelp.XSAVE_FORMAT) != WindowsDbghelpSpec.sizeof_XSAVE_FORMAT)
            return error.InvalidXSaveFormatSize;
    }
    if (@sizeOf(dbghelp.CONTEXT) != WindowsDbghelpSpec.sizeof_CONTEXT)
        return error.InvalidContextSize;
    if (@sizeOf(dbghelp.EXCEPTION_RECORD) != WindowsDbghelpSpec.sizeof_EXCEPTION_RECORD)
        return error.InvalidExceptionRecordSize;
    if (@sizeOf(dbghelp.EXCEPTION_POINTERS) != WindowsDbghelpSpec.sizeof_EXCEPTION_POINTERS)
        return error.InvalidExceptionPointersSize;
    if (@sizeOf(dbghelp.NT_TIB) != WindowsDbghelpSpec.sizeof_NT_TIB)
        return error.InvalidNtTibSize;
    if (@sizeOf(dbghelp.SYMBOL_INFO) != WindowsDbghelpSpec.sizeof_SYMBOL_INFO)
        return error.InvalidSymbolInfoSize;
    if (@sizeOf(dbghelp.SYMBOL_INFOW) != WindowsDbghelpSpec.sizeof_SYMBOL_INFOW)
        return error.InvalidSymbolInfoWSize;
    if (@sizeOf(dbghelp.IMAGEHLP_LINE64) != WindowsDbghelpSpec.sizeof_IMAGEHLP_LINE64)
        return error.InvalidImagehlpLine64Size;
    if (@sizeOf(dbghelp.IMAGEHLP_LINEW64) != WindowsDbghelpSpec.sizeof_IMAGEHLP_LINEW64)
        return error.InvalidImagehlpLineW64Size;
    if (@sizeOf(dbghelp.THREADENTRY32) != WindowsDbghelpSpec.sizeof_THREADENTRY32)
        return error.InvalidThreadEntry32Size;
    if (@sizeOf(dbghelp.ADDRESS64) != WindowsDbghelpSpec.sizeof_ADDRESS64)
        return error.InvalidAddress64Size;
    if (@sizeOf(dbghelp.KDHELP64) != WindowsDbghelpSpec.sizeof_KDHELP64)
        return error.InvalidKdHelp64Size;
    if (@sizeOf(dbghelp.STACKFRAME64) != WindowsDbghelpSpec.sizeof_STACKFRAME64)
        return error.InvalidStackFrame64Size;
    if (@sizeOf(dbghelp.LUID) != WindowsDbghelpSpec.sizeof_LUID)
        return error.InvalidLuidSize;
    if (@sizeOf(dbghelp.LUID_AND_ATTRIBUTES) != WindowsDbghelpSpec.sizeof_LUID_AND_ATTRIBUTES)
        return error.InvalidLuidAndAttributesSize;
    if (@sizeOf(dbghelp.TOKEN_PRIVILEGES) != WindowsDbghelpSpec.sizeof_TOKEN_PRIVILEGES)
        return error.InvalidTokenPrivilegesSize;
    if (@sizeOf(dbghelp.VS_FIXEDFILEINFO) != WindowsDbghelpSpec.sizeof_VS_FIXEDFILEINFO)
        return error.InvalidVsFixedFileInfoSize;
    if (@sizeOf(dbghelp.MINIDUMP_EXCEPTION_INFORMATION) != WindowsDbghelpSpec.sizeof_MINIDUMP_EXCEPTION_INFORMATION)
        return error.InvalidMiniDumpExceptionInformationSize;
    if (@sizeOf(dbghelp.MINIDUMP_EXCEPTION_INFORMATION64) != WindowsDbghelpSpec.sizeof_MINIDUMP_EXCEPTION_INFORMATION64)
        return error.InvalidMiniDumpExceptionInformation64Size;
    if (@sizeOf(dbghelp.MINIDUMP_USER_STREAM) != WindowsDbghelpSpec.sizeof_MINIDUMP_USER_STREAM)
        return error.InvalidMiniDumpUserStreamSize;
    if (@sizeOf(dbghelp.MINIDUMP_USER_STREAM_INFORMATION) != WindowsDbghelpSpec.sizeof_MINIDUMP_USER_STREAM_INFORMATION)
        return error.InvalidMiniDumpUserStreamInformationSize;
}

pub fn validateAll() DbghelpAbiError!void {
    try validateDbghelpConstants();
    try validateDbghelpStructSizes();
}

fn reportDbghelpSizes() void {
    std.debug.print(
        \\================================================================================
        \\ Dbghelp Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "EXCEPTION_RECORD", .spec = WindowsDbghelpSpec.sizeof_EXCEPTION_RECORD, .zig = @sizeOf(dbghelp.EXCEPTION_RECORD) },
        .{ .name = "EXCEPTION_POINTERS", .spec = WindowsDbghelpSpec.sizeof_EXCEPTION_POINTERS, .zig = @sizeOf(dbghelp.EXCEPTION_POINTERS) },
        .{ .name = "CONTEXT", .spec = WindowsDbghelpSpec.sizeof_CONTEXT, .zig = @sizeOf(dbghelp.CONTEXT) },
        .{ .name = "NT_TIB", .spec = WindowsDbghelpSpec.sizeof_NT_TIB, .zig = @sizeOf(dbghelp.NT_TIB) },
        .{ .name = "SYMBOL_INFO", .spec = WindowsDbghelpSpec.sizeof_SYMBOL_INFO, .zig = @sizeOf(dbghelp.SYMBOL_INFO) },
        .{ .name = "SYMBOL_INFOW", .spec = WindowsDbghelpSpec.sizeof_SYMBOL_INFOW, .zig = @sizeOf(dbghelp.SYMBOL_INFOW) },
        .{ .name = "IMAGEHLP_LINE64", .spec = WindowsDbghelpSpec.sizeof_IMAGEHLP_LINE64, .zig = @sizeOf(dbghelp.IMAGEHLP_LINE64) },
        .{ .name = "IMAGEHLP_LINEW64", .spec = WindowsDbghelpSpec.sizeof_IMAGEHLP_LINEW64, .zig = @sizeOf(dbghelp.IMAGEHLP_LINEW64) },
        .{ .name = "THREADENTRY32", .spec = WindowsDbghelpSpec.sizeof_THREADENTRY32, .zig = @sizeOf(dbghelp.THREADENTRY32) },
        .{ .name = "ADDRESS64", .spec = WindowsDbghelpSpec.sizeof_ADDRESS64, .zig = @sizeOf(dbghelp.ADDRESS64) },
        .{ .name = "KDHELP64", .spec = WindowsDbghelpSpec.sizeof_KDHELP64, .zig = @sizeOf(dbghelp.KDHELP64) },
        .{ .name = "STACKFRAME64", .spec = WindowsDbghelpSpec.sizeof_STACKFRAME64, .zig = @sizeOf(dbghelp.STACKFRAME64) },
        .{ .name = "LUID", .spec = WindowsDbghelpSpec.sizeof_LUID, .zig = @sizeOf(dbghelp.LUID) },
        .{ .name = "LUID_AND_ATTRIBUTES", .spec = WindowsDbghelpSpec.sizeof_LUID_AND_ATTRIBUTES, .zig = @sizeOf(dbghelp.LUID_AND_ATTRIBUTES) },
        .{ .name = "TOKEN_PRIVILEGES", .spec = WindowsDbghelpSpec.sizeof_TOKEN_PRIVILEGES, .zig = @sizeOf(dbghelp.TOKEN_PRIVILEGES) },
        .{ .name = "VS_FIXEDFILEINFO", .spec = WindowsDbghelpSpec.sizeof_VS_FIXEDFILEINFO, .zig = @sizeOf(dbghelp.VS_FIXEDFILEINFO) },
        .{ .name = "MINIDUMP_EXCEPTION_INFORMATION", .spec = WindowsDbghelpSpec.sizeof_MINIDUMP_EXCEPTION_INFORMATION, .zig = @sizeOf(dbghelp.MINIDUMP_EXCEPTION_INFORMATION) },
        .{ .name = "MINIDUMP_EXCEPTION_INFORMATION64", .spec = WindowsDbghelpSpec.sizeof_MINIDUMP_EXCEPTION_INFORMATION64, .zig = @sizeOf(dbghelp.MINIDUMP_EXCEPTION_INFORMATION64) },
        .{ .name = "MINIDUMP_USER_STREAM", .spec = WindowsDbghelpSpec.sizeof_MINIDUMP_USER_STREAM, .zig = @sizeOf(dbghelp.MINIDUMP_USER_STREAM) },
        .{ .name = "MINIDUMP_USER_STREAM_INFORMATION", .spec = WindowsDbghelpSpec.sizeof_MINIDUMP_USER_STREAM_INFORMATION, .zig = @sizeOf(dbghelp.MINIDUMP_USER_STREAM_INFORMATION) },
    };
    inline for (table) |entry| {
        std.debug.print(
            \\ {s:<38} | {d:<10} | {d:<14}
            \\
        , .{ entry.name, entry.spec, entry.zig });
    }
    if (comptime @hasDecl(dbghelp, "M128A")) {
        std.debug.print(
            \\ {s:<38} | {d:<10} | {d:<14}
            \\
        , .{ "M128A", WindowsDbghelpSpec.sizeof_M128A, @sizeOf(dbghelp.M128A) });
    }
    if (comptime @hasDecl(dbghelp, "XSAVE_FORMAT")) {
        std.debug.print(
            \\ {s:<38} | {d:<10} | {d:<14}
            \\
        , .{ "XSAVE_FORMAT", WindowsDbghelpSpec.sizeof_XSAVE_FORMAT, @sizeOf(dbghelp.XSAVE_FORMAT) });
    }
    std.debug.print(
        \\================================================================================
        \\
    , .{});
}

pub export fn rosette_validate_dbghelp() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidExceptionCodes => 1,
        error.InvalidSnapshottingConstants => 2,
        error.InvalidSymbolOptions => 3,
        error.InvalidM128ASize => 4,
        error.InvalidXSaveFormatSize => 5,
        error.InvalidContextSize => 6,
        error.InvalidExceptionRecordSize => 7,
        error.InvalidExceptionPointersSize => 8,
        error.InvalidNtTibSize => 9,
        error.InvalidSymbolInfoSize => 10,
        error.InvalidSymbolInfoWSize => 11,
        error.InvalidImagehlpLine64Size => 12,
        error.InvalidImagehlpLineW64Size => 13,
        error.InvalidThreadEntry32Size => 14,
        error.InvalidAddress64Size => 15,
        error.InvalidKdHelp64Size => 16,
        error.InvalidStackFrame64Size => 17,
        error.InvalidLuidSize => 18,
        error.InvalidLuidAndAttributesSize => 19,
        error.InvalidTokenPrivilegesSize => 20,
        error.InvalidVsFixedFileInfoSize => 21,
        error.InvalidMiniDumpExceptionInformationSize => 22,
        error.InvalidMiniDumpExceptionInformation64Size => 23,
        error.InvalidMiniDumpUserStreamSize => 24,
        error.InvalidMiniDumpUserStreamInformationSize => 25,
    };
    return 0;
}

pub export fn rosette_dbghelp_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidExceptionCodes",
        2 => "InvalidSnapshottingConstants",
        3 => "InvalidSymbolOptions",
        4 => "InvalidM128ASize",
        5 => "InvalidXSaveFormatSize",
        6 => "InvalidContextSize",
        7 => "InvalidExceptionRecordSize",
        8 => "InvalidExceptionPointersSize",
        9 => "InvalidNtTibSize",
        10 => "InvalidSymbolInfoSize",
        11 => "InvalidSymbolInfoWSize",
        12 => "InvalidImagehlpLine64Size",
        13 => "InvalidImagehlpLineW64Size",
        14 => "InvalidThreadEntry32Size",
        15 => "InvalidAddress64Size",
        16 => "InvalidKdHelp64Size",
        17 => "InvalidStackFrame64Size",
        18 => "InvalidLuidSize",
        19 => "InvalidLuidAndAttributesSize",
        20 => "InvalidTokenPrivilegesSize",
        21 => "InvalidVsFixedFileInfoSize",
        22 => "InvalidMiniDumpExceptionInformationSize",
        23 => "InvalidMiniDumpExceptionInformation64Size",
        24 => "InvalidMiniDumpUserStreamSize",
        25 => "InvalidMiniDumpUserStreamInformationSize",
        else => "UnknownDbghelpFailure",
    };
}

pub export fn rosette_print_dbghelp_report() void {
    reportDbghelpSizes();
}

test "dbghelp.h matches Windows spec constants and sizes" {
    try validateAll();
}
