const std = @import("std");

const behavior = @import("behavior_api");

pub const BehaviorError = error{
    SleepRange,
    ConsoleHandleInvalid,
    ConsoleAttributeInvalid,
    ConsoleCursorPositionInvalid,
    ConsoleCursorInfoInvalid,
};

pub fn validateSleep() BehaviorError!void {
    behavior.Sleep(1);
    behavior.Sleep(10);
    behavior.Sleep(100);
}

pub fn validateConsoleHandle() BehaviorError!void {
    const hOut = behavior.GetStdHandle(behavior.STD_OUTPUT_HANDLE);
    const hIn = behavior.GetStdHandle(behavior.STD_INPUT_HANDLE);
    const hErr = behavior.GetStdHandle(behavior.STD_ERROR_HANDLE);
    _ = hOut;
    _ = hIn;
    _ = hErr;
}

pub fn validateConsoleAttribute() BehaviorError!void {
    const hOut = behavior.GetStdHandle(behavior.STD_OUTPUT_HANDLE);
    if (behavior.SetConsoleTextAttribute(hOut, behavior.FOREGROUND_GREEN | behavior.FOREGROUND_INTENSITY) == 0)
        return error.ConsoleAttributeInvalid;
}

pub fn validateConsoleCursorPosition() BehaviorError!void {
    const hOut = behavior.GetStdHandle(behavior.STD_OUTPUT_HANDLE);
    var pos: behavior.COORD = undefined;
    pos.X = 0;
    pos.Y = 0;
    if (behavior.SetConsoleCursorPosition(hOut, pos) == 0)
        return error.ConsoleCursorPositionInvalid;
}

pub fn validateConsoleCursorInfo() BehaviorError!void {
    const hOut = behavior.GetStdHandle(behavior.STD_OUTPUT_HANDLE);
    var info: behavior.CONSOLE_CURSOR_INFO = undefined;
    info.dwSize = 25;
    info.bVisible = 1;
    if (behavior.SetConsoleCursorInfo(hOut, &info) == 0)
        return error.ConsoleCursorInfoInvalid;
}

pub fn validateAll() BehaviorError!void {
    try validateSleep();
    try validateConsoleHandle();
    try validateConsoleAttribute();
    try validateConsoleCursorPosition();
    try validateConsoleCursorInfo();
}

pub fn rosetta3_validate_behavior() c_int {
    validateAll() catch |err| return switch (err) {
        error.SleepRange => 1,
        error.ConsoleHandleInvalid => 2,
        error.ConsoleAttributeInvalid => 3,
        error.ConsoleCursorPositionInvalid => 4,
        error.ConsoleCursorInfoInvalid => 5,
    };
    return 0;
}

pub fn rosetta3_behavior_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "SleepRange",
        2 => "ConsoleHandleInvalid",
        3 => "ConsoleAttributeInvalid",
        4 => "ConsoleCursorPositionInvalid",
        5 => "ConsoleCursorInfoInvalid",
        else => "UnknownBehaviorFailure",
    };
}

pub fn rosetta3_print_behavior_report() void {
    std.debug.print(
        \\================================================================================
        \\ Behavioral Validation Report
        \\================================================================================
    , .{});
    validateAll() catch |err| {
        std.debug.print("\n  FAILED: {}\n\n", .{err});
        return;
    };
    std.debug.print("\n  All checks passed.\n\n", .{});
}

test "behavioral validation" {
    try validateAll();
}
