const std = @import("std");

const shims = @import("win32_shim_surface");

pub const ShimSurfaceError = error{
    InitCommonControlsExSizeMismatch,
    IccListViewClassesMismatch,
    IccBarClassesMismatch,
    IccTabClassesMismatch,
    DwmWindowCornerPreferenceMismatch,
    DwmRoundCornerMismatch,
    DwmSystemBackdropTypeMismatch,
    DwmMainWindowBackdropMismatch,
    SystemTimeSizeMismatch,
    TimeZoneInformationSizeMismatch,
    TimecapsSizeMismatch,
    TimerrBaseMismatch,
    TimerrNoErrorMismatch,
    TimerrNoCanDoMismatch,
    CpUtf8Mismatch,
    FormatMessageFromSystemMismatch,
    LangEnglishMismatch,
    SublangEnglishUsMismatch,
    TcharSizeMismatch,
    WindowsxGetXLParamMismatch,
    WindowsxGetYLParamMismatch,
    ExtractIconSignatureMismatch,
    ShellAboutSignatureMismatch,
    ConioKbhitSignatureMismatch,
    ConioGetchSignatureMismatch,
    ConioGetcheSignatureMismatch,
    ArmCompatInt64SizeMismatch,
    ArmCompatUint64SizeMismatch,
};

pub const WindowsShimSurfaceSpec = struct {
    pub const sizeof_INITCOMMONCONTROLSEX: comptime_int = 8;
    pub const ICC_LISTVIEW_CLASSES: comptime_int = 0x00000001;
    pub const ICC_BAR_CLASSES: comptime_int = 0x00000004;
    pub const ICC_TAB_CLASSES: comptime_int = 0x00000008;

    pub const DWMWA_WINDOW_CORNER_PREFERENCE: comptime_int = 33;
    pub const DWMWCP_ROUND: comptime_int = 2;
    pub const DWMWA_SYSTEMBACKDROP_TYPE: comptime_int = 38;
    pub const DWMSBT_MAINWINDOW: comptime_int = 2;

    pub const sizeof_SYSTEMTIME: comptime_int = 16;
    pub const sizeof_TIME_ZONE_INFORMATION: comptime_int = 172;
    pub const sizeof_TIMECAPS: comptime_int = 8;
    pub const TIMERR_BASE: comptime_int = 96;
    pub const TIMERR_NOERROR: comptime_int = 0;
    pub const TIMERR_NOCANDO: comptime_int = 97;
    pub const CP_UTF8: comptime_int = 65001;
    pub const FORMAT_MESSAGE_FROM_SYSTEM: comptime_int = 0x00001000;
    pub const LANG_ENGLISH: comptime_int = 0x09;
    pub const SUBLANG_ENGLISH_US: comptime_int = 0x01;

    pub const sizeof_TCHAR: comptime_int = 1;
    pub const function_pointer_size: comptime_int = @sizeOf(usize);
    pub const sizeof_arm_compat_i64: comptime_int = 8;
    pub const sizeof_arm_compat_u64: comptime_int = 8;
    pub const sample_lparam: comptime_int = 0x12345678;
    pub const sample_x: comptime_int = 0x5678;
    pub const sample_y: comptime_int = 0x1234;
};

