const std = @import("std");

const win32_all = @import("win32_pending");

pub const IoAbiError = error{
    InvalidStdHandleConstants,
    InvalidAttachParentProcess,
    InvalidHandleFlags,
    InvalidColorConstants,
    InvalidCtrlEventConstants,
    InvalidConsoleInputFlags,
    InvalidConsoleOutputFlags,
    InvalidHeapFlags,
    InvalidMemConstants,
    InvalidPageConstants,
    InvalidPipeFlags,
    InvalidPipeAccessFlags,
    InvalidPipeUnlimitedInstances,
    InvalidErrorPipeBusy,
    InvalidCoordSize,
    InvalidSmallRectSize,
    InvalidConsoleScreenBufferInfoSize,
    InvalidMemoryBasicInformation32Size,
    InvalidMemoryBasicInformation64Size,
};

pub const WindowsIoSpec = struct {
    pub const STD_INPUT_HANDLE: comptime_int = 0xFFFFFFF6;
    pub const STD_OUTPUT_HANDLE: comptime_int = 0xFFFFFFF5;
    pub const STD_ERROR_HANDLE: comptime_int = 0xFFFFFFF4;

    pub const ATTACH_PARENT_PROCESS: comptime_int = 0xFFFFFFFF;

    pub const HANDLE_FLAG_INHERIT: comptime_int = 0x00000001;
    pub const HANDLE_FLAG_PROTECT_FROM_CLOSE: comptime_int = 0x00000002;

    pub const FOREGROUND_BLUE: comptime_int = 0x0001;
    pub const FOREGROUND_GREEN: comptime_int = 0x0002;
    pub const FOREGROUND_RED: comptime_int = 0x0004;
    pub const FOREGROUND_INTENSITY: comptime_int = 0x0008;
    pub const BACKGROUND_BLUE: comptime_int = 0x0010;
    pub const BACKGROUND_GREEN: comptime_int = 0x0020;
    pub const BACKGROUND_RED: comptime_int = 0x0040;
    pub const BACKGROUND_INTENSITY: comptime_int = 0x0080;

    pub const CTRL_C_EVENT: comptime_int = 0;
    pub const CTRL_BREAK_EVENT: comptime_int = 1;
    pub const CTRL_CLOSE_EVENT: comptime_int = 2;

    pub const ENABLE_PROCESSED_INPUT: comptime_int = 0x0001;
    pub const ENABLE_LINE_INPUT: comptime_int = 0x0002;
    pub const ENABLE_ECHO_INPUT: comptime_int = 0x0004;
    pub const ENABLE_VIRTUAL_TERMINAL_INPUT: comptime_int = 0x0200;

    pub const ENABLE_PROCESSED_OUTPUT: comptime_int = 0x0001;
    pub const ENABLE_WRAP_AT_EOL_OUTPUT: comptime_int = 0x0002;
    pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: comptime_int = 0x0004;

    pub const HEAP_NO_SERIALIZE: comptime_int = 0x00000001;
    pub const HEAP_ZERO_MEMORY: comptime_int = 0x00000008;

    pub const MEM_COMMIT: comptime_int = 0x00001000;
    pub const MEM_RESERVE: comptime_int = 0x00002000;
    pub const MEM_RESET: comptime_int = 0x00080000;
    pub const MEM_DECOMMIT: comptime_int = 0x4000;
    pub const MEM_RELEASE: comptime_int = 0x8000;
    pub const MEM_FREE: comptime_int = 0x10000;
    pub const MEM_IMAGE: comptime_int = 0x1000000;
    pub const MEM_MAPPED: comptime_int = 0x40000;
    pub const MEM_PRIVATE: comptime_int = 0x20000;

    pub const PAGE_NOACCESS: comptime_int = 0x01;
    pub const PAGE_READONLY: comptime_int = 0x02;
    pub const PAGE_READWRITE: comptime_int = 0x04;
    pub const PAGE_EXECUTE: comptime_int = 0x10;
    pub const PAGE_EXECUTE_READ: comptime_int = 0x20;
    pub const PAGE_EXECUTE_READWRITE: comptime_int = 0x40;
    pub const PAGE_GUARD: comptime_int = 0x100;
    pub const PAGE_NOCACHE: comptime_int = 0x200;
    pub const PAGE_WRITECOMBINE: comptime_int = 0x400;

    pub const PIPE_WAIT: comptime_int = 0x00000000;
    pub const PIPE_NOWAIT: comptime_int = 0x00000001;

    pub const PIPE_ACCESS_INBOUND: comptime_int = 0x00000001;
    pub const PIPE_ACCESS_OUTBOUND: comptime_int = 0x00000002;
    pub const PIPE_ACCESS_DUPLEX: comptime_int = 0x00000003;

    pub const PIPE_UNLIMITED_INSTANCES: comptime_int = 255;

    pub const ERROR_PIPE_BUSY: comptime_int = 231;

    pub const sizeof_COORD: comptime_int = 4;
    pub const sizeof_SMALL_RECT: comptime_int = 8;
    pub const sizeof_CONSOLE_SCREEN_BUFFER_INFO: comptime_int = 22;
    pub const sizeof_MEMORY_BASIC_INFORMATION32: comptime_int = 28;
    pub const sizeof_MEMORY_BASIC_INFORMATION64: comptime_int = 56;
};

