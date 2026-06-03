const std = @import("std");

const win32_all = @import("win32_pending");

pub const SynchapiAbiError = error{
    InvalidSynchronizationBarrierFlags,
};

pub const WindowsSynchapiSpec = struct {
    pub const SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY: comptime_int = 0x1;
    pub const SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY: comptime_int = 0x2;
    pub const SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE: comptime_int = 0x4;
};

pub fn validateSynchapiConstants() SynchapiAbiError!void {
    if (win32_all.SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY != WindowsSynchapiSpec.SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY or
        win32_all.SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY != WindowsSynchapiSpec.SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY or
        win32_all.SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE != WindowsSynchapiSpec.SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE)
        return error.InvalidSynchronizationBarrierFlags;
}

pub fn validateAll() SynchapiAbiError!void {
    try validateSynchapiConstants();
}

pub export fn rosetta3_validate_synchapi() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidSynchronizationBarrierFlags => 1,
    };
    return 0;
}

pub export fn rosetta3_synchapi_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidSynchronizationBarrierFlags",
        else => "UnknownSynchapiFailure",
    };
}

pub export fn rosetta3_print_synchapi_report() void {
    std.debug.print(
        \\================================================================================
        \\ Synchapi Constants Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                      | Win32 Spec | Zig Translated
        \\-------------------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: comptime_int, zig: comptime_int }{
        .{ .name = "SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY", .spec = WindowsSynchapiSpec.SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY, .zig = win32_all.SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY },
        .{ .name = "SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY", .spec = WindowsSynchapiSpec.SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY, .zig = win32_all.SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY },
        .{ .name = "SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE", .spec = WindowsSynchapiSpec.SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE, .zig = win32_all.SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE },
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

test "synchapi.h matches pseudo-Windows constants" {
    try validateAll();
}