pub fn validateAll() ShimSurfaceError!void {
    if (@sizeOf(shims.INITCOMMONCONTROLSEX) != WindowsShimSurfaceSpec.sizeof_INITCOMMONCONTROLSEX)
        return error.InitCommonControlsExSizeMismatch;
    if (shims.ICC_LISTVIEW_CLASSES != WindowsShimSurfaceSpec.ICC_LISTVIEW_CLASSES)
        return error.IccListViewClassesMismatch;
    if (shims.ICC_BAR_CLASSES != WindowsShimSurfaceSpec.ICC_BAR_CLASSES)
        return error.IccBarClassesMismatch;
    if (shims.ICC_TAB_CLASSES != WindowsShimSurfaceSpec.ICC_TAB_CLASSES)
        return error.IccTabClassesMismatch;

    if (shims.DWMWA_WINDOW_CORNER_PREFERENCE != WindowsShimSurfaceSpec.DWMWA_WINDOW_CORNER_PREFERENCE)
        return error.DwmWindowCornerPreferenceMismatch;
    if (shims.DWMWCP_ROUND != WindowsShimSurfaceSpec.DWMWCP_ROUND)
        return error.DwmRoundCornerMismatch;
    if (shims.DWMWA_SYSTEMBACKDROP_TYPE != WindowsShimSurfaceSpec.DWMWA_SYSTEMBACKDROP_TYPE)
        return error.DwmSystemBackdropTypeMismatch;
    if (shims.DWMSBT_MAINWINDOW != WindowsShimSurfaceSpec.DWMSBT_MAINWINDOW)
        return error.DwmMainWindowBackdropMismatch;

    if (@sizeOf(shims.SYSTEMTIME) != WindowsShimSurfaceSpec.sizeof_SYSTEMTIME)
        return error.SystemTimeSizeMismatch;
    if (@sizeOf(shims.TIME_ZONE_INFORMATION) != WindowsShimSurfaceSpec.sizeof_TIME_ZONE_INFORMATION)
        return error.TimeZoneInformationSizeMismatch;
    if (@sizeOf(shims.TIMECAPS) != WindowsShimSurfaceSpec.sizeof_TIMECAPS)
        return error.TimecapsSizeMismatch;
    if (shims.TIMERR_BASE != WindowsShimSurfaceSpec.TIMERR_BASE)
        return error.TimerrBaseMismatch;
    if (shims.TIMERR_NOERROR != WindowsShimSurfaceSpec.TIMERR_NOERROR)
        return error.TimerrNoErrorMismatch;
    if (shims.TIMERR_NOCANDO != WindowsShimSurfaceSpec.TIMERR_NOCANDO)
        return error.TimerrNoCanDoMismatch;
    if (shims.CP_UTF8 != WindowsShimSurfaceSpec.CP_UTF8)
        return error.CpUtf8Mismatch;
    if (shims.FORMAT_MESSAGE_FROM_SYSTEM != WindowsShimSurfaceSpec.FORMAT_MESSAGE_FROM_SYSTEM)
        return error.FormatMessageFromSystemMismatch;
    if (shims.LANG_ENGLISH != WindowsShimSurfaceSpec.LANG_ENGLISH)
        return error.LangEnglishMismatch;
    if (shims.SUBLANG_ENGLISH_US != WindowsShimSurfaceSpec.SUBLANG_ENGLISH_US)
        return error.SublangEnglishUsMismatch;

    if (@sizeOf(shims.TCHAR) != WindowsShimSurfaceSpec.sizeof_TCHAR)
        return error.TcharSizeMismatch;
    if (shims.rosette_windowsx_get_x_lparam(WindowsShimSurfaceSpec.sample_lparam) != WindowsShimSurfaceSpec.sample_x)
        return error.WindowsxGetXLParamMismatch;
    if (shims.rosette_windowsx_get_y_lparam(WindowsShimSurfaceSpec.sample_lparam) != WindowsShimSurfaceSpec.sample_y)
        return error.WindowsxGetYLParamMismatch;

    if (@sizeOf(shims.rosette_extract_icon_a_fn) != WindowsShimSurfaceSpec.function_pointer_size)
        return error.ExtractIconSignatureMismatch;
    if (@sizeOf(shims.rosette_shell_about_a_fn) != WindowsShimSurfaceSpec.function_pointer_size)
        return error.ShellAboutSignatureMismatch;
    if (@sizeOf(shims.rosette_conio_kbhit_fn) != WindowsShimSurfaceSpec.function_pointer_size)
        return error.ConioKbhitSignatureMismatch;
    if (@sizeOf(shims.rosette_conio_getch_fn) != WindowsShimSurfaceSpec.function_pointer_size)
        return error.ConioGetchSignatureMismatch;
    if (@sizeOf(shims.rosette_conio_getche_fn) != WindowsShimSurfaceSpec.function_pointer_size)
        return error.ConioGetcheSignatureMismatch;
    if (@sizeOf(shims.rosette_arm_compat_i64) != WindowsShimSurfaceSpec.sizeof_arm_compat_i64)
        return error.ArmCompatInt64SizeMismatch;
    if (@sizeOf(shims.rosette_arm_compat_u64) != WindowsShimSurfaceSpec.sizeof_arm_compat_u64)
        return error.ArmCompatUint64SizeMismatch;
}

