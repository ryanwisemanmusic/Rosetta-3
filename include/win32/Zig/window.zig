const std = @import("std");

const win32_all = @import("win32_all");
const window = win32_all;

pub const WindowAbiError = error{
    InvalidMbOk,
    InvalidMbOkCancel,
    InvalidMbAbortRetryIgnore,
    InvalidMbYesNo,
    InvalidMbYesNoCancel,
    InvalidMbRetryCancel,
    InvalidMbCancelTryContinue,
    InvalidMbIconExclamation,
    InvalidMbIconInformation,
    InvalidMbIconQuestion,
    InvalidMbIconError,
    InvalidMbDefButton1,
    InvalidMbDefButton2,
    InvalidMbDefButton3,
    InvalidMbApplModal,
    InvalidMbSystemModal,
    InvalidMbTaskModal,
    InvalidMbTopMost,
    InvalidIdAbort,
    InvalidIdCancel,
    InvalidIdContinue,
    InvalidIdIgnore,
    InvalidIdNo,
    InvalidIdOk,
    InvalidIdRetry,
    InvalidIdYes,
    InvalidWsOverlapped,
    InvalidWsPopup,
    InvalidWsChild,
    InvalidWsMinimize,
    InvalidWsVisible,
    InvalidWsDisabled,
    InvalidWsClipSiblings,
    InvalidWsClipChildren,
    InvalidWsCaption,
    InvalidWsBorder,
    InvalidWsDlgFrame,
    InvalidWsVScroll,
    InvalidWsHScroll,
    InvalidWsSysMenu,
    InvalidWsThickFrame,
    InvalidWsMinimizeBox,
    InvalidWsMaximizeBox,
    InvalidWsOverlappedWindow,
    InvalidCsVRedraw,
    InvalidCsHRedraw,
    InvalidPmNoRemove,
    InvalidPmRemove,
    InvalidWmNull,
    InvalidWmCreate,
    InvalidWmDestroy,
    InvalidWmClose,
    InvalidWmQuit,
    InvalidWmPaint,
    InvalidWmSize,
    InvalidWmMove,
    InvalidWmKeyDown,
    InvalidWmKeyUp,
    InvalidWmSysCommand,
    InvalidWmActivate,
    InvalidWaInactive,
    InvalidWaActive,
    InvalidWaClickActive,
    InvalidScKeyMenu,
    InvalidVkBack,
    InvalidVkTab,
    InvalidVkShift,
    InvalidVkControl,
    InvalidVkMenu,
    InvalidVkReturn,
    InvalidVkEscape,
    InvalidVkSpace,
    InvalidVkLeft,
    InvalidVkUp,
    InvalidVkRight,
    InvalidVkDown,
    InvalidVkDelete,
    InvalidSwHide,
    InvalidSwShowNormal,
    InvalidSwNormal,
    InvalidSwShowMinimized,
    InvalidSwShowMaximized,
    InvalidSwMaximize,
    InvalidSwShowNoActivate,
    InvalidSwShow,
    InvalidSwMinimize,
    InvalidSwRestore,
    InvalidSwShowDefault,
    InvalidSwForceMinimize,
    InvalidCwUseDefault,
    InvalidRectSize,
    InvalidPointSize,
    InvalidMsgSize,
    InvalidWndClassSize,
    InvalidWndClassExASize,
    InvalidWndClassExWSize,
};

