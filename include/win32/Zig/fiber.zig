const std = @import("std");

const win32_all = @import("win32_pending");

pub const FiberAbiError = error{
    InvalidFlsOutOfIndexes,
    InvalidFiberStartRoutineSize,
    InvalidFlsCallbackFunctionSize,
};

pub const WindowsFiberSpec = struct {
    pub const FLS_OUT_OF_INDEXES: comptime_int = 0xFFFFFFFF;
    pub const sizeof_PFIBER_START_ROUTINE: comptime_int = 8;
    pub const sizeof_PFLS_CALLBACK_FUNCTION: comptime_int = 8;
};

pub fn validateFiberConstants() FiberAbiError!void {
    if (win32_all.FLS_OUT_OF_INDEXES != WindowsFiberSpec.FLS_OUT_OF_INDEXES)
        return error.InvalidFlsOutOfIndexes;
}

pub fn validateFiberFunctionPointerSizes() FiberAbiError!void {
    if (@sizeOf(win32_all.PFIBER_START_ROUTINE) != WindowsFiberSpec.sizeof_PFIBER_START_ROUTINE)
        return error.InvalidFiberStartRoutineSize;
    if (@sizeOf(win32_all.PFLS_CALLBACK_FUNCTION) != WindowsFiberSpec.sizeof_PFLS_CALLBACK_FUNCTION)
        return error.InvalidFlsCallbackFunctionSize;
}

pub fn validateAll() FiberAbiError!void {
    try validateFiberConstants();
    try validateFiberFunctionPointerSizes();
}

fn reportFiberSizes() void {
    std.debug.print(
        \\================================================================================
        \\ Fiber Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "PFIBER_START_ROUTINE", .spec = WindowsFiberSpec.sizeof_PFIBER_START_ROUTINE, .zig = @sizeOf(win32_all.PFIBER_START_ROUTINE) },
        .{ .name = "PFLS_CALLBACK_FUNCTION", .spec = WindowsFiberSpec.sizeof_PFLS_CALLBACK_FUNCTION, .zig = @sizeOf(win32_all.PFLS_CALLBACK_FUNCTION) },
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

pub export fn rosetta3_print_fiber_report() void {
    reportFiberSizes();
}

pub export fn rosetta3_validate_fiber() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidFlsOutOfIndexes => 1,
        error.InvalidFiberStartRoutineSize => 2,
        error.InvalidFlsCallbackFunctionSize => 3,
    };
    return 0;
}

pub export fn rosetta3_fiber_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidFlsOutOfIndexes",
        2 => "InvalidFiberStartRoutineSize",
        3 => "InvalidFlsCallbackFunctionSize",
        else => "UnknownFiberFailure",
    };
}

test "fiber.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
