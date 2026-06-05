const std = @import("std");

const win32_all = @import("win32_pending");

pub const ThreadsAbiError = error{
    InvalidInfinite,
    InvalidStandardRightsRequired,
    InvalidSynchronize,
    InvalidStatusWait0,
    InvalidStatusAbandonedWait0,
    InvalidStatusTimeout,
    InvalidStatusPending,
    InvalidWaitFailed,
    InvalidWaitObject0,
    InvalidWaitAbandoned,
    InvalidWaitTimeout,
    InvalidTlsOutOfIndexes,
    InvalidFlsOutOfIndexes,
    InvalidCreateSuspended,
    InvalidThreadGetContext,
    InvalidThreadQueryInformation,
    InvalidThreadSuspendResume,
    InvalidThreadTerminate,
    InvalidSemaphoreAllAccess,
    InvalidSemaphoreModifyState,
    InvalidEventAllAccess,
    InvalidEventModifyState,
    InvalidRtlConditionVariableLockmodeShared,
    InvalidImageTlsDirectory32Size,
    InvalidImageTlsDirectory64Size,
    InvalidListEntrySize,
    InvalidRtlCriticalSectionDebugSize,
    InvalidRtlCriticalSectionSize,
    InvalidRtlConditionVariableSize,
    InvalidRtlSrwlockSize,
};

pub const WindowsThreadsSpec = struct {
    pub const INFINITE: comptime_int = 0xffffffff;
    pub const STANDARD_RIGHTS_REQUIRED: comptime_int = 0x000F0000;
    pub const SYNCHRONIZE: comptime_int = 0x00100000;
    pub const STATUS_WAIT_0: comptime_int = 0x00000000;
    pub const STATUS_ABANDONED_WAIT_0: comptime_int = 0x00000080;
    pub const STATUS_TIMEOUT: comptime_int = 0x00000102;
    pub const STATUS_PENDING: comptime_int = 0x00000103;
    pub const WAIT_FAILED: comptime_int = 0xffffffff;
    pub const WAIT_OBJECT_0: comptime_int = 0x00000000;
    pub const WAIT_ABANDONED: comptime_int = 0x00000080;
    pub const WAIT_TIMEOUT: comptime_int = 258;
    pub const TLS_OUT_OF_INDEXES: comptime_int = 0xFFFFFFFF;
    pub const FLS_OUT_OF_INDEXES: comptime_int = 0xFFFFFFFF;
    pub const CREATE_SUSPENDED: comptime_int = 0x00000004;
    pub const THREAD_GET_CONTEXT: comptime_int = 0x0008;
    pub const THREAD_QUERY_INFORMATION: comptime_int = 0x0040;
    pub const THREAD_SUSPEND_RESUME: comptime_int = 0x0002;
    pub const THREAD_TERMINATE: comptime_int = 0x0001;
    pub const SEMAPHORE_ALL_ACCESS: comptime_int = 0x1F0003;
    pub const SEMAPHORE_MODIFY_STATE: comptime_int = 0x0002;
    pub const EVENT_ALL_ACCESS: comptime_int = 0x1F0003;
    pub const EVENT_MODIFY_STATE: comptime_int = 0x0002;
    pub const RTL_CONDITION_VARIABLE_LOCKMODE_SHARED: comptime_int = 0x1;

    pub const sizeof_IMAGE_TLS_DIRECTORY32: comptime_int = 24;
    pub const sizeof_IMAGE_TLS_DIRECTORY64: comptime_int = 40;
    pub const sizeof_LIST_ENTRY: comptime_int = 16;
    pub const sizeof_RTL_CRITICAL_SECTION_DEBUG: comptime_int = 40;
    pub const sizeof_RTL_CRITICAL_SECTION: comptime_int = 40;
    pub const sizeof_RTL_CONDITION_VARIABLE: comptime_int = 8;
    pub const sizeof_RTL_SRWLOCK: comptime_int = 8;
};

