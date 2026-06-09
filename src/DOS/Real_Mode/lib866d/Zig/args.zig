const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const vgacon = @import("vgacon.zig");

pub const ARG_STR: u16 = 0x0000;
pub const ARG_U8: u16 = 0x0100;
pub const ARG_U16: u16 = 0x0200;
pub const ARG_U32: u16 = 0x0300;
pub const ARG_I8: u16 = 0x0400;
pub const ARG_I16: u16 = 0x0500;
pub const ARG_I32: u16 = 0x0600;
pub const ARG_BOOL: u16 = 0x0700;
pub const ARG_FLAG: u16 = 0x0800;
pub const ARG_NFLAG: u16 = 0x0900;
pub const ARG_BLANK: u16 = 0xFB00;
pub const ARG_HEADER: u16 = 0xFC00;
pub const ARG_EXPLAIN: u16 = 0xFD00;
pub const ARG_USAGE: u16 = 0xFE00;
pub const ARG_NONE: u16 = 0xFF00;

pub fn ARG_STRING(size: u8) u16 {
    return ARG_STR | size;
}
pub fn ARG_ARRAY(typ: u16, count: u8) u16 {
    return typ | count;
}
pub const ARG_MAX: u16 = 255;

pub const ArgType = u16;
pub const CheckFn = *const fn (val: *const anyopaque) bool;

pub const Arg = extern struct {
    prefix: ?[*:0]const u8,
    paramNames: ?[*:0]const u8,
    description: ?[*:0]const u8,
    type: ArgType,
    foundFlag: ?*bool,
    dst: ?*anyopaque,
    checker: ?CheckFn,
};

pub const ParseError = enum(u8) {
    success = 0,
    @"error" = 1,
    input_error = 2,
    out_of_range = 3,
    too_few_array_values = 4,
    string_too_long = 5,
    check_failed = 6,
    arg_not_found = 7,
    usage_printed = 8,
    internal_error = 9,
    no_arguments = 10,
};

pub fn getArgType(arg_type: ArgType) ArgType {
    return arg_type & 0xFF00;
}
pub fn getArgArraySize(arg_type: ArgType) u8 {
    return @truncate(arg_type & 0x00FF);
}
pub fn argHasParam(arg_type: ArgType) bool {
    return arg_type != ARG_FLAG and arg_type != ARG_NFLAG and arg_type != ARG_USAGE;
}

fn incrementAndCheckPageBreak() void {
    var printedLines: usize = 0;
    const consoleHeight = vgacon.getConsoleHeight();
    printedLines += 1;
    if (printedLines % consoleHeight == consoleHeight - 1) {
        vgacon.waitKeyWithMessage();
    }
}

fn printLineSeparator() void {
    const width = vgacon.getConsoleWidth();
    var i: u16 = 0;
    while (i < width) : (i += 1) {
        std.debug.print("{c}", .{@as(u8, 0xCD)});
    }
    incrementAndCheckPageBreak();
}

pub fn printUsage(argList: []const Arg) void {
    var tmp: [256]u8 = std.mem.zeroes([256]u8);
    debug.nullcheck(argList.ptr);
    debug.assertMsg(argList.len > 0, "argListSize > 0");
    var idx: usize = 0;
    if (getArgType(argList[0].type) == ARG_HEADER) {
        printLineSeparator();
        if (argList[0].prefix) |p| std.debug.print("{s}\n\n", .{p});
        if (argList[0].description) |d| std.debug.print("{s}\n", .{d});
        vgacon.waitKeyWithMessage();
        printLineSeparator();
        idx = 1;
    }
    std.debug.print("\n Valid command line parameters are: \n\n", .{});
    while (idx < argList.len) : (idx += 1) {
        switch (getArgType(argList[idx].type)) {
            ARG_HEADER => {},
            ARG_BLANK => {
                incrementAndCheckPageBreak();
                std.debug.print("\n", .{});
            },
            ARG_EXPLAIN => {
                incrementAndCheckPageBreak();
                if (argList[idx].description) |d| std.debug.print("                         {s}\n", .{d});
            },
            else => {
                if (argHasParam(getArgType(argList[idx].type))) {
                    if (argList[idx].prefix) |p| {
                        const pn = argList[idx].paramNames orelse "...";
                        const written = std.fmt.bufPrint(&tmp, "/{s}:<{s}>", .{ p, pn }) catch unreachable;
                        std.debug.print("                         {s} {s}\n", .{ written, argList[idx].description orelse "" });
                    }
                } else {
                    if (argList[idx].prefix) |p| {
                        std.debug.print("                         /{s} {s}\n", .{ p, argList[idx].description orelse "" });
                    }
                }
                incrementAndCheckPageBreak();
            },
        }
    }
    std.debug.print("\n", .{});
}