pub const WindowsWindowSpec = struct {
    pub const MB_OK: comptime_int = 0x00000000;
    pub const MB_OKCANCEL: comptime_int = 0x00000001;
    pub const MB_ABORTRETRYIGNORE: comptime_int = 0x00000002;
    pub const MB_YESNO: comptime_int = 0x00000004;
    pub const MB_YESNOCANCEL: comptime_int = 0x00000003;
    pub const MB_RETRYCANCEL: comptime_int = 0x00000005;
    pub const MB_CANCELTRYCONTINUE: comptime_int = 0x00000006;
    pub const MB_ICONEXCLAMATION: comptime_int = 0x00000030;
    pub const MB_ICONINFORMATION: comptime_int = 0x00000040;
    pub const MB_ICONQUESTION: comptime_int = 0x00000020;
    pub const MB_ICONERROR: comptime_int = 0x00000010;
    pub const MB_DEFBUTTON1: comptime_int = 0x00000000;
    pub const MB_DEFBUTTON2: comptime_int = 0x00000100;
    pub const MB_DEFBUTTON3: comptime_int = 0x00000200;
    pub const MB_APPLMODAL: comptime_int = 0x00000000;
    pub const MB_SYSTEMMODAL: comptime_int = 0x00001000;
    pub const MB_TASKMODAL: comptime_int = 0x00002000;
    pub const MB_TOPMOST: comptime_int = 0x00040000;

    pub const IDABORT: comptime_int = 3;
    pub const IDCANCEL: comptime_int = 2;
    pub const IDCONTINUE: comptime_int = 11;
    pub const IDIGNORE: comptime_int = 5;
    pub const IDNO: comptime_int = 7;
    pub const IDOK: comptime_int = 1;
    pub const IDRETRY: comptime_int = 4;
    pub const IDYES: comptime_int = 6;

    pub const WS_OVERLAPPED: comptime_int = 0x00000000;
    pub const WS_POPUP: comptime_int = 0x80000000;
    pub const WS_CHILD: comptime_int = 0x40000000;
    pub const WS_MINIMIZE: comptime_int = 0x20000000;
    pub const WS_VISIBLE: comptime_int = 0x10000000;
    pub const WS_DISABLED: comptime_int = 0x08000000;
    pub const WS_CLIPSIBLINGS: comptime_int = 0x04000000;
    pub const WS_CLIPCHILDREN: comptime_int = 0x02000000;
    pub const WS_CAPTION: comptime_int = 0x00C00000;
    pub const WS_BORDER: comptime_int = 0x00800000;
    pub const WS_DLGFRAME: comptime_int = 0x00400000;
    pub const WS_VSCROLL: comptime_int = 0x00200000;
    pub const WS_HSCROLL: comptime_int = 0x00100000;
    pub const WS_SYSMENU: comptime_int = 0x00080000;
    pub const WS_THICKFRAME: comptime_int = 0x00040000;
    pub const WS_MINIMIZEBOX: comptime_int = 0x00020000;
    pub const WS_MAXIMIZEBOX: comptime_int = 0x00010000;
    pub const WS_OVERLAPPEDWINDOW: comptime_int = 0x00CF0000;

    pub const CS_VREDRAW: comptime_int = 0x0001;
    pub const CS_HREDRAW: comptime_int = 0x0002;

    pub const PM_NOREMOVE: comptime_int = 0x0000;
    pub const PM_REMOVE: comptime_int = 0x0001;

    pub const WM_NULL: comptime_int = 0x0000;
    pub const WM_CREATE: comptime_int = 0x0001;
    pub const WM_DESTROY: comptime_int = 0x0002;
    pub const WM_CLOSE: comptime_int = 0x0010;
    pub const WM_QUIT: comptime_int = 0x0012;
    pub const WM_PAINT: comptime_int = 0x000F;
    pub const WM_SIZE: comptime_int = 0x0005;
    pub const WM_MOVE: comptime_int = 0x0003;
    pub const WM_KEYDOWN: comptime_int = 0x0100;
    pub const WM_KEYUP: comptime_int = 0x0101;
    pub const WM_SYSCOMMAND: comptime_int = 0x0112;
    pub const WM_ACTIVATE: comptime_int = 0x0006;

    pub const WA_INACTIVE: comptime_int = 0;
    pub const WA_ACTIVE: comptime_int = 1;
    pub const WA_CLICKACTIVE: comptime_int = 2;

    pub const SC_KEYMENU: comptime_int = 0xF100;

    pub const VK_BACK: comptime_int = 0x08;
    pub const VK_TAB: comptime_int = 0x09;
    pub const VK_SHIFT: comptime_int = 0x10;
    pub const VK_CONTROL: comptime_int = 0x11;
    pub const VK_MENU: comptime_int = 0x12;
    pub const VK_RETURN: comptime_int = 0x0D;
    pub const VK_ESCAPE: comptime_int = 0x1B;
    pub const VK_SPACE: comptime_int = 0x20;
    pub const VK_LEFT: comptime_int = 0x25;
    pub const VK_UP: comptime_int = 0x26;
    pub const VK_RIGHT: comptime_int = 0x27;
    pub const VK_DOWN: comptime_int = 0x28;
    pub const VK_DELETE: comptime_int = 0x2E;

    pub const SW_HIDE: comptime_int = 0;
    pub const SW_SHOWNORMAL: comptime_int = 1;
    pub const SW_NORMAL: comptime_int = 1;
    pub const SW_SHOWMINIMIZED: comptime_int = 2;
    pub const SW_SHOWMAXIMIZED: comptime_int = 3;
    pub const SW_MAXIMIZE: comptime_int = 3;
    pub const SW_SHOWNOACTIVATE: comptime_int = 4;
    pub const SW_SHOW: comptime_int = 5;
    pub const SW_MINIMIZE: comptime_int = 6;
    pub const SW_RESTORE: comptime_int = 9;
    pub const SW_SHOWDEFAULT: comptime_int = 10;
    pub const SW_FORCEMINIMIZE: comptime_int = 11;

    pub const CW_USEDEFAULT: comptime_int = @as(c_int, @bitCast(@as(u32, 0x80000000)));

    pub const sizeof_RECT: comptime_int = 16;
    pub const sizeof_POINT: comptime_int = 8;
    pub const sizeof_MSG: comptime_int = 48;
    pub const sizeof_WNDCLASS: comptime_int = 48;
    pub const sizeof_WNDCLASSEXA: comptime_int = 52;
    pub const sizeof_WNDCLASSEXW: comptime_int = 52;
};