pub fn validateThreadsConstants() ThreadsAbiError!void {
    if (win32_all.INFINITE != WindowsThreadsSpec.INFINITE)
        return error.InvalidInfinite;

    if (win32_all.STANDARD_RIGHTS_REQUIRED != WindowsThreadsSpec.STANDARD_RIGHTS_REQUIRED)
        return error.InvalidStandardRightsRequired;

    if (win32_all.SYNCHRONIZE != WindowsThreadsSpec.SYNCHRONIZE)
        return error.InvalidSynchronize;

    if (win32_all.STATUS_WAIT_0 != WindowsThreadsSpec.STATUS_WAIT_0)
        return error.InvalidStatusWait0;

    if (win32_all.STATUS_ABANDONED_WAIT_0 != WindowsThreadsSpec.STATUS_ABANDONED_WAIT_0)
        return error.InvalidStatusAbandonedWait0;

    if (win32_all.STATUS_TIMEOUT != WindowsThreadsSpec.STATUS_TIMEOUT)
        return error.InvalidStatusTimeout;

    if (win32_all.STATUS_PENDING != WindowsThreadsSpec.STATUS_PENDING)
        return error.InvalidStatusPending;

    if (win32_all.WAIT_FAILED != WindowsThreadsSpec.WAIT_FAILED)
        return error.InvalidWaitFailed;

    if (win32_all.WAIT_OBJECT_0 != WindowsThreadsSpec.WAIT_OBJECT_0)
        return error.InvalidWaitObject0;

    if (win32_all.WAIT_ABANDONED != WindowsThreadsSpec.WAIT_ABANDONED)
        return error.InvalidWaitAbandoned;

    if (win32_all.WAIT_TIMEOUT != WindowsThreadsSpec.WAIT_TIMEOUT)
        return error.InvalidWaitTimeout;

    if (win32_all.TLS_OUT_OF_INDEXES != WindowsThreadsSpec.TLS_OUT_OF_INDEXES)
        return error.InvalidTlsOutOfIndexes;

    if (win32_all.FLS_OUT_OF_INDEXES != WindowsThreadsSpec.FLS_OUT_OF_INDEXES)
        return error.InvalidFlsOutOfIndexes;

    if (win32_all.CREATE_SUSPENDED != WindowsThreadsSpec.CREATE_SUSPENDED)
        return error.InvalidCreateSuspended;

    if (win32_all.THREAD_GET_CONTEXT != WindowsThreadsSpec.THREAD_GET_CONTEXT)
        return error.InvalidThreadGetContext;

    if (win32_all.THREAD_QUERY_INFORMATION != WindowsThreadsSpec.THREAD_QUERY_INFORMATION)
        return error.InvalidThreadQueryInformation;

    if (win32_all.THREAD_SUSPEND_RESUME != WindowsThreadsSpec.THREAD_SUSPEND_RESUME)
        return error.InvalidThreadSuspendResume;

    if (win32_all.THREAD_TERMINATE != WindowsThreadsSpec.THREAD_TERMINATE)
        return error.InvalidThreadTerminate;

    if (win32_all.SEMAPHORE_ALL_ACCESS != WindowsThreadsSpec.SEMAPHORE_ALL_ACCESS)
        return error.InvalidSemaphoreAllAccess;

    if (win32_all.SEMAPHORE_MODIFY_STATE != WindowsThreadsSpec.SEMAPHORE_MODIFY_STATE)
        return error.InvalidSemaphoreModifyState;

    if (win32_all.EVENT_ALL_ACCESS != WindowsThreadsSpec.EVENT_ALL_ACCESS)
        return error.InvalidEventAllAccess;

    if (win32_all.EVENT_MODIFY_STATE != WindowsThreadsSpec.EVENT_MODIFY_STATE)
        return error.InvalidEventModifyState;

    if (win32_all.RTL_CONDITION_VARIABLE_LOCKMODE_SHARED != WindowsThreadsSpec.RTL_CONDITION_VARIABLE_LOCKMODE_SHARED)
        return error.InvalidRtlConditionVariableLockmodeShared;
}

pub fn validateThreadsStructSizes() ThreadsAbiError!void {
    if (@sizeOf(win32_all.IMAGE_TLS_DIRECTORY32) != WindowsThreadsSpec.sizeof_IMAGE_TLS_DIRECTORY32)
        return error.InvalidImageTlsDirectory32Size;

    if (@sizeOf(win32_all.IMAGE_TLS_DIRECTORY64) != WindowsThreadsSpec.sizeof_IMAGE_TLS_DIRECTORY64)
        return error.InvalidImageTlsDirectory64Size;

    if (@sizeOf(win32_all.LIST_ENTRY) != WindowsThreadsSpec.sizeof_LIST_ENTRY)
        return error.InvalidListEntrySize;

    if (@sizeOf(win32_all.RTL_CRITICAL_SECTION_DEBUG) != WindowsThreadsSpec.sizeof_RTL_CRITICAL_SECTION_DEBUG)
        return error.InvalidRtlCriticalSectionDebugSize;

    if (@sizeOf(win32_all.RTL_CRITICAL_SECTION) != WindowsThreadsSpec.sizeof_RTL_CRITICAL_SECTION)
        return error.InvalidRtlCriticalSectionSize;

    if (@sizeOf(win32_all.RTL_CONDITION_VARIABLE) != WindowsThreadsSpec.sizeof_RTL_CONDITION_VARIABLE)
        return error.InvalidRtlConditionVariableSize;

    if (@sizeOf(win32_all.RTL_SRWLOCK) != WindowsThreadsSpec.sizeof_RTL_SRWLOCK)
        return error.InvalidRtlSrwlockSize;
}

pub fn validateAll() ThreadsAbiError!void {
    try validateThreadsConstants();
    try validateThreadsStructSizes();
}

