const std = @import("std");

const behavior = @import("behavior_api");

pub const BehaviorError = error{
    StdInputHandleMismatch,
    StdOutputHandleMismatch,
    StdErrorHandleMismatch,
    ForegroundGreenMismatch,
    ForegroundIntensityMismatch,
    CoordSizeMismatch,
    ConsoleCursorInfoSizeMismatch,
    SleepSignatureMismatch,
    GetStdHandleSignatureMismatch,
    SetConsoleTextAttributeSignatureMismatch,
    SetConsoleCursorPositionSignatureMismatch,
    SetConsoleCursorInfoSignatureMismatch,
};

pub const WindowsBehaviorSpec = struct {
    pub const STD_INPUT_HANDLE: comptime_int = 0xFFFFFFF6;
    pub const STD_OUTPUT_HANDLE: comptime_int = 0xFFFFFFF5;
    pub const STD_ERROR_HANDLE: comptime_int = 0xFFFFFFF4;
    pub const FOREGROUND_GREEN: comptime_int = 0x0002;
    pub const FOREGROUND_INTENSITY: comptime_int = 0x0008;

    pub const sizeof_COORD: comptime_int = 4;
    pub const sizeof_CONSOLE_CURSOR_INFO: comptime_int = 8;

    pub const function_pointer_size: comptime_int = @sizeOf(usize);
};

fn validateConstants() BehaviorError!void {
    if (behavior.STD_INPUT_HANDLE != WindowsBehaviorSpec.STD_INPUT_HANDLE)
        return error.StdInputHandleMismatch;
    if (behavior.STD_OUTPUT_HANDLE != WindowsBehaviorSpec.STD_OUTPUT_HANDLE)
        return error.StdOutputHandleMismatch;
    if (behavior.STD_ERROR_HANDLE != WindowsBehaviorSpec.STD_ERROR_HANDLE)
        return error.StdErrorHandleMismatch;
    if (behavior.FOREGROUND_GREEN != WindowsBehaviorSpec.FOREGROUND_GREEN)
        return error.ForegroundGreenMismatch;
    if (behavior.FOREGROUND_INTENSITY != WindowsBehaviorSpec.FOREGROUND_INTENSITY)
        return error.ForegroundIntensityMismatch;
}

fn validateTypes() BehaviorError!void {
    if (@sizeOf(behavior.COORD) != WindowsBehaviorSpec.sizeof_COORD)
        return error.CoordSizeMismatch;
    if (@sizeOf(behavior.CONSOLE_CURSOR_INFO) != WindowsBehaviorSpec.sizeof_CONSOLE_CURSOR_INFO)
        return error.ConsoleCursorInfoSizeMismatch;
}

fn validateSignatures() BehaviorError!void {
    if (@sizeOf(@TypeOf(&behavior.Sleep)) != WindowsBehaviorSpec.function_pointer_size)
        return error.SleepSignatureMismatch;
    if (@sizeOf(@TypeOf(&behavior.GetStdHandle)) != WindowsBehaviorSpec.function_pointer_size)
        return error.GetStdHandleSignatureMismatch;
    if (@sizeOf(@TypeOf(&behavior.SetConsoleTextAttribute)) != WindowsBehaviorSpec.function_pointer_size)
        return error.SetConsoleTextAttributeSignatureMismatch;
    if (@sizeOf(@TypeOf(&behavior.SetConsoleCursorPosition)) != WindowsBehaviorSpec.function_pointer_size)
        return error.SetConsoleCursorPositionSignatureMismatch;
    if (@sizeOf(@TypeOf(&behavior.SetConsoleCursorInfo)) != WindowsBehaviorSpec.function_pointer_size)
        return error.SetConsoleCursorInfoSignatureMismatch;
}

pub fn validateAll() BehaviorError!void {
    try validateConstants();
    try validateTypes();
    try validateSignatures();
}

pub fn rosetta3_validate_behavior() c_int {
    validateAll() catch |err| return switch (err) {
        error.StdInputHandleMismatch => 1,
        error.StdOutputHandleMismatch => 2,
        error.StdErrorHandleMismatch => 3,
        error.ForegroundGreenMismatch => 4,
        error.ForegroundIntensityMismatch => 5,
        error.CoordSizeMismatch => 6,
        error.ConsoleCursorInfoSizeMismatch => 7,
        error.SleepSignatureMismatch => 8,
        error.GetStdHandleSignatureMismatch => 9,
        error.SetConsoleTextAttributeSignatureMismatch => 10,
        error.SetConsoleCursorPositionSignatureMismatch => 11,
        error.SetConsoleCursorInfoSignatureMismatch => 12,
    };
    return 0;
}