pub fn validateWindowConstants() WindowAbiError!void {
    if (window.MB_OK != WindowsWindowSpec.MB_OK) return error.InvalidMbOk;
    if (window.MB_OKCANCEL != WindowsWindowSpec.MB_OKCANCEL) return error.InvalidMbOkCancel;
    if (window.MB_ABORTRETRYIGNORE != WindowsWindowSpec.MB_ABORTRETRYIGNORE) return error.InvalidMbAbortRetryIgnore;
    if (window.MB_YESNO != WindowsWindowSpec.MB_YESNO) return error.InvalidMbYesNo;
    if (window.MB_YESNOCANCEL != WindowsWindowSpec.MB_YESNOCANCEL) return error.InvalidMbYesNoCancel;
    if (window.MB_RETRYCANCEL != WindowsWindowSpec.MB_RETRYCANCEL) return error.InvalidMbRetryCancel;
    if (window.MB_CANCELTRYCONTINUE != WindowsWindowSpec.MB_CANCELTRYCONTINUE) return error.InvalidMbCancelTryContinue;
    if (window.MB_ICONEXCLAMATION != WindowsWindowSpec.MB_ICONEXCLAMATION) return error.InvalidMbIconExclamation;
    if (window.MB_ICONINFORMATION != WindowsWindowSpec.MB_ICONINFORMATION) return error.InvalidMbIconInformation;
    if (window.MB_ICONQUESTION != WindowsWindowSpec.MB_ICONQUESTION) return error.InvalidMbIconQuestion;
    if (window.MB_ICONERROR != WindowsWindowSpec.MB_ICONERROR) return error.InvalidMbIconError;
    if (window.MB_DEFBUTTON1 != WindowsWindowSpec.MB_DEFBUTTON1) return error.InvalidMbDefButton1;
    if (window.MB_DEFBUTTON2 != WindowsWindowSpec.MB_DEFBUTTON2) return error.InvalidMbDefButton2;
    if (window.MB_DEFBUTTON3 != WindowsWindowSpec.MB_DEFBUTTON3) return error.InvalidMbDefButton3;
    if (window.MB_APPLMODAL != WindowsWindowSpec.MB_APPLMODAL) return error.InvalidMbApplModal;
    if (window.MB_SYSTEMMODAL != WindowsWindowSpec.MB_SYSTEMMODAL) return error.InvalidMbSystemModal;
    if (window.MB_TASKMODAL != WindowsWindowSpec.MB_TASKMODAL) return error.InvalidMbTaskModal;
    if (window.MB_TOPMOST != WindowsWindowSpec.MB_TOPMOST) return error.InvalidMbTopMost;

    if (window.IDABORT != WindowsWindowSpec.IDABORT) return error.InvalidIdAbort;
    if (window.IDCANCEL != WindowsWindowSpec.IDCANCEL) return error.InvalidIdCancel;
    if (window.IDCONTINUE != WindowsWindowSpec.IDCONTINUE) return error.InvalidIdContinue;
    if (window.IDIGNORE != WindowsWindowSpec.IDIGNORE) return error.InvalidIdIgnore;
    if (window.IDNO != WindowsWindowSpec.IDNO) return error.InvalidIdNo;
    if (window.IDOK != WindowsWindowSpec.IDOK) return error.InvalidIdOk;
    if (window.IDRETRY != WindowsWindowSpec.IDRETRY) return error.InvalidIdRetry;
    if (window.IDYES != WindowsWindowSpec.IDYES) return error.InvalidIdYes;

    if (window.WS_OVERLAPPED != WindowsWindowSpec.WS_OVERLAPPED) return error.InvalidWsOverlapped;
    if (window.WS_POPUP != WindowsWindowSpec.WS_POPUP) return error.InvalidWsPopup;
    if (window.WS_CHILD != WindowsWindowSpec.WS_CHILD) return error.InvalidWsChild;
    if (window.WS_MINIMIZE != WindowsWindowSpec.WS_MINIMIZE) return error.InvalidWsMinimize;
    if (window.WS_VISIBLE != WindowsWindowSpec.WS_VISIBLE) return error.InvalidWsVisible;
    if (window.WS_DISABLED != WindowsWindowSpec.WS_DISABLED) return error.InvalidWsDisabled;
    if (window.WS_CLIPSIBLINGS != WindowsWindowSpec.WS_CLIPSIBLINGS) return error.InvalidWsClipSiblings;
    if (window.WS_CLIPCHILDREN != WindowsWindowSpec.WS_CLIPCHILDREN) return error.InvalidWsClipChildren;
    if (window.WS_CAPTION != WindowsWindowSpec.WS_CAPTION) return error.InvalidWsCaption;
    if (window.WS_BORDER != WindowsWindowSpec.WS_BORDER) return error.InvalidWsBorder;
    if (window.WS_DLGFRAME != WindowsWindowSpec.WS_DLGFRAME) return error.InvalidWsDlgFrame;
    if (window.WS_VSCROLL != WindowsWindowSpec.WS_VSCROLL) return error.InvalidWsVScroll;
    if (window.WS_HSCROLL != WindowsWindowSpec.WS_HSCROLL) return error.InvalidWsHScroll;
    if (window.WS_SYSMENU != WindowsWindowSpec.WS_SYSMENU) return error.InvalidWsSysMenu;
    if (window.WS_THICKFRAME != WindowsWindowSpec.WS_THICKFRAME) return error.InvalidWsThickFrame;
    if (window.WS_MINIMIZEBOX != WindowsWindowSpec.WS_MINIMIZEBOX) return error.InvalidWsMinimizeBox;
    if (window.WS_MAXIMIZEBOX != WindowsWindowSpec.WS_MAXIMIZEBOX) return error.InvalidWsMaximizeBox;
    if (window.WS_OVERLAPPEDWINDOW != WindowsWindowSpec.WS_OVERLAPPEDWINDOW) return error.InvalidWsOverlappedWindow;

    if (window.CS_VREDRAW != WindowsWindowSpec.CS_VREDRAW) return error.InvalidCsVRedraw;
    if (window.CS_HREDRAW != WindowsWindowSpec.CS_HREDRAW) return error.InvalidCsHRedraw;

    if (window.PM_NOREMOVE != WindowsWindowSpec.PM_NOREMOVE) return error.InvalidPmNoRemove;
    if (window.PM_REMOVE != WindowsWindowSpec.PM_REMOVE) return error.InvalidPmRemove;

    if (window.WM_NULL != WindowsWindowSpec.WM_NULL) return error.InvalidWmNull;
    if (window.WM_CREATE != WindowsWindowSpec.WM_CREATE) return error.InvalidWmCreate;
    if (window.WM_DESTROY != WindowsWindowSpec.WM_DESTROY) return error.InvalidWmDestroy;
    if (window.WM_CLOSE != WindowsWindowSpec.WM_CLOSE) return error.InvalidWmClose;
    if (window.WM_QUIT != WindowsWindowSpec.WM_QUIT) return error.InvalidWmQuit;
    if (window.WM_PAINT != WindowsWindowSpec.WM_PAINT) return error.InvalidWmPaint;
    if (window.WM_SIZE != WindowsWindowSpec.WM_SIZE) return error.InvalidWmSize;
    if (window.WM_MOVE != WindowsWindowSpec.WM_MOVE) return error.InvalidWmMove;
    if (window.WM_KEYDOWN != WindowsWindowSpec.WM_KEYDOWN) return error.InvalidWmKeyDown;
    if (window.WM_KEYUP != WindowsWindowSpec.WM_KEYUP) return error.InvalidWmKeyUp;
    if (window.WM_SYSCOMMAND != WindowsWindowSpec.WM_SYSCOMMAND) return error.InvalidWmSysCommand;
    if (window.WM_ACTIVATE != WindowsWindowSpec.WM_ACTIVATE) return error.InvalidWmActivate;

    if (window.WA_INACTIVE != WindowsWindowSpec.WA_INACTIVE) return error.InvalidWaInactive;
    if (window.WA_ACTIVE != WindowsWindowSpec.WA_ACTIVE) return error.InvalidWaActive;
    if (window.WA_CLICKACTIVE != WindowsWindowSpec.WA_CLICKACTIVE) return error.InvalidWaClickActive;

    if (window.SC_KEYMENU != WindowsWindowSpec.SC_KEYMENU) return error.InvalidScKeyMenu;

    if (window.VK_BACK != WindowsWindowSpec.VK_BACK) return error.InvalidVkBack;
    if (window.VK_TAB != WindowsWindowSpec.VK_TAB) return error.InvalidVkTab;
    if (window.VK_SHIFT != WindowsWindowSpec.VK_SHIFT) return error.InvalidVkShift;
    if (window.VK_CONTROL != WindowsWindowSpec.VK_CONTROL) return error.InvalidVkControl;
    if (window.VK_MENU != WindowsWindowSpec.VK_MENU) return error.InvalidVkMenu;
    if (window.VK_RETURN != WindowsWindowSpec.VK_RETURN) return error.InvalidVkReturn;
    if (window.VK_ESCAPE != WindowsWindowSpec.VK_ESCAPE) return error.InvalidVkEscape;
    if (window.VK_SPACE != WindowsWindowSpec.VK_SPACE) return error.InvalidVkSpace;
    if (window.VK_LEFT != WindowsWindowSpec.VK_LEFT) return error.InvalidVkLeft;
    if (window.VK_UP != WindowsWindowSpec.VK_UP) return error.InvalidVkUp;
    if (window.VK_RIGHT != WindowsWindowSpec.VK_RIGHT) return error.InvalidVkRight;
    if (window.VK_DOWN != WindowsWindowSpec.VK_DOWN) return error.InvalidVkDown;
    if (window.VK_DELETE != WindowsWindowSpec.VK_DELETE) return error.InvalidVkDelete;

    if (window.SW_HIDE != WindowsWindowSpec.SW_HIDE) return error.InvalidSwHide;
    if (window.SW_SHOWNORMAL != WindowsWindowSpec.SW_SHOWNORMAL) return error.InvalidSwShowNormal;
    if (window.SW_NORMAL != WindowsWindowSpec.SW_NORMAL) return error.InvalidSwNormal;
    if (window.SW_SHOWMINIMIZED != WindowsWindowSpec.SW_SHOWMINIMIZED) return error.InvalidSwShowMinimized;
    if (window.SW_SHOWMAXIMIZED != WindowsWindowSpec.SW_SHOWMAXIMIZED) return error.InvalidSwShowMaximized;
    if (window.SW_MAXIMIZE != WindowsWindowSpec.SW_MAXIMIZE) return error.InvalidSwMaximize;
    if (window.SW_SHOWNOACTIVATE != WindowsWindowSpec.SW_SHOWNOACTIVATE) return error.InvalidSwShowNoActivate;
    if (window.SW_SHOW != WindowsWindowSpec.SW_SHOW) return error.InvalidSwShow;
    if (window.SW_MINIMIZE != WindowsWindowSpec.SW_MINIMIZE) return error.InvalidSwMinimize;
    if (window.SW_RESTORE != WindowsWindowSpec.SW_RESTORE) return error.InvalidSwRestore;
    if (window.SW_SHOWDEFAULT != WindowsWindowSpec.SW_SHOWDEFAULT) return error.InvalidSwShowDefault;
    if (window.SW_FORCEMINIMIZE != WindowsWindowSpec.SW_FORCEMINIMIZE) return error.InvalidSwForceMinimize;

    if (window.CW_USEDEFAULT != WindowsWindowSpec.CW_USEDEFAULT) return error.InvalidCwUseDefault;
}

