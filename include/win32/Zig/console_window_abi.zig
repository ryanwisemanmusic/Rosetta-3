const std = @import("std");
const win32_all = @import("win32_all");

pub const ConsoleWindowAbiError = error{
    InvalidMonitorInfoSize,
    InvalidMonitorInfoExASize,
    InvalidMonitorInfoExWSize,
    InvalidConsoleCursorInfoSize,
    InvalidMonitorInfoCbSize,
};

pub const WindowsConsoleWindowSpec = struct {
    pub const sizeof_MONITORINFO: comptime_int = 40;
    pub const sizeof_MONITORINFOEXA: comptime_int = 72;
    pub const sizeof_MONITORINFOEXW: comptime_int = 104;
    pub const sizeof_CONSOLE_CURSOR_INFO: comptime_int = 8;
};

pub fn validateConsoleWindowStructSizes() ConsoleWindowAbiError!void {
    if (@sizeOf(win32_all.MONITORINFO) != WindowsConsoleWindowSpec.sizeof_MONITORINFO)
        return error.InvalidMonitorInfoSize;
    if (@sizeOf(win32_all.MONITORINFOEXA) != WindowsConsoleWindowSpec.sizeof_MONITORINFOEXA)
        return error.InvalidMonitorInfoExASize;
    if (@sizeOf(win32_all.MONITORINFOEXW) != WindowsConsoleWindowSpec.sizeof_MONITORINFOEXW)
        return error.InvalidMonitorInfoExWSize;
    if (@sizeOf(win32_all.CONSOLE_CURSOR_INFO) != WindowsConsoleWindowSpec.sizeof_CONSOLE_CURSOR_INFO)
        return error.InvalidConsoleCursorInfoSize;
}

pub fn validateConsoleWindowBehavior() ConsoleWindowAbiError!void {
    const mi: win32_all.MONITORINFO = .{
        .cbSize = @sizeOf(win32_all.MONITORINFO),
        .rcMonitor = undefined,
        .rcWork = undefined,
        .dwFlags = 0,
    };
    if (mi.cbSize != @sizeOf(win32_all.MONITORINFO))
        return error.InvalidMonitorInfoCbSize;
}

pub fn validateAll() ConsoleWindowAbiError!void {
    try validateConsoleWindowStructSizes();
    try validateConsoleWindowBehavior();
}

pub export fn rosette_validate_console_window_abi() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidMonitorInfoSize => 1,
        error.InvalidMonitorInfoExASize => 2,
        error.InvalidMonitorInfoExWSize => 3,
        error.InvalidConsoleCursorInfoSize => 4,
        error.InvalidMonitorInfoCbSize => 5,
    };
    return 0;
}

pub export fn rosette_console_window_abi_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidMonitorInfoSize",
        2 => "InvalidMonitorInfoExASize",
        3 => "InvalidMonitorInfoExWSize",
        4 => "InvalidConsoleCursorInfoSize",
        5 => "InvalidMonitorInfoCbSize",
        else => "UnknownConsoleWindowAbiFailure",
    };
}

pub export fn rosette_print_console_window_abi_report() void {
    std.debug.print(
        \\Console/Window ABI Report:
        \\  sizeof(MONITORINFO)         = {d}  (spec: {d})
        \\  sizeof(MONITORINFOEXA)      = {d}  (spec: {d})
        \\  sizeof(MONITORINFOEXW)      = {d}  (spec: {d})
        \\  sizeof(CONSOLE_CURSOR_INFO) = {d}  (spec: {d})
        \\
    , .{
        @sizeOf(win32_all.MONITORINFO),         WindowsConsoleWindowSpec.sizeof_MONITORINFO,
        @sizeOf(win32_all.MONITORINFOEXA),      WindowsConsoleWindowSpec.sizeof_MONITORINFOEXA,
        @sizeOf(win32_all.MONITORINFOEXW),      WindowsConsoleWindowSpec.sizeof_MONITORINFOEXW,
        @sizeOf(win32_all.CONSOLE_CURSOR_INFO), WindowsConsoleWindowSpec.sizeof_CONSOLE_CURSOR_INFO,
    });
}

test "console/window structs match Win32 spec" {
    try validateAll();
}
