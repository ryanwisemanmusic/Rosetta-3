const std = @import("std");

const win32_all = @import("win32_all");
const gdi = win32_all;

pub const GdiAbiError = error{
    InvalidStockBrushConstants,
    InvalidStockPenConstants,
    InvalidStockFontConstants,
    InvalidCursorIdConstants,
    InvalidIconIdConstants,
    InvalidMakeIntResourceMacro,
    InvalidPointSize,
    InvalidSizeSize,
    InvalidWcharSize,
};

pub const WindowsGdiSpec = struct {
    // Stock brush constants (GetStockObject)
    pub const WHITE_BRUSH: comptime_int = 0;
    pub const GRAY_BRUSH: comptime_int = 2;
    pub const NULL_BRUSH: comptime_int = 5;
    pub const HOLLOW_BRUSH: comptime_int = 5;
    pub const BLACK_BRUSH: comptime_int = 4;
    pub const DC_BRUSH: comptime_int = 18;

    // Stock pen constants (GetStockObject)
    pub const WHITE_PEN: comptime_int = 6;
    pub const BLACK_PEN: comptime_int = 7;
    pub const DC_PEN: comptime_int = 19;

    // Stock font constants (GetStockObject)
    pub const OEM_FIXED_FONT: comptime_int = 10;
    pub const ANSI_FIXED_FONT: comptime_int = 11;
    pub const ANSI_VAR_FONT: comptime_int = 12;
    pub const SYSTEM_FONT: comptime_int = 13;
    pub const DEFAULT_GUI_FONT: comptime_int = 17;

    // System cursor IDs (LoadCursor)
    pub const IDC_ARROW: comptime_int = 32512;
    pub const IDC_IBEAM: comptime_int = 32513;
    pub const IDC_WAIT: comptime_int = 32514;
    pub const IDC_CROSS: comptime_int = 32515;
    pub const IDC_SIZEALL: comptime_int = 32646;

    // System icon IDs (LoadIcon)
    pub const IDI_APPLICATION: comptime_int = 32512;
    pub const IDI_ASTERISK: comptime_int = 32516;
    pub const IDI_EXCLAMATION: comptime_int = 32517;
    pub const IDI_HAND: comptime_int = 32513;
    pub const IDI_QUESTION: comptime_int = 32514;
    pub const IDI_WINLOGO: comptime_int = 32518;

    // MAKEINTRESOURCE macro validation
    // MAKEINTRESOURCE(i) == ((ULONG_PTR)((WORD)(i)))
    pub const MAKEINTRESOURCE_32512: comptime_int = 32512;
    pub const MAKEINTRESOURCE_32513: comptime_int = 32513;
    pub const MAKEINTRESOURCE_32514: comptime_int = 32514;
    pub const MAKEINTRESOURCE_32515: comptime_int = 32515;
    pub const MAKEINTRESOURCE_32516: comptime_int = 32516;
    pub const MAKEINTRESOURCE_32517: comptime_int = 32517;
    pub const MAKEINTRESOURCE_32518: comptime_int = 32518;
    pub const MAKEINTRESOURCE_32646: comptime_int = 32646;
};

