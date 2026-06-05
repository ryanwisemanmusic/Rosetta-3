const std = @import("std");

const win32_all = @import("win32_pending");

pub const AtomicAbiError = error{
    Invalid8BitAtomicFunctions,
    Invalid16BitAtomicFunctions,
    Invalid32BitAtomicFunctions,
    Invalid64BitAtomicFunctions,
    Invalid128BitAtomicFunctions,
    InvalidMemoryBarrier,
    InvalidYieldProcessor,
    InvalidReadWriteBarrier,
    InvalidFunctionPointerSize,
};

pub const WindowsAtomicSpec = struct {
    pub const FUNCTION_POINTER_SIZE: comptime_int = 8;
};

fn checkFnPtrSize(comptime T: type) bool {
    return @sizeOf(*const T) == WindowsAtomicSpec.FUNCTION_POINTER_SIZE;
}

pub fn validateAtomicConstants() AtomicAbiError!void {
    if (win32_all.InterlockedExchange8 != win32_all._InterlockedExchange8 or
        win32_all.InterlockedExchangeAdd8 != win32_all._InterlockedExchangeAdd8 or
        win32_all.InterlockedExchangeAnd8 != win32_all._InterlockedExchangeAnd8 or
        win32_all.InterlockedExchangeOr8 != win32_all._InterlockedExchangeOr8 or
        win32_all.InterlockedExchangeXor8 != win32_all._InterlockedExchangeXor8 or
        win32_all.InterlockedDecrement8 != win32_all._InterlockedDecrement8 or
        win32_all.InterlockedIncrement8 != win32_all._InterlockedIncrement8 or
        win32_all.InterlockedCompareExchange8 != win32_all._InterlockedCompareExchange8)
        return error.Invalid8BitAtomicFunctions;

    if (win32_all.InterlockedExchange16 != win32_all._InterlockedExchange16 or
        win32_all.InterlockedExchangeAdd16 != win32_all._InterlockedExchangeAdd16 or
        win32_all.InterlockedExchangeAnd16 != win32_all._InterlockedExchangeAnd16 or
        win32_all.InterlockedExchangeOr16 != win32_all._InterlockedExchangeOr16 or
        win32_all.InterlockedExchangeXor16 != win32_all._InterlockedExchangeXor16 or
        win32_all.InterlockedDecrement16 != win32_all._InterlockedDecrement16 or
        win32_all.InterlockedIncrement16 != win32_all._InterlockedIncrement16 or
        win32_all.InterlockedCompareExchange16 != win32_all._InterlockedCompareExchange16)
        return error.Invalid16BitAtomicFunctions;

    if (win32_all.InterlockedExchange != win32_all._InterlockedExchange or
        win32_all.InterlockedExchangeAdd != win32_all._InterlockedExchangeAdd or
        win32_all.InterlockedExchangeAnd != win32_all._InterlockedExchangeAnd or
        win32_all.InterlockedExchangeOr != win32_all._InterlockedExchangeOr or
        win32_all.InterlockedExchangeXor != win32_all._InterlockedExchangeXor or
        win32_all.InterlockedDecrement != win32_all._InterlockedDecrement or
        win32_all.InterlockedIncrement != win32_all._InterlockedIncrement or
        win32_all.InterlockedCompareExchange != win32_all._InterlockedCompareExchange)
        return error.Invalid32BitAtomicFunctions;

    if (win32_all.InterlockedExchange64 != win32_all._InterlockedExchange64 or
        win32_all.InterlockedExchangeAdd64 != win32_all._InterlockedExchangeAdd64 or
        win32_all.InterlockedExchangeAnd64 != win32_all._InterlockedExchangeAnd64 or
        win32_all.InterlockedExchangeOr64 != win32_all._InterlockedExchangeOr64 or
        win32_all.InterlockedExchangeXor64 != win32_all._InterlockedExchangeXor64 or
        win32_all.InterlockedDecrement64 != win32_all._InterlockedDecrement64 or
        win32_all.InterlockedIncrement64 != win32_all._InterlockedIncrement64 or
        win32_all.InterlockedCompareExchange64 != win32_all._InterlockedCompareExchange64)
        return error.Invalid64BitAtomicFunctions;

    if (win32_all.InterlockedCompareExchange128 != win32_all._InterlockedCompareExchange128)
        return error.Invalid128BitAtomicFunctions;
}

pub fn validateAtomicFunctionPointerSizes() AtomicAbiError!void {
    if (!checkFnPtrSize(@TypeOf(win32_all._InterlockedExchange8)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAdd8)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAnd8)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeOr8)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeXor8)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedDecrement8)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedIncrement8)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedCompareExchange8)))
        return error.InvalidFunctionPointerSize;

    if (!checkFnPtrSize(@TypeOf(win32_all._InterlockedExchange16)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAdd16)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAnd16)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeOr16)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeXor16)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedDecrement16)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedIncrement16)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedCompareExchange16)))
        return error.InvalidFunctionPointerSize;

    if (!checkFnPtrSize(@TypeOf(win32_all._InterlockedExchange)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAdd)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAnd)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeOr)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeXor)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedDecrement)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedIncrement)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedCompareExchange)))
        return error.InvalidFunctionPointerSize;

    if (!checkFnPtrSize(@TypeOf(win32_all._InterlockedExchange64)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAdd64)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeAnd64)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeOr64)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedExchangeXor64)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedDecrement64)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedIncrement64)) or
        !checkFnPtrSize(@TypeOf(win32_all._InterlockedCompareExchange64)))
        return error.InvalidFunctionPointerSize;

    if (!checkFnPtrSize(@TypeOf(win32_all._InterlockedCompareExchange128)))
        return error.InvalidFunctionPointerSize;
}