fn parseAndSetNum(arg: *const Arg, toParse: []const u8, arraySize: usize, isSigned: bool, size: usize) ParseError {
    _ = arg;
    _ = toParse;
    _ = arraySize;
    _ = isSigned;
    _ = size;
    return .success;
}

fn parseAndSetStr(arg: *const Arg, toParse: []const u8, length: usize) ParseError {
    const finalLen = if (length == 0 or length > ARG_MAX) ARG_MAX else length;
    if (toParse.len > finalLen) return .string_too_long;
    if (arg.dst) |dst| {
        const d = @as([*]u8, @ptrCast(dst))[0..toParse.len];
        @memcpy(d, toParse);
    }
    if (arg.checker) |chk| if (!chk(@as(*const anyopaque, @ptrCast(toParse.ptr)))) return .check_failed;
    return .success;
}

fn setFlag(arg: *const Arg, value: bool) ParseError {
    const dstFlag: ?*bool = @ptrCast(arg.dst);
    if (dstFlag) |f| f.* = value;
    if (arg.checker) |chk| if (!chk(@as(*const anyopaque, @ptrCast(&value)))) return .check_failed;
    return .success;
}

fn doParse(arg: *const Arg, toParse: []const u8) ParseError {
    const prefixLen = std.mem.len(arg.prefix.?);
    var arraySize: usize = arg.type & 0xFF;
    if (arraySize == 0) arraySize = 1;
    switch (getArgType(arg.type)) {
        ARG_FLAG => return setFlag(arg, true),
        ARG_NFLAG => return setFlag(arg, false),
        ARG_USAGE => return .internal_error,
        else => {},
    }
    const val = toParse[prefixLen + 2 ..];
    switch (getArgType(arg.type)) {
        ARG_STR => return parseAndSetStr(arg, val, arraySize),
        ARG_U8 => return parseAndSetNum(arg, val, arraySize, false, 1),
        ARG_U16 => return parseAndSetNum(arg, val, arraySize, false, 2),
        ARG_U32 => return parseAndSetNum(arg, val, arraySize, false, 4),
        ARG_I8 => return parseAndSetNum(arg, val, arraySize, true, 1),
        ARG_I16 => return parseAndSetNum(arg, val, arraySize, true, 2),
        ARG_I32 => return parseAndSetNum(arg, val, arraySize, true, 4),
        ARG_BOOL => return parseAndSetNum(arg, val, arraySize, false, 1),
        else => return .internal_error,
    }
}

fn isThisArg(arg: *const Arg, str: []const u8) bool {
    const prefixLen = std.mem.len(arg.prefix.?);
    if (str.len < prefixLen or str[0] != '/') return false;
    if (!std.ascii.eqlIgnoreCase(str[1..][0..prefixLen], arg.prefix.?[0..prefixLen])) return false;
    switch (getArgType(arg.type)) {
        ARG_HEADER, ARG_BLANK, ARG_EXPLAIN => return false,
        ARG_FLAG, ARG_NFLAG, ARG_USAGE => {
            if (str.len != prefixLen + 1) return false;
        },
        else => {
            if (str[prefixLen + 1] != ':') return false;
        },
    }
    return true;
}

fn printUsageHintIfPresent(argList: []const Arg) void {
    for (argList) |a| {
        if (a.type == ARG_USAGE) {
            if (a.prefix) |p| std.debug.print("Use /{s} for parameter information.\n", .{p});
            return;
        }
    }
}

pub fn parseArg(argList: []const Arg, toParse: []const u8) ParseError {
    var ret: ParseError = .arg_not_found;
    for (argList) |*a| {
        if (a.prefix == null) continue;
        if (isThisArg(a, toParse)) {
            if (a.type == ARG_USAGE) {
                printUsage(argList);
                return .usage_printed;
            }
            ret = doParse(a, toParse);
            if (ret == .success) {
                if (a.foundFlag) |f| f.* = true;
                return .success;
            }
        }
    }
    if (ret == .arg_not_found) {
        std.debug.print("Input Parameter '{s}' not recognized.\n", .{toParse});
        printUsageHintIfPresent(argList);
    }
    return ret;
}

pub fn parseAllArgs(args: []const []const u8, argList: []const Arg) ParseError {
    if (args.len <= 1) return .no_arguments;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const ret = parseArg(argList, args[i]);
        if (ret != .success) return ret;
    }
    return .success;
}