pub fn validateWindowStructSizes() WindowAbiError!void {
    if (@sizeOf(window.RECT) != WindowsWindowSpec.sizeof_RECT) return error.InvalidRectSize;
    if (@sizeOf(window.POINT) != WindowsWindowSpec.sizeof_POINT) return error.InvalidPointSize;
    if (@sizeOf(window.MSG) != WindowsWindowSpec.sizeof_MSG) return error.InvalidMsgSize;
    if (@sizeOf(window.WNDCLASS) != WindowsWindowSpec.sizeof_WNDCLASS) return error.InvalidWndClassSize;
    if (@sizeOf(window.WNDCLASSEXA) != WindowsWindowSpec.sizeof_WNDCLASSEXA) return error.InvalidWndClassExASize;
    if (@sizeOf(window.WNDCLASSEXW) != WindowsWindowSpec.sizeof_WNDCLASSEXW) return error.InvalidWndClassExWSize;
}

pub fn validateAll() WindowAbiError!void {
    try validateWindowConstants();
    try validateWindowStructSizes();
}

fn reportWindowSizes() void {
    std.debug.print(
        \\================================================================================
        \\ Window Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "RECT", .spec = WindowsWindowSpec.sizeof_RECT, .zig = @sizeOf(window.RECT) },
        .{ .name = "POINT", .spec = WindowsWindowSpec.sizeof_POINT, .zig = @sizeOf(window.POINT) },
        .{ .name = "MSG", .spec = WindowsWindowSpec.sizeof_MSG, .zig = @sizeOf(window.MSG) },
        .{ .name = "WNDCLASS", .spec = WindowsWindowSpec.sizeof_WNDCLASS, .zig = @sizeOf(window.WNDCLASS) },
        .{ .name = "WNDCLASSEXA", .spec = WindowsWindowSpec.sizeof_WNDCLASSEXA, .zig = @sizeOf(window.WNDCLASSEXA) },
        .{ .name = "WNDCLASSEXW", .spec = WindowsWindowSpec.sizeof_WNDCLASSEXW, .zig = @sizeOf(window.WNDCLASSEXW) },
    };
    for (table) |entry| {
        std.debug.print(
            \\ {s:<38} | {d:<10} | {d:<14}
        , .{ entry.name, entry.spec, entry.zig });
    }
    std.debug.print(
        \\================================================================================
        \\
    , .{});
}