pub fn validateGdiConstants() GdiAbiError!void {
    if (gdi.WHITE_BRUSH != WindowsGdiSpec.WHITE_BRUSH or
        gdi.GRAY_BRUSH != WindowsGdiSpec.GRAY_BRUSH or
        gdi.NULL_BRUSH != WindowsGdiSpec.NULL_BRUSH or
        gdi.HOLLOW_BRUSH != WindowsGdiSpec.HOLLOW_BRUSH or
        gdi.BLACK_BRUSH != WindowsGdiSpec.BLACK_BRUSH or
        gdi.DC_BRUSH != WindowsGdiSpec.DC_BRUSH)
        return error.InvalidStockBrushConstants;

    if (gdi.WHITE_PEN != WindowsGdiSpec.WHITE_PEN or
        gdi.BLACK_PEN != WindowsGdiSpec.BLACK_PEN or
        gdi.DC_PEN != WindowsGdiSpec.DC_PEN)
        return error.InvalidStockPenConstants;

    if (gdi.OEM_FIXED_FONT != WindowsGdiSpec.OEM_FIXED_FONT or
        gdi.ANSI_FIXED_FONT != WindowsGdiSpec.ANSI_FIXED_FONT or
        gdi.ANSI_VAR_FONT != WindowsGdiSpec.ANSI_VAR_FONT or
        gdi.SYSTEM_FONT != WindowsGdiSpec.SYSTEM_FONT or
        gdi.DEFAULT_GUI_FONT != WindowsGdiSpec.DEFAULT_GUI_FONT)
        return error.InvalidStockFontConstants;

    if (gdi.IDC_ARROW != WindowsGdiSpec.IDC_ARROW or
        gdi.IDC_IBEAM != WindowsGdiSpec.IDC_IBEAM or
        gdi.IDC_WAIT != WindowsGdiSpec.IDC_WAIT or
        gdi.IDC_CROSS != WindowsGdiSpec.IDC_CROSS or
        gdi.IDC_SIZEALL != WindowsGdiSpec.IDC_SIZEALL)
        return error.InvalidCursorIdConstants;

    if (gdi.IDI_APPLICATION != WindowsGdiSpec.IDI_APPLICATION or
        gdi.IDI_ASTERISK != WindowsGdiSpec.IDI_ASTERISK or
        gdi.IDI_EXCLAMATION != WindowsGdiSpec.IDI_EXCLAMATION or
        gdi.IDI_HAND != WindowsGdiSpec.IDI_HAND or
        gdi.IDI_QUESTION != WindowsGdiSpec.IDI_QUESTION or
        gdi.IDI_WINLOGO != WindowsGdiSpec.IDI_WINLOGO)
        return error.InvalidIconIdConstants;

    if (gdi.MAKEINTRESOURCE(32512) != WindowsGdiSpec.MAKEINTRESOURCE_32512 or
        gdi.MAKEINTRESOURCE(32513) != WindowsGdiSpec.MAKEINTRESOURCE_32513 or
        gdi.MAKEINTRESOURCE(32514) != WindowsGdiSpec.MAKEINTRESOURCE_32514 or
        gdi.MAKEINTRESOURCE(32515) != WindowsGdiSpec.MAKEINTRESOURCE_32515 or
        gdi.MAKEINTRESOURCE(32516) != WindowsGdiSpec.MAKEINTRESOURCE_32516 or
        gdi.MAKEINTRESOURCE(32517) != WindowsGdiSpec.MAKEINTRESOURCE_32517 or
        gdi.MAKEINTRESOURCE(32518) != WindowsGdiSpec.MAKEINTRESOURCE_32518 or
        gdi.MAKEINTRESOURCE(32646) != WindowsGdiSpec.MAKEINTRESOURCE_32646)
        return error.InvalidMakeIntResourceMacro;

    if (@sizeOf(gdi.POINT) != 8) return error.InvalidPointSize;
    if (@sizeOf(gdi.SIZE) != 8) return error.InvalidSizeSize;
    if (@sizeOf(gdi.WCHAR) != 2) return error.InvalidWcharSize;
}

pub fn validateAll() GdiAbiError!void {
    try validateGdiConstants();
}

