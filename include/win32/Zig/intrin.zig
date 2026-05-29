const std = @import("std");

const win32_all = @import("win32_all");

pub const IntrinAbiError = error{
    InvalidMmxPausePrototype,
    InvalidReadWriteBarrierPrototype,
};

pub const WindowsIntrinSpec = struct {
    pub const fn_mm_pause: type = *const fn () callconv(.C) void;
    pub const fn_ReadWriteBarrier: type = *const fn () callconv(.C) void;
};

fn validateIntrinPrototypes() IntrinAbiError!void {
    if (@TypeOf(win32_all._mm_pause) != WindowsIntrinSpec.fn_mm_pause)
        return error.InvalidMmxPausePrototype;
    if (@TypeOf(win32_all._ReadWriteBarrier) != WindowsIntrinSpec.fn_ReadWriteBarrier)
        return error.InvalidReadWriteBarrierPrototype;
}

pub fn validateAll() IntrinAbiError!void {
    try validateIntrinPrototypes();
}

fn reportIntrinSummary() void {
    std.debug.print(
        \\================================================================================
        \\ Intrin Symbol Validation Summary
        \\================================================================================
        \\ Symbol                 | Status
        \\------------------------+----------------------
    , .{});
    const table = [_]struct { name: []const u8, ok: bool }{
        .{ .name = "_mm_pause", .ok = @TypeOf(win32_all._mm_pause) == WindowsIntrinSpec.fn_mm_pause },
        .{ .name = "_ReadWriteBarrier", .ok = @TypeOf(win32_all._ReadWriteBarrier) == WindowsIntrinSpec.fn_ReadWriteBarrier },
    };
    for (table) |entry| {
        std.debug.print(
            \\ {s:<21} | {s:<21}
        , .{ entry.name, if (entry.ok) "PASS" else "FAIL" });
    }
    std.debug.print(
        \\================================================================================
        \\
    , .{});
}

pub export fn rosetta3_print_intrin_report() void {
    reportIntrinSummary();
}

pub export fn rosetta3_validate_intrin() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidMmxPausePrototype => 1,
        error.InvalidReadWriteBarrierPrototype => 2,
    };
    return 0;
}

pub export fn rosetta3_intrin_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidMmxPausePrototype",
        2 => "InvalidReadWriteBarrierPrototype",
        else => "UnknownIntrinFailure",
    };
}

test "intrin.h matches Windows prototypes" {
    try validateAll();
}