pub export fn rosetta3_print_window_report() void {
    reportWindowSizes();
}

pub export fn rosetta3_validate_window() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidMbOk => 1,
        error.InvalidMbOkCancel => 2,
        error.InvalidMbAbortRetryIgnore => 3,
        error.InvalidMbYesNo => 4,
        error.InvalidMbYesNoCancel => 5,
        error.InvalidMbRetryCancel => 6,
        error.InvalidMbCancelTryContinue => 7,
        error.InvalidMbIconExclamation => 8,
        error.InvalidMbIconInformation => 9,
        error.InvalidMbIconQuestion => 10,
        error.InvalidMbIconError => 11,
        error.InvalidMbDefButton1 => 12,
        error.InvalidMbDefButton2 => 13,
        error.InvalidMbDefButton3 => 14,
        error.InvalidMbApplModal => 15,
        error.InvalidMbSystemModal => 16,
        error.InvalidMbTaskModal => 17,
        error.InvalidMbTopMost => 18,
        error.InvalidIdAbort => 19,
        error.InvalidIdCancel => 20,
        error.InvalidIdContinue => 21,
        error.InvalidIdIgnore => 22,
        error.InvalidIdNo => 23,
        error.InvalidIdOk => 24,
        error.InvalidIdRetry => 25,
        error.InvalidIdYes => 26,
        error.InvalidWsOverlapped => 27,
        error.InvalidWsPopup => 28,
        error.InvalidWsChild => 29,
        error.InvalidWsMinimize => 30,
        error.InvalidWsVisible => 31,
        error.InvalidWsDisabled => 32,
        error.InvalidWsClipSiblings => 33,
        error.InvalidWsClipChildren => 34,
        error.InvalidWsCaption => 35,
        error.InvalidWsBorder => 36,
        error.InvalidWsDlgFrame => 37,
        error.InvalidWsVScroll => 38,
        error.InvalidWsHScroll => 39,
        error.InvalidWsSysMenu => 40,
        error.InvalidWsThickFrame => 41,
        error.InvalidWsMinimizeBox => 42,
        error.InvalidWsMaximizeBox => 43,
        error.InvalidWsOverlappedWindow => 44,
        error.InvalidCsVRedraw => 45,
        error.InvalidCsHRedraw => 46,
        error.InvalidPmNoRemove => 47,
        error.InvalidPmRemove => 48,
        error.InvalidWmNull => 49,
        error.InvalidWmCreate => 50,
        error.InvalidWmDestroy => 51,
        error.InvalidWmClose => 52,
        error.InvalidWmQuit => 53,
        error.InvalidWmPaint => 54,
        error.InvalidWmSize => 55,
        error.InvalidWmMove => 56,
        error.InvalidWmKeyDown => 57,
        error.InvalidWmKeyUp => 58,
        error.InvalidWmSysCommand => 59,
        error.InvalidWmActivate => 60,
        error.InvalidWaInactive => 61,
        error.InvalidWaActive => 62,
        error.InvalidWaClickActive => 63,
        error.InvalidScKeyMenu => 64,
        error.InvalidVkBack => 65,
        error.InvalidVkTab => 66,
        error.InvalidVkShift => 67,
        error.InvalidVkControl => 68,
        error.InvalidVkMenu => 69,
        error.InvalidVkReturn => 70,
        error.InvalidVkEscape => 71,
        error.InvalidVkSpace => 72,
        error.InvalidVkLeft => 73,
        error.InvalidVkUp => 74,
        error.InvalidVkRight => 75,
        error.InvalidVkDown => 76,
        error.InvalidVkDelete => 77,
        error.InvalidSwHide => 78,
        error.InvalidSwShowNormal => 79,
        error.InvalidSwNormal => 80,
        error.InvalidSwShowMinimized => 81,
        error.InvalidSwShowMaximized => 82,
        error.InvalidSwMaximize => 83,
        error.InvalidSwShowNoActivate => 84,
        error.InvalidSwShow => 85,
        error.InvalidSwMinimize => 86,
        error.InvalidSwRestore => 87,
        error.InvalidSwShowDefault => 88,
        error.InvalidSwForceMinimize => 89,
        error.InvalidCwUseDefault => 90,
        error.InvalidRectSize => 91,
        error.InvalidPointSize => 92,
        error.InvalidMsgSize => 93,
        error.InvalidWndClassSize => 94,
        error.InvalidWndClassExASize => 95,
        error.InvalidWndClassExWSize => 96,
    };
    return 0;
}