pub fn validateIoConstants() IoAbiError!void {
    if (win32_all.STD_INPUT_HANDLE != WindowsIoSpec.STD_INPUT_HANDLE or
        win32_all.STD_OUTPUT_HANDLE != WindowsIoSpec.STD_OUTPUT_HANDLE or
        win32_all.STD_ERROR_HANDLE != WindowsIoSpec.STD_ERROR_HANDLE)
        return error.InvalidStdHandleConstants;

    if (win32_all.ATTACH_PARENT_PROCESS != WindowsIoSpec.ATTACH_PARENT_PROCESS)
        return error.InvalidAttachParentProcess;

    if (win32_all.HANDLE_FLAG_INHERIT != WindowsIoSpec.HANDLE_FLAG_INHERIT or
        win32_all.HANDLE_FLAG_PROTECT_FROM_CLOSE != WindowsIoSpec.HANDLE_FLAG_PROTECT_FROM_CLOSE)
        return error.InvalidHandleFlags;

    if (win32_all.FOREGROUND_BLUE != WindowsIoSpec.FOREGROUND_BLUE or
        win32_all.FOREGROUND_GREEN != WindowsIoSpec.FOREGROUND_GREEN or
        win32_all.FOREGROUND_RED != WindowsIoSpec.FOREGROUND_RED or
        win32_all.FOREGROUND_INTENSITY != WindowsIoSpec.FOREGROUND_INTENSITY or
        win32_all.BACKGROUND_BLUE != WindowsIoSpec.BACKGROUND_BLUE or
        win32_all.BACKGROUND_GREEN != WindowsIoSpec.BACKGROUND_GREEN or
        win32_all.BACKGROUND_RED != WindowsIoSpec.BACKGROUND_RED or
        win32_all.BACKGROUND_INTENSITY != WindowsIoSpec.BACKGROUND_INTENSITY)
        return error.InvalidColorConstants;

    if (win32_all.CTRL_C_EVENT != WindowsIoSpec.CTRL_C_EVENT or
        win32_all.CTRL_BREAK_EVENT != WindowsIoSpec.CTRL_BREAK_EVENT or
        win32_all.CTRL_CLOSE_EVENT != WindowsIoSpec.CTRL_CLOSE_EVENT)
        return error.InvalidCtrlEventConstants;

    if (win32_all.ENABLE_PROCESSED_INPUT != WindowsIoSpec.ENABLE_PROCESSED_INPUT or
        win32_all.ENABLE_LINE_INPUT != WindowsIoSpec.ENABLE_LINE_INPUT or
        win32_all.ENABLE_ECHO_INPUT != WindowsIoSpec.ENABLE_ECHO_INPUT or
        win32_all.ENABLE_VIRTUAL_TERMINAL_INPUT != WindowsIoSpec.ENABLE_VIRTUAL_TERMINAL_INPUT)
        return error.InvalidConsoleInputFlags;

    if (win32_all.ENABLE_PROCESSED_OUTPUT != WindowsIoSpec.ENABLE_PROCESSED_OUTPUT or
        win32_all.ENABLE_WRAP_AT_EOL_OUTPUT != WindowsIoSpec.ENABLE_WRAP_AT_EOL_OUTPUT or
        win32_all.ENABLE_VIRTUAL_TERMINAL_PROCESSING != WindowsIoSpec.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
        return error.InvalidConsoleOutputFlags;

    if (win32_all.HEAP_NO_SERIALIZE != WindowsIoSpec.HEAP_NO_SERIALIZE or
        win32_all.HEAP_ZERO_MEMORY != WindowsIoSpec.HEAP_ZERO_MEMORY)
        return error.InvalidHeapFlags;

    if (win32_all.MEM_COMMIT != WindowsIoSpec.MEM_COMMIT or
        win32_all.MEM_RESERVE != WindowsIoSpec.MEM_RESERVE or
        win32_all.MEM_RESET != WindowsIoSpec.MEM_RESET or
        win32_all.MEM_DECOMMIT != WindowsIoSpec.MEM_DECOMMIT or
        win32_all.MEM_RELEASE != WindowsIoSpec.MEM_RELEASE or
        win32_all.MEM_FREE != WindowsIoSpec.MEM_FREE or
        win32_all.MEM_IMAGE != WindowsIoSpec.MEM_IMAGE or
        win32_all.MEM_MAPPED != WindowsIoSpec.MEM_MAPPED or
        win32_all.MEM_PRIVATE != WindowsIoSpec.MEM_PRIVATE)
        return error.InvalidMemConstants;

    if (win32_all.PAGE_NOACCESS != WindowsIoSpec.PAGE_NOACCESS or
        win32_all.PAGE_READONLY != WindowsIoSpec.PAGE_READONLY or
        win32_all.PAGE_READWRITE != WindowsIoSpec.PAGE_READWRITE or
        win32_all.PAGE_EXECUTE != WindowsIoSpec.PAGE_EXECUTE or
        win32_all.PAGE_EXECUTE_READ != WindowsIoSpec.PAGE_EXECUTE_READ or
        win32_all.PAGE_EXECUTE_READWRITE != WindowsIoSpec.PAGE_EXECUTE_READWRITE or
        win32_all.PAGE_GUARD != WindowsIoSpec.PAGE_GUARD or
        win32_all.PAGE_NOCACHE != WindowsIoSpec.PAGE_NOCACHE or
        win32_all.PAGE_WRITECOMBINE != WindowsIoSpec.PAGE_WRITECOMBINE)
        return error.InvalidPageConstants;

    if (win32_all.PIPE_WAIT != WindowsIoSpec.PIPE_WAIT or
        win32_all.PIPE_NOWAIT != WindowsIoSpec.PIPE_NOWAIT)
        return error.InvalidPipeFlags;

    if (win32_all.PIPE_ACCESS_INBOUND != WindowsIoSpec.PIPE_ACCESS_INBOUND or
        win32_all.PIPE_ACCESS_OUTBOUND != WindowsIoSpec.PIPE_ACCESS_OUTBOUND or
        win32_all.PIPE_ACCESS_DUPLEX != WindowsIoSpec.PIPE_ACCESS_DUPLEX)
        return error.InvalidPipeAccessFlags;

    if (win32_all.PIPE_UNLIMITED_INSTANCES != WindowsIoSpec.PIPE_UNLIMITED_INSTANCES)
        return error.InvalidPipeUnlimitedInstances;

    if (win32_all.ERROR_PIPE_BUSY != WindowsIoSpec.ERROR_PIPE_BUSY)
        return error.InvalidErrorPipeBusy;
}

pub fn validateIoStructSizes() IoAbiError!void {
    if (@sizeOf(win32_all.COORD) != WindowsIoSpec.sizeof_COORD)
        return error.InvalidCoordSize;
    if (@sizeOf(win32_all.SMALL_RECT) != WindowsIoSpec.sizeof_SMALL_RECT)
        return error.InvalidSmallRectSize;
    if (@sizeOf(win32_all.CONSOLE_SCREEN_BUFFER_INFO) != WindowsIoSpec.sizeof_CONSOLE_SCREEN_BUFFER_INFO)
        return error.InvalidConsoleScreenBufferInfoSize;
    if (@sizeOf(win32_all.MEMORY_BASIC_INFORMATION32) != WindowsIoSpec.sizeof_MEMORY_BASIC_INFORMATION32)
        return error.InvalidMemoryBasicInformation32Size;
    if (@sizeOf(win32_all.MEMORY_BASIC_INFORMATION64) != WindowsIoSpec.sizeof_MEMORY_BASIC_INFORMATION64)
        return error.InvalidMemoryBasicInformation64Size;
}

pub fn validateAll() IoAbiError!void {
    try validateIoConstants();
    try validateIoStructSizes();
}

fn reportIoSizes() void {
    std.debug.print(
        \\================================================================================
        \\ IO Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "COORD", .spec = WindowsIoSpec.sizeof_COORD, .zig = @sizeOf(win32_all.COORD) },
        .{ .name = "SMALL_RECT", .spec = WindowsIoSpec.sizeof_SMALL_RECT, .zig = @sizeOf(win32_all.SMALL_RECT) },
        .{ .name = "CONSOLE_SCREEN_BUFFER_INFO", .spec = WindowsIoSpec.sizeof_CONSOLE_SCREEN_BUFFER_INFO, .zig = @sizeOf(win32_all.CONSOLE_SCREEN_BUFFER_INFO) },
        .{ .name = "MEMORY_BASIC_INFORMATION32", .spec = WindowsIoSpec.sizeof_MEMORY_BASIC_INFORMATION32, .zig = @sizeOf(win32_all.MEMORY_BASIC_INFORMATION32) },
        .{ .name = "MEMORY_BASIC_INFORMATION64", .spec = WindowsIoSpec.sizeof_MEMORY_BASIC_INFORMATION64, .zig = @sizeOf(win32_all.MEMORY_BASIC_INFORMATION64) },
    };
    inline for (table) |entry| {
        std.debug.print(
            \\ {s:<38} | {d:<10} | {d:<14}
            \\
        , .{ entry.name, entry.spec, entry.zig });
    }
    std.debug.print(
        \\================================================================================
        \\
    , .{});
}

