const std = @import("std");
const builtin = @import("builtin");
const types = @import("types.zig");
const debug = @import("debug.zig");

pub const COLOR_BLACK: u8 = 0;
pub const COLOR_BLUE: u8 = 1;
pub const COLOR_GREEN: u8 = 2;
pub const COLOR_CYAN: u8 = 3;
pub const COLOR_RED: u8 = 4;
pub const COLOR_MAGNT: u8 = 5;
pub const COLOR_BROWN: u8 = 6;
pub const COLOR_GRAY: u8 = 7;
pub const COLOR_DGRAY: u8 = 8;
pub const COLOR_LBLUE: u8 = 9;
pub const COLOR_LGREN: u8 = 10;
pub const COLOR_LCYAN: u8 = 11;
pub const COLOR_LRED: u8 = 12;
pub const COLOR_LMGNT: u8 = 13;
pub const COLOR_YELLO: u8 = 14;
pub const COLOR_WHITE: u8 = 15;

pub const BIOSColor = extern union {
    data: packed struct(u16) {
        foreground: u4,
        background: u3,
        blinking: u1,
    },
    raw: extern struct {
        high: u8,
        low: u8,
    },
};

pub const CursorPos = extern struct {
    x: u8,
    y: u8,
};

pub const CursorType = extern struct {
    startScanLine: u8,
    endScanLine: u8,
};

pub const LogLevel = enum(u8) {
    debug = 0,
    info = 1,
    ok = 2,
    warning = 3,
    @"error" = 4,
    silent = 5,
};

const BIOSChar = extern struct {
    c: u8,
    attr: u8,
};

var logLevel: LogLevel = if (builtin.mode == .Debug) .debug else .info;

fn makeColor(fg: u8, bg: u8, blink: bool) u8 {
    return ((bg & 0x07) << 4) | (fg & 0x0f) | (@as(u8, @intFromBool(blink)) << 7);
}

fn advanceCursor(increment: usize) void {
    _ = increment;
}

fn getCurrentDrawPointer() void {}

pub fn printSizedColorString(str: []const u8, fgColor: u8, bgColor: u8, blink: bool) void {
    const attr = makeColor(fgColor, bgColor, blink);
    _ = attr;
    for (str) |c| {
        std.debug.print("{c}", .{c});
    }
}

pub fn printColorString(str: []const u8, fgColor: u8, bgColor: u8, blink: bool) void {
    printSizedColorString(str, fgColor, bgColor, blink);
}

fn vprintfLogLevelInternal(level: LogLevel, comptime fmt: []const u8, args: anytype, newLine: bool) void {
    if (@intFromEnum(level) < @intFromEnum(logLevel)) return;
    std.debug.print(" ", .{});
    switch (level) {
        .debug => std.debug.print("DEBUG", .{}),
        .info => {},
        .ok => std.debug.print("   OK", .{}),
        .warning => std.debug.print(" WARN", .{}),
        .@"error" => std.debug.print("ERROR", .{}),
        .silent => return,
    }
    std.debug.print(" \xBB", .{});
    std.debug.print(fmt, args);
    if (newLine) std.debug.print("\n", .{});
}

pub fn vprintfLogLevel(level: LogLevel, comptime fmt: []const u8, args: anytype) void {
    vprintfLogLevelInternal(level, fmt, args, false);
}

pub fn printDebug(comptime fmt: []const u8, args: anytype) void {
    vprintfLogLevelInternal(.debug, fmt, args, false);
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    vprintfLogLevelInternal(.info, fmt, args, false);
}

pub fn printOK(comptime fmt: []const u8, args: anytype) void {
    vprintfLogLevelInternal(.ok, fmt, args, false);
}

pub fn printWarning(comptime fmt: []const u8, args: anytype) void {
    vprintfLogLevelInternal(.warning, fmt, args, false);
}

pub fn printError(comptime fmt: []const u8, args: anytype) void {
    vprintfLogLevelInternal(.@"error", fmt, args, false);
}

pub fn setLogLevel(level: LogLevel) void {
    if (@intFromEnum(level) <= @intFromEnum(LogLevel.silent)) logLevel = level;
}

pub fn fillColorCharacter(character: u8, length: usize, fgColor: u8, bgColor: u8, blink: bool) void {
    _ = blink;
    const attr = makeColor(fgColor, bgColor, false);
    _ = attr;
    var i: usize = 0;
    while (i < length) : (i += 1) {
        std.debug.print("{c}", .{character});
    }
}

pub fn fillCharacter(character: u8, length: usize) void {
    var i: usize = 0;
    while (i < length) : (i += 1) {
        std.debug.print("{c}", .{character});
    }
}

pub fn isCursorAtStartOfLine() bool {
    return true;
}

pub fn getConsoleWidth() u16 {
    return 80;
}

pub fn getConsoleHeight() u16 {
    return 25;
}

pub fn waitKeyWithMessage() void {
    std.debug.print("< press any key to continue... >\n", .{});
}