fn reportGdiConstants() void {
    std.debug.print(
        \\==============================================================================
        \\ GDI Header Constant Table (Windows spec vs Zig translated)
        \\==============================================================================
        \\ Name                           | Win32 Spec | Zig Translated
        \\--------------------------------+------------+----------------
    , .{});
    const table = [_]struct { name: []const u8, spec: comptime_int, zig: comptime_int }{
        .{ .name = "WHITE_BRUSH", .spec = WindowsGdiSpec.WHITE_BRUSH, .zig = gdi.WHITE_BRUSH },
        .{ .name = "GRAY_BRUSH", .spec = WindowsGdiSpec.GRAY_BRUSH, .zig = gdi.GRAY_BRUSH },
        .{ .name = "NULL_BRUSH", .spec = WindowsGdiSpec.NULL_BRUSH, .zig = gdi.NULL_BRUSH },
        .{ .name = "HOLLOW_BRUSH", .spec = WindowsGdiSpec.HOLLOW_BRUSH, .zig = gdi.HOLLOW_BRUSH },
        .{ .name = "BLACK_BRUSH", .spec = WindowsGdiSpec.BLACK_BRUSH, .zig = gdi.BLACK_BRUSH },
        .{ .name = "DC_BRUSH", .spec = WindowsGdiSpec.DC_BRUSH, .zig = gdi.DC_BRUSH },
        .{ .name = "WHITE_PEN", .spec = WindowsGdiSpec.WHITE_PEN, .zig = gdi.WHITE_PEN },
        .{ .name = "BLACK_PEN", .spec = WindowsGdiSpec.BLACK_PEN, .zig = gdi.BLACK_PEN },
        .{ .name = "DC_PEN", .spec = WindowsGdiSpec.DC_PEN, .zig = gdi.DC_PEN },
        .{ .name = "OEM_FIXED_FONT", .spec = WindowsGdiSpec.OEM_FIXED_FONT, .zig = gdi.OEM_FIXED_FONT },
        .{ .name = "ANSI_FIXED_FONT", .spec = WindowsGdiSpec.ANSI_FIXED_FONT, .zig = gdi.ANSI_FIXED_FONT },
        .{ .name = "ANSI_VAR_FONT", .spec = WindowsGdiSpec.ANSI_VAR_FONT, .zig = gdi.ANSI_VAR_FONT },
        .{ .name = "SYSTEM_FONT", .spec = WindowsGdiSpec.SYSTEM_FONT, .zig = gdi.SYSTEM_FONT },
        .{ .name = "DEFAULT_GUI_FONT", .spec = WindowsGdiSpec.DEFAULT_GUI_FONT, .zig = gdi.DEFAULT_GUI_FONT },
        .{ .name = "IDC_ARROW", .spec = WindowsGdiSpec.IDC_ARROW, .zig = gdi.IDC_ARROW },
        .{ .name = "IDC_IBEAM", .spec = WindowsGdiSpec.IDC_IBEAM, .zig = gdi.IDC_IBEAM },
        .{ .name = "IDC_WAIT", .spec = WindowsGdiSpec.IDC_WAIT, .zig = gdi.IDC_WAIT },
        .{ .name = "IDC_CROSS", .spec = WindowsGdiSpec.IDC_CROSS, .zig = gdi.IDC_CROSS },
        .{ .name = "IDC_SIZEALL", .spec = WindowsGdiSpec.IDC_SIZEALL, .zig = gdi.IDC_SIZEALL },
        .{ .name = "IDI_APPLICATION", .spec = WindowsGdiSpec.IDI_APPLICATION, .zig = gdi.IDI_APPLICATION },
        .{ .name = "IDI_ASTERISK", .spec = WindowsGdiSpec.IDI_ASTERISK, .zig = gdi.IDI_ASTERISK },
        .{ .name = "IDI_EXCLAMATION", .spec = WindowsGdiSpec.IDI_EXCLAMATION, .zig = gdi.IDI_EXCLAMATION },
        .{ .name = "IDI_HAND", .spec = WindowsGdiSpec.IDI_HAND, .zig = gdi.IDI_HAND },
        .{ .name = "IDI_QUESTION", .spec = WindowsGdiSpec.IDI_QUESTION, .zig = gdi.IDI_QUESTION },
        .{ .name = "IDI_WINLOGO", .spec = WindowsGdiSpec.IDI_WINLOGO, .zig = gdi.IDI_WINLOGO },
    };
    for (table) |entry| {
        std.debug.print(
            \\ {s:<30} | {d:<10} | {d:<14}
        , .{ entry.name, entry.spec, entry.zig });
    }
    std.debug.print(
        \\==============================================================================
        \\
    , .{});
}

pub export fn rosetta3_print_gdi_report() void {
    reportGdiConstants();
}

pub export fn rosetta3_validate_gdi() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidStockBrushConstants => 1,
        error.InvalidStockPenConstants => 2,
        error.InvalidStockFontConstants => 3,
        error.InvalidCursorIdConstants => 4,
        error.InvalidIconIdConstants => 5,
        error.InvalidMakeIntResourceMacro => 6,
        error.InvalidPointSize => 7,
        error.InvalidSizeSize => 8,
        error.InvalidWcharSize => 9,
    };
    return 0;
}

pub export fn rosetta3_gdi_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidStockBrushConstants",
        2 => "InvalidStockPenConstants",
        3 => "InvalidStockFontConstants",
        4 => "InvalidCursorIdConstants",
        5 => "InvalidIconIdConstants",
        6 => "InvalidMakeIntResourceMacro",
        7 => "InvalidPointSize",
        8 => "InvalidSizeSize",
        9 => "InvalidWcharSize",
        else => "UnknownGdiFailure",
    };
}

test "gdi.h matches pseudo-Windows constants" {
    try validateAll();
}