pub export fn rosetta3_print_io_report() void {
    reportIoSizes();
}

pub export fn rosetta3_validate_io() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidStdHandleConstants => 1,
        error.InvalidAttachParentProcess => 2,
        error.InvalidHandleFlags => 3,
        error.InvalidColorConstants => 4,
        error.InvalidCtrlEventConstants => 5,
        error.InvalidConsoleInputFlags => 6,
        error.InvalidConsoleOutputFlags => 7,
        error.InvalidHeapFlags => 8,
        error.InvalidMemConstants => 9,
        error.InvalidPageConstants => 10,
        error.InvalidPipeFlags => 11,
        error.InvalidPipeAccessFlags => 12,
        error.InvalidPipeUnlimitedInstances => 13,
        error.InvalidErrorPipeBusy => 14,
        error.InvalidCoordSize => 15,
        error.InvalidSmallRectSize => 16,
        error.InvalidConsoleScreenBufferInfoSize => 17,
        error.InvalidMemoryBasicInformation32Size => 18,
        error.InvalidMemoryBasicInformation64Size => 19,
    };
    return 0;
}

pub export fn rosetta3_io_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidStdHandleConstants",
        2 => "InvalidAttachParentProcess",
        3 => "InvalidHandleFlags",
        4 => "InvalidColorConstants",
        5 => "InvalidCtrlEventConstants",
        6 => "InvalidConsoleInputFlags",
        7 => "InvalidConsoleOutputFlags",
        8 => "InvalidHeapFlags",
        9 => "InvalidMemConstants",
        10 => "InvalidPageConstants",
        11 => "InvalidPipeFlags",
        12 => "InvalidPipeAccessFlags",
        13 => "InvalidPipeUnlimitedInstances",
        14 => "InvalidErrorPipeBusy",
        15 => "InvalidCoordSize",
        16 => "InvalidSmallRectSize",
        17 => "InvalidConsoleScreenBufferInfoSize",
        18 => "InvalidMemoryBasicInformation32Size",
        19 => "InvalidMemoryBasicInformation64Size",
        else => "UnknownIoFailure",
    };
}

test "io.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