pub export fn rosette_validate_shim_surface() c_int {
    validateAll() catch |err| return switch (err) {
        error.InitCommonControlsExSizeMismatch => 1,
        error.IccListViewClassesMismatch => 2,
        error.IccBarClassesMismatch => 3,
        error.IccTabClassesMismatch => 4,
        error.DwmWindowCornerPreferenceMismatch => 5,
        error.DwmRoundCornerMismatch => 6,
        error.DwmSystemBackdropTypeMismatch => 7,
        error.DwmMainWindowBackdropMismatch => 8,
        error.SystemTimeSizeMismatch => 9,
        error.TimeZoneInformationSizeMismatch => 10,
        error.TimecapsSizeMismatch => 11,
        error.TimerrBaseMismatch => 12,
        error.TimerrNoErrorMismatch => 13,
        error.TimerrNoCanDoMismatch => 14,
        error.CpUtf8Mismatch => 15,
        error.FormatMessageFromSystemMismatch => 16,
        error.LangEnglishMismatch => 17,
        error.SublangEnglishUsMismatch => 18,
        error.TcharSizeMismatch => 19,
        error.WindowsxGetXLParamMismatch => 20,
        error.WindowsxGetYLParamMismatch => 21,
        error.ExtractIconSignatureMismatch => 22,
        error.ShellAboutSignatureMismatch => 23,
        error.ConioKbhitSignatureMismatch => 24,
        error.ConioGetchSignatureMismatch => 25,
        error.ConioGetcheSignatureMismatch => 26,
        error.ArmCompatInt64SizeMismatch => 27,
        error.ArmCompatUint64SizeMismatch => 28,
    };
    return 0;
}

pub export fn rosette_shim_surface_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InitCommonControlsExSizeMismatch",
        2 => "IccListViewClassesMismatch",
        3 => "IccBarClassesMismatch",
        4 => "IccTabClassesMismatch",
        5 => "DwmWindowCornerPreferenceMismatch",
        6 => "DwmRoundCornerMismatch",
        7 => "DwmSystemBackdropTypeMismatch",
        8 => "DwmMainWindowBackdropMismatch",
        9 => "SystemTimeSizeMismatch",
        10 => "TimeZoneInformationSizeMismatch",
        11 => "TimecapsSizeMismatch",
        12 => "TimerrBaseMismatch",
        13 => "TimerrNoErrorMismatch",
        14 => "TimerrNoCanDoMismatch",
        15 => "CpUtf8Mismatch",
        16 => "FormatMessageFromSystemMismatch",
        17 => "LangEnglishMismatch",
        18 => "SublangEnglishUsMismatch",
        19 => "TcharSizeMismatch",
        20 => "WindowsxGetXLParamMismatch",
        21 => "WindowsxGetYLParamMismatch",
        22 => "ExtractIconSignatureMismatch",
        23 => "ShellAboutSignatureMismatch",
        24 => "ConioKbhitSignatureMismatch",
        25 => "ConioGetchSignatureMismatch",
        26 => "ConioGetcheSignatureMismatch",
        27 => "ArmCompatInt64SizeMismatch",
        28 => "ArmCompatUint64SizeMismatch",
        else => "UnknownShimSurfaceFailure",
    };
}