fn reportThreadsSizes() void {
    std.debug.print(
        \\================================================================================
        \\ Threads Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "IMAGE_TLS_DIRECTORY32", .spec = WindowsThreadsSpec.sizeof_IMAGE_TLS_DIRECTORY32, .zig = @sizeOf(win32_all.IMAGE_TLS_DIRECTORY32) },
        .{ .name = "IMAGE_TLS_DIRECTORY64", .spec = WindowsThreadsSpec.sizeof_IMAGE_TLS_DIRECTORY64, .zig = @sizeOf(win32_all.IMAGE_TLS_DIRECTORY64) },
        .{ .name = "LIST_ENTRY", .spec = WindowsThreadsSpec.sizeof_LIST_ENTRY, .zig = @sizeOf(win32_all.LIST_ENTRY) },
        .{ .name = "RTL_CRITICAL_SECTION_DEBUG", .spec = WindowsThreadsSpec.sizeof_RTL_CRITICAL_SECTION_DEBUG, .zig = @sizeOf(win32_all.RTL_CRITICAL_SECTION_DEBUG) },
        .{ .name = "RTL_CRITICAL_SECTION", .spec = WindowsThreadsSpec.sizeof_RTL_CRITICAL_SECTION, .zig = @sizeOf(win32_all.RTL_CRITICAL_SECTION) },
        .{ .name = "RTL_CONDITION_VARIABLE", .spec = WindowsThreadsSpec.sizeof_RTL_CONDITION_VARIABLE, .zig = @sizeOf(win32_all.RTL_CONDITION_VARIABLE) },
        .{ .name = "RTL_SRWLOCK", .spec = WindowsThreadsSpec.sizeof_RTL_SRWLOCK, .zig = @sizeOf(win32_all.RTL_SRWLOCK) },
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

pub export fn rosette_print_threads_report() void {
    reportThreadsSizes();
}

pub export fn rosette_validate_threads() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidInfinite => 1,
        error.InvalidStandardRightsRequired => 2,
        error.InvalidSynchronize => 3,
        error.InvalidStatusWait0 => 4,
        error.InvalidStatusAbandonedWait0 => 5,
        error.InvalidStatusTimeout => 6,
        error.InvalidStatusPending => 7,
        error.InvalidWaitFailed => 8,
        error.InvalidWaitObject0 => 9,
        error.InvalidWaitAbandoned => 10,
        error.InvalidWaitTimeout => 11,
        error.InvalidTlsOutOfIndexes => 12,
        error.InvalidFlsOutOfIndexes => 13,
        error.InvalidCreateSuspended => 14,
        error.InvalidThreadGetContext => 15,
        error.InvalidThreadQueryInformation => 16,
        error.InvalidThreadSuspendResume => 17,
        error.InvalidThreadTerminate => 18,
        error.InvalidSemaphoreAllAccess => 19,
        error.InvalidSemaphoreModifyState => 20,
        error.InvalidEventAllAccess => 21,
        error.InvalidEventModifyState => 22,
        error.InvalidRtlConditionVariableLockmodeShared => 23,
        error.InvalidImageTlsDirectory32Size => 24,
        error.InvalidImageTlsDirectory64Size => 25,
        error.InvalidListEntrySize => 26,
        error.InvalidRtlCriticalSectionDebugSize => 27,
        error.InvalidRtlCriticalSectionSize => 28,
        error.InvalidRtlConditionVariableSize => 29,
        error.InvalidRtlSrwlockSize => 30,
    };
    return 0;
}

pub export fn rosette_threads_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidInfinite",
        2 => "InvalidStandardRightsRequired",
        3 => "InvalidSynchronize",
        4 => "InvalidStatusWait0",
        5 => "InvalidStatusAbandonedWait0",
        6 => "InvalidStatusTimeout",
        7 => "InvalidStatusPending",
        8 => "InvalidWaitFailed",
        9 => "InvalidWaitObject0",
        10 => "InvalidWaitAbandoned",
        11 => "InvalidWaitTimeout",
        12 => "InvalidTlsOutOfIndexes",
        13 => "InvalidFlsOutOfIndexes",
        14 => "InvalidCreateSuspended",
        15 => "InvalidThreadGetContext",
        16 => "InvalidThreadQueryInformation",
        17 => "InvalidThreadSuspendResume",
        18 => "InvalidThreadTerminate",
        19 => "InvalidSemaphoreAllAccess",
        20 => "InvalidSemaphoreModifyState",
        21 => "InvalidEventAllAccess",
        22 => "InvalidEventModifyState",
        23 => "InvalidRtlConditionVariableLockmodeShared",
        24 => "InvalidImageTlsDirectory32Size",
        25 => "InvalidImageTlsDirectory64Size",
        26 => "InvalidListEntrySize",
        27 => "InvalidRtlCriticalSectionDebugSize",
        28 => "InvalidRtlCriticalSectionSize",
        29 => "InvalidRtlConditionVariableSize",
        30 => "InvalidRtlSrwlockSize",
        else => "UnknownThreadsFailure",
    };
}

test "threads.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