pub fn validateMacros() AtomicAbiError!void {
    if (@TypeOf(win32_all.MemoryBarrier) != @TypeOf(win32_all.__faststorefence))
        return error.InvalidMemoryBarrier;
    if (@TypeOf(win32_all.YieldProcessor) != @TypeOf(win32_all._mm_pause))
        return error.InvalidYieldProcessor;
    if (@TypeOf(win32_all._ReadWriteBarrier) != fn () callconv(.c) void)
        return error.InvalidReadWriteBarrier;
}

pub fn validateAll() AtomicAbiError!void {
    try validateAtomicConstants();
    try validateAtomicFunctionPointerSizes();
    try validateMacros();
}

fn reportAtomicTable() void {
    std.debug.print(
        \\================================================================================
        \\ Atomic Function Pointer Sizes Table
        \\================================================================================
        \\ Function Name                       | Expected Size | Actual Size
        \\--------------------------------------+---------------+-------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, size: usize }{
        .{ .name = "_InterlockedExchange8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchange8)) },
        .{ .name = "_InterlockedExchangeAdd8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAdd8)) },
        .{ .name = "_InterlockedExchangeAnd8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAnd8)) },
        .{ .name = "_InterlockedExchangeOr8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeOr8)) },
        .{ .name = "_InterlockedExchangeXor8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeXor8)) },
        .{ .name = "_InterlockedDecrement8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedDecrement8)) },
        .{ .name = "_InterlockedIncrement8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedIncrement8)) },
        .{ .name = "_InterlockedCompareExchange8", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedCompareExchange8)) },
        .{ .name = "_InterlockedExchange16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchange16)) },
        .{ .name = "_InterlockedExchangeAdd16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAdd16)) },
        .{ .name = "_InterlockedExchangeAnd16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAnd16)) },
        .{ .name = "_InterlockedExchangeOr16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeOr16)) },
        .{ .name = "_InterlockedExchangeXor16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeXor16)) },
        .{ .name = "_InterlockedDecrement16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedDecrement16)) },
        .{ .name = "_InterlockedIncrement16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedIncrement16)) },
        .{ .name = "_InterlockedCompareExchange16", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedCompareExchange16)) },
        .{ .name = "_InterlockedExchange", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchange)) },
        .{ .name = "_InterlockedExchangeAdd", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAdd)) },
        .{ .name = "_InterlockedExchangeAnd", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAnd)) },
        .{ .name = "_InterlockedExchangeOr", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeOr)) },
        .{ .name = "_InterlockedExchangeXor", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeXor)) },
        .{ .name = "_InterlockedDecrement", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedDecrement)) },
        .{ .name = "_InterlockedIncrement", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedIncrement)) },
        .{ .name = "_InterlockedCompareExchange", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedCompareExchange)) },
        .{ .name = "_InterlockedExchange64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchange64)) },
        .{ .name = "_InterlockedExchangeAdd64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAdd64)) },
        .{ .name = "_InterlockedExchangeAnd64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeAnd64)) },
        .{ .name = "_InterlockedExchangeOr64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeOr64)) },
        .{ .name = "_InterlockedExchangeXor64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedExchangeXor64)) },
        .{ .name = "_InterlockedDecrement64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedDecrement64)) },
        .{ .name = "_InterlockedIncrement64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedIncrement64)) },
        .{ .name = "_InterlockedCompareExchange64", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedCompareExchange64)) },
        .{ .name = "_InterlockedCompareExchange128", .size = @sizeOf(*const @TypeOf(win32_all._InterlockedCompareExchange128)) },
    };
    inline for (table) |entry| {
        std.debug.print(
            \\ {s:<35} | {d:<13} | {d:<11}
            \\
        , .{ entry.name, WindowsAtomicSpec.FUNCTION_POINTER_SIZE, entry.size });
    }
    std.debug.print(
        \\================================================================================
        \\
    , .{});
}

pub export fn rosette_print_atomic_report() void {
    reportAtomicTable();
}

pub export fn rosette_validate_atomic() c_int {
    validateAll() catch |err| return switch (err) {
        error.Invalid8BitAtomicFunctions => 1,
        error.Invalid16BitAtomicFunctions => 2,
        error.Invalid32BitAtomicFunctions => 3,
        error.Invalid64BitAtomicFunctions => 4,
        error.Invalid128BitAtomicFunctions => 5,
        error.InvalidMemoryBarrier => 6,
        error.InvalidYieldProcessor => 7,
        error.InvalidReadWriteBarrier => 8,
        error.InvalidFunctionPointerSize => 9,
    };
    return 0;
}

pub export fn rosette_atomic_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "Invalid8BitAtomicFunctions",
        2 => "Invalid16BitAtomicFunctions",
        3 => "Invalid32BitAtomicFunctions",
        4 => "Invalid64BitAtomicFunctions",
        5 => "Invalid128BitAtomicFunctions",
        6 => "InvalidMemoryBarrier",
        7 => "InvalidYieldProcessor",
        8 => "InvalidReadWriteBarrier",
        9 => "InvalidFunctionPointerSize",
        else => "UnknownAtomicFailure",
    };
}

test "atomic.h matches pseudo-Windows atomic constants and signatures" {
    try validateAll();
}