pub fn rosetta3_behavior_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "StdInputHandleMismatch",
        2 => "StdOutputHandleMismatch",
        3 => "StdErrorHandleMismatch",
        4 => "ForegroundGreenMismatch",
        5 => "ForegroundIntensityMismatch",
        6 => "CoordSizeMismatch",
        7 => "ConsoleCursorInfoSizeMismatch",
        8 => "SleepSignatureMismatch",
        9 => "GetStdHandleSignatureMismatch",
        10 => "SetConsoleTextAttributeSignatureMismatch",
        11 => "SetConsoleCursorPositionSignatureMismatch",
        12 => "SetConsoleCursorInfoSignatureMismatch",
        else => "UnknownBehaviorFailure",
    };
}

pub fn rosetta3_print_behavior_report() void {
    std.debug.print(
        \\================================================================================
        \\ Behavioral ABI Validation Report
        \\================================================================================
        \\ STD_INPUT_HANDLE            : 0x{x:0>8} (spec: 0x{x:0>8})
        \\ STD_OUTPUT_HANDLE           : 0x{x:0>8} (spec: 0x{x:0>8})
        \\ STD_ERROR_HANDLE            : 0x{x:0>8} (spec: 0x{x:0>8})
        \\ FOREGROUND_GREEN            : 0x{x:0>4} (spec: 0x{x:0>4})
        \\ FOREGROUND_INTENSITY        : 0x{x:0>4} (spec: 0x{x:0>4})
        \\ sizeof(COORD)               : {d} (spec: {d})
        \\ sizeof(CONSOLE_CURSOR_INFO) : {d} (spec: {d})
        \\ sizeof(&Sleep)              : {d} (spec: {d})
        \\ sizeof(&GetStdHandle)       : {d} (spec: {d})
        \\ sizeof(&SetConsoleTextAttribute) : {d} (spec: {d})
        \\ sizeof(&SetConsoleCursorPosition) : {d} (spec: {d})
        \\ sizeof(&SetConsoleCursorInfo) : {d} (spec: {d})
        \\
    , .{
        @as(u32, @intCast(behavior.STD_INPUT_HANDLE)),
        @as(u32, WindowsBehaviorSpec.STD_INPUT_HANDLE),
        @as(u32, @intCast(behavior.STD_OUTPUT_HANDLE)),
        @as(u32, WindowsBehaviorSpec.STD_OUTPUT_HANDLE),
        @as(u32, @intCast(behavior.STD_ERROR_HANDLE)),
        @as(u32, WindowsBehaviorSpec.STD_ERROR_HANDLE),
        @as(u32, @intCast(behavior.FOREGROUND_GREEN)),
        @as(u32, WindowsBehaviorSpec.FOREGROUND_GREEN),
        @as(u32, @intCast(behavior.FOREGROUND_INTENSITY)),
        @as(u32, WindowsBehaviorSpec.FOREGROUND_INTENSITY),
        @sizeOf(behavior.COORD),
        WindowsBehaviorSpec.sizeof_COORD,
        @sizeOf(behavior.CONSOLE_CURSOR_INFO),
        WindowsBehaviorSpec.sizeof_CONSOLE_CURSOR_INFO,
        @sizeOf(@TypeOf(&behavior.Sleep)),
        WindowsBehaviorSpec.function_pointer_size,
        @sizeOf(@TypeOf(&behavior.GetStdHandle)),
        WindowsBehaviorSpec.function_pointer_size,
        @sizeOf(@TypeOf(&behavior.SetConsoleTextAttribute)),
        WindowsBehaviorSpec.function_pointer_size,
        @sizeOf(@TypeOf(&behavior.SetConsoleCursorPosition)),
        WindowsBehaviorSpec.function_pointer_size,
        @sizeOf(@TypeOf(&behavior.SetConsoleCursorInfo)),
        WindowsBehaviorSpec.function_pointer_size,
    });
}

test "behavioral ABI validation" {
    try validateAll();
}