pub export fn rosetta3_window_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidMbOk",
        2 => "InvalidMbOkCancel",
        3 => "InvalidMbAbortRetryIgnore",
        4 => "InvalidMbYesNo",
        5 => "InvalidMbYesNoCancel",
        6 => "InvalidMbRetryCancel",
        7 => "InvalidMbCancelTryContinue",
        8 => "InvalidMbIconExclamation",
        9 => "InvalidMbIconInformation",
        10 => "InvalidMbIconQuestion",
        11 => "InvalidMbIconError",
        12 => "InvalidMbDefButton1",
        13 => "InvalidMbDefButton2",
        14 => "InvalidMbDefButton3",
        15 => "InvalidMbApplModal",
        16 => "InvalidMbSystemModal",
        17 => "InvalidMbTaskModal",
        18 => "InvalidMbTopMost",
        19 => "InvalidIdAbort",
        20 => "InvalidIdCancel",
        21 => "InvalidIdContinue",
        22 => "InvalidIdIgnore",
        23 => "InvalidIdNo",
        24 => "InvalidIdOk",
        25 => "InvalidIdRetry",
        26 => "InvalidIdYes",
        27 => "InvalidWsOverlapped",
        28 => "InvalidWsPopup",
        29 => "InvalidWsChild",
        30 => "InvalidWsMinimize",
        31 => "InvalidWsVisible",
        32 => "InvalidWsDisabled",
        33 => "InvalidWsClipSiblings",
        34 => "InvalidWsClipChildren",
        35 => "InvalidWsCaption",
        36 => "InvalidWsBorder",
        37 => "InvalidWsDlgFrame",
        38 => "InvalidWsVScroll",
        39 => "InvalidWsHScroll",
        40 => "InvalidWsSysMenu",
        41 => "InvalidWsThickFrame",
        42 => "InvalidWsMinimizeBox",
        43 => "InvalidWsMaximizeBox",
        44 => "InvalidWsOverlappedWindow",
        45 => "InvalidCsVRedraw",
        46 => "InvalidCsHRedraw",
        47 => "InvalidPmNoRemove",
        48 => "InvalidPmRemove",
        49 => "InvalidWmNull",
        50 => "InvalidWmCreate",
        51 => "InvalidWmDestroy",
        52 => "InvalidWmClose",
        53 => "InvalidWmQuit",
        54 => "InvalidWmPaint",
        55 => "InvalidWmSize",
        56 => "InvalidWmMove",
        57 => "InvalidWmKeyDown",
        58 => "InvalidWmKeyUp",
        59 => "InvalidWmSysCommand",
        60 => "InvalidWmActivate",
        61 => "InvalidWaInactive",
        62 => "InvalidWaActive",
        63 => "InvalidWaClickActive",
        64 => "InvalidScKeyMenu",
        65 => "InvalidVkBack",
        66 => "InvalidVkTab",
        67 => "InvalidVkShift",
        68 => "InvalidVkControl",
        69 => "InvalidVkMenu",
        70 => "InvalidVkReturn",
        71 => "InvalidVkEscape",
        72 => "InvalidVkSpace",
        73 => "InvalidVkLeft",
        74 => "InvalidVkUp",
        75 => "InvalidVkRight",
        76 => "InvalidVkDown",
        77 => "InvalidVkDelete",
        78 => "InvalidSwHide",
        79 => "InvalidSwShowNormal",
        80 => "InvalidSwNormal",
        81 => "InvalidSwShowMinimized",
        82 => "InvalidSwShowMaximized",
        83 => "InvalidSwMaximize",
        84 => "InvalidSwShowNoActivate",
        85 => "InvalidSwShow",
        86 => "InvalidSwMinimize",
        87 => "InvalidSwRestore",
        88 => "InvalidSwShowDefault",
        89 => "InvalidSwForceMinimize",
        90 => "InvalidCwUseDefault",
        91 => "InvalidRectSize",
        92 => "InvalidPointSize",
        93 => "InvalidMsgSize",
        94 => "InvalidWndClassSize",
        95 => "InvalidWndClassExASize",
        96 => "InvalidWndClassExWSize",
        else => "UnknownWindowFailure",
    };
}

test "window.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