pub export fn rosette_print_shim_surface_report() void {
    std.debug.print(
        \\================================================================================
        \\ Shim Surface ABI Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ INITCOMMONCONTROLSEX size      : {d} (spec: {d})
        \\ ICC_LISTVIEW_CLASSES           : 0x{x:0>8} (spec: 0x{x:0>8})
        \\ ICC_BAR_CLASSES                : 0x{x:0>8} (spec: 0x{x:0>8})
        \\ ICC_TAB_CLASSES                : 0x{x:0>8} (spec: 0x{x:0>8})
        \\ DWMWA_WINDOW_CORNER_PREFERENCE : {d} (spec: {d})
        \\ DWMWCP_ROUND                   : {d} (spec: {d})
        \\ DWMWA_SYSTEMBACKDROP_TYPE      : {d} (spec: {d})
        \\ DWMSBT_MAINWINDOW              : {d} (spec: {d})
        \\
    , .{
        @sizeOf(shims.INITCOMMONCONTROLSEX),
        WindowsShimSurfaceSpec.sizeof_INITCOMMONCONTROLSEX,
        @as(u32, @intCast(shims.ICC_LISTVIEW_CLASSES)),
        @as(u32, WindowsShimSurfaceSpec.ICC_LISTVIEW_CLASSES),
        @as(u32, @intCast(shims.ICC_BAR_CLASSES)),
        @as(u32, WindowsShimSurfaceSpec.ICC_BAR_CLASSES),
        @as(u32, @intCast(shims.ICC_TAB_CLASSES)),
        @as(u32, WindowsShimSurfaceSpec.ICC_TAB_CLASSES),
        shims.DWMWA_WINDOW_CORNER_PREFERENCE,
        WindowsShimSurfaceSpec.DWMWA_WINDOW_CORNER_PREFERENCE,
        shims.DWMWCP_ROUND,
        WindowsShimSurfaceSpec.DWMWCP_ROUND,
        shims.DWMWA_SYSTEMBACKDROP_TYPE,
        WindowsShimSurfaceSpec.DWMWA_SYSTEMBACKDROP_TYPE,
        shims.DWMSBT_MAINWINDOW,
        WindowsShimSurfaceSpec.DWMSBT_MAINWINDOW,
    });

    std.debug.print(
        \\ SYSTEMTIME size                : {d} (spec: {d})
        \\ TIME_ZONE_INFORMATION size     : {d} (spec: {d})
        \\ TIMECAPS size                  : {d} (spec: {d})
        \\ TIMERR_BASE                    : {d} (spec: {d})
        \\ TIMERR_NOERROR                 : {d} (spec: {d})
        \\ TIMERR_NOCANDO                 : {d} (spec: {d})
        \\ CP_UTF8                        : {d} (spec: {d})
        \\ FORMAT_MESSAGE_FROM_SYSTEM     : 0x{x:0>8} (spec: 0x{x:0>8})
        \\ LANG_ENGLISH                   : {d} (spec: {d})
        \\ SUBLANG_ENGLISH_US             : {d} (spec: {d})
        \\ TCHAR size                     : {d} (spec: {d})
        \\
    , .{
        @sizeOf(shims.SYSTEMTIME),
        WindowsShimSurfaceSpec.sizeof_SYSTEMTIME,
        @sizeOf(shims.TIME_ZONE_INFORMATION),
        WindowsShimSurfaceSpec.sizeof_TIME_ZONE_INFORMATION,
        @sizeOf(shims.TIMECAPS),
        WindowsShimSurfaceSpec.sizeof_TIMECAPS,
        shims.TIMERR_BASE,
        WindowsShimSurfaceSpec.TIMERR_BASE,
        shims.TIMERR_NOERROR,
        WindowsShimSurfaceSpec.TIMERR_NOERROR,
        shims.TIMERR_NOCANDO,
        WindowsShimSurfaceSpec.TIMERR_NOCANDO,
        shims.CP_UTF8,
        WindowsShimSurfaceSpec.CP_UTF8,
        @as(u32, @intCast(shims.FORMAT_MESSAGE_FROM_SYSTEM)),
        @as(u32, WindowsShimSurfaceSpec.FORMAT_MESSAGE_FROM_SYSTEM),
        shims.LANG_ENGLISH,
        WindowsShimSurfaceSpec.LANG_ENGLISH,
        shims.SUBLANG_ENGLISH_US,
        WindowsShimSurfaceSpec.SUBLANG_ENGLISH_US,
        @sizeOf(shims.TCHAR),
        WindowsShimSurfaceSpec.sizeof_TCHAR,
    });

    std.debug.print(
        \\ GET_X_LPARAM(0x{x})            : {d} (spec: {d})
        \\ GET_Y_LPARAM(0x{x})            : {d} (spec: {d})
        \\ sizeof(ExtractIconA fn ptr)    : {d} (spec: {d})
        \\ sizeof(ShellAboutA fn ptr)     : {d} (spec: {d})
        \\ sizeof(kbhit fn ptr)           : {d} (spec: {d})
        \\ sizeof(getch fn ptr)           : {d} (spec: {d})
        \\ sizeof(getche fn ptr)          : {d} (spec: {d})
        \\ sizeof(__int64 shim type)      : {d} (spec: {d})
        \\ sizeof(__uint64 shim type)     : {d} (spec: {d})
        \\
    , .{
        WindowsShimSurfaceSpec.sample_lparam,
        shims.rosette_windowsx_get_x_lparam(WindowsShimSurfaceSpec.sample_lparam),
        WindowsShimSurfaceSpec.sample_x,
        WindowsShimSurfaceSpec.sample_lparam,
        shims.rosette_windowsx_get_y_lparam(WindowsShimSurfaceSpec.sample_lparam),
        WindowsShimSurfaceSpec.sample_y,
        @sizeOf(shims.rosette_extract_icon_a_fn),
        WindowsShimSurfaceSpec.function_pointer_size,
        @sizeOf(shims.rosette_shell_about_a_fn),
        WindowsShimSurfaceSpec.function_pointer_size,
        @sizeOf(shims.rosette_conio_kbhit_fn),
        WindowsShimSurfaceSpec.function_pointer_size,
        @sizeOf(shims.rosette_conio_getch_fn),
        WindowsShimSurfaceSpec.function_pointer_size,
        @sizeOf(shims.rosette_conio_getche_fn),
        WindowsShimSurfaceSpec.function_pointer_size,
        @sizeOf(shims.rosette_arm_compat_i64),
        WindowsShimSurfaceSpec.sizeof_arm_compat_i64,
        @sizeOf(shims.rosette_arm_compat_u64),
        WindowsShimSurfaceSpec.sizeof_arm_compat_u64,
    });
}

test "shim surface ABI validation" {
    try validateAll();
}
