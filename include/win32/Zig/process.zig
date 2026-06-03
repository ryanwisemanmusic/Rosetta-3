const std = @import("std");

const win32_all = @import("win32_pending");
const proc = win32_all;

pub const ProcessAbiError = error{
    InvalidInfiniteConstant,
    InvalidStandardRightsRequired,
    InvalidSynchronizeConstant,
    InvalidProcessDupHandle,
    InvalidProcessQueryInformation,
    InvalidProcessSuspendResume,
    InvalidProcessTerminate,
    InvalidProcessVmRead,
    InvalidTokenAssignPrimary,
    InvalidTokenDuplicate,
    InvalidTokenImpersonate,
    InvalidTokenQuery,
    InvalidTokenQuerySource,
    InvalidSePrivilegeEnabledByDefault,
    InvalidSePrivilegeEnabled,
    InvalidStartfUseShowWindow,
    InvalidStartfUseStdHandles,
    InvalidNormalPriorityClass,
    InvalidJobObjectLimitKillOnJobClose,
    InvalidStatusWait0,
    InvalidStatusTimeout,
    InvalidStatusPending,
    InvalidStartupInfoASize,
    InvalidStartupInfoWSize,
    InvalidStartupInfoExASize,
    InvalidStartupInfoExWSize,
    InvalidProcessInformationSize,
    InvalidJobObjectBasicLimitInformationSize,
    InvalidIoCountersSize,
    InvalidJobObjectExtendedLimitInformationSize,
};

pub const WindowsProcessSpec = struct {
    pub const INFINITE: comptime_int = 0xffffffff;
    pub const STANDARD_RIGHTS_REQUIRED: comptime_int = 0x000F0000;
    pub const SYNCHRONIZE: comptime_int = 0x00100000;
    pub const PROCESS_DUP_HANDLE: comptime_int = 0x0040;
    pub const PROCESS_QUERY_INFORMATION: comptime_int = 0x0400;
    pub const PROCESS_SUSPEND_RESUME: comptime_int = 0x0800;
    pub const PROCESS_TERMINATE: comptime_int = 0x0001;
    pub const PROCESS_VM_READ: comptime_int = 0x0010;
    pub const TOKEN_ASSIGN_PRIMARY: comptime_int = 0x0001;
    pub const TOKEN_DUPLICATE: comptime_int = 0x0002;
    pub const TOKEN_IMPERSONATE: comptime_int = 0x0004;
    pub const TOKEN_QUERY: comptime_int = 0x0008;
    pub const TOKEN_QUERY_SOURCE: comptime_int = 0x0010;
    pub const SE_PRIVILEGE_ENABLED_BY_DEFAULT: comptime_int = 0x00000001;
    pub const SE_PRIVILEGE_ENABLED: comptime_int = 0x00000002;
    pub const STARTF_USESHOWWINDOW: comptime_int = 0x00000001;
    pub const STARTF_USESTDHANDLES: comptime_int = 0x00000100;
    pub const NORMAL_PRIORITY_CLASS: comptime_int = 0x00000020;
    pub const JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE: comptime_int = 0x00002000;
    pub const STATUS_WAIT_0: comptime_int = 0x00000000;
    pub const STATUS_TIMEOUT: comptime_int = 0x00000102;
    pub const STATUS_PENDING: comptime_int = 0x00000103;

    pub const sizeof_STARTUPINFOA: comptime_int = 104;
    pub const sizeof_STARTUPINFOW: comptime_int = 104;
    pub const sizeof_STARTUPINFOEXA: comptime_int = 112;
    pub const sizeof_STARTUPINFOEXW: comptime_int = 112;
    pub const sizeof_PROCESS_INFORMATION: comptime_int = 24;
    pub const sizeof_JOBOBJECT_BASIC_LIMIT_INFORMATION: comptime_int = 48;
    pub const sizeof_IO_COUNTERS: comptime_int = 48;
    pub const sizeof_JOBOBJECT_EXTENDED_LIMIT_INFORMATION: comptime_int = 112;
};

pub fn validateProcessConstants() ProcessAbiError!void {
    if (proc.INFINITE != WindowsProcessSpec.INFINITE)
        return error.InvalidInfiniteConstant;

    if (proc.STANDARD_RIGHTS_REQUIRED != WindowsProcessSpec.STANDARD_RIGHTS_REQUIRED)
        return error.InvalidStandardRightsRequired;

    if (proc.SYNCHRONIZE != WindowsProcessSpec.SYNCHRONIZE)
        return error.InvalidSynchronizeConstant;

    if (proc.PROCESS_DUP_HANDLE != WindowsProcessSpec.PROCESS_DUP_HANDLE)
        return error.InvalidProcessDupHandle;

    if (proc.PROCESS_QUERY_INFORMATION != WindowsProcessSpec.PROCESS_QUERY_INFORMATION)
        return error.InvalidProcessQueryInformation;

    if (proc.PROCESS_SUSPEND_RESUME != WindowsProcessSpec.PROCESS_SUSPEND_RESUME)
        return error.InvalidProcessSuspendResume;

    if (proc.PROCESS_TERMINATE != WindowsProcessSpec.PROCESS_TERMINATE)
        return error.InvalidProcessTerminate;

    if (proc.PROCESS_VM_READ != WindowsProcessSpec.PROCESS_VM_READ)
        return error.InvalidProcessVmRead;

    if (proc.TOKEN_ASSIGN_PRIMARY != WindowsProcessSpec.TOKEN_ASSIGN_PRIMARY)
        return error.InvalidTokenAssignPrimary;

    if (proc.TOKEN_DUPLICATE != WindowsProcessSpec.TOKEN_DUPLICATE)
        return error.InvalidTokenDuplicate;

    if (proc.TOKEN_IMPERSONATE != WindowsProcessSpec.TOKEN_IMPERSONATE)
        return error.InvalidTokenImpersonate;

    if (proc.TOKEN_QUERY != WindowsProcessSpec.TOKEN_QUERY)
        return error.InvalidTokenQuery;

    if (proc.TOKEN_QUERY_SOURCE != WindowsProcessSpec.TOKEN_QUERY_SOURCE)
        return error.InvalidTokenQuerySource;

    if (proc.SE_PRIVILEGE_ENABLED_BY_DEFAULT != WindowsProcessSpec.SE_PRIVILEGE_ENABLED_BY_DEFAULT)
        return error.InvalidSePrivilegeEnabledByDefault;

    if (proc.SE_PRIVILEGE_ENABLED != WindowsProcessSpec.SE_PRIVILEGE_ENABLED)
        return error.InvalidSePrivilegeEnabled;

    if (proc.STARTF_USESHOWWINDOW != WindowsProcessSpec.STARTF_USESHOWWINDOW)
        return error.InvalidStartfUseShowWindow;

    if (proc.STARTF_USESTDHANDLES != WindowsProcessSpec.STARTF_USESTDHANDLES)
        return error.InvalidStartfUseStdHandles;

    if (proc.NORMAL_PRIORITY_CLASS != WindowsProcessSpec.NORMAL_PRIORITY_CLASS)
        return error.InvalidNormalPriorityClass;

    if (proc.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE != WindowsProcessSpec.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE)
        return error.InvalidJobObjectLimitKillOnJobClose;

    if (proc.STATUS_WAIT_0 != WindowsProcessSpec.STATUS_WAIT_0)
        return error.InvalidStatusWait0;

    if (proc.STATUS_TIMEOUT != WindowsProcessSpec.STATUS_TIMEOUT)
        return error.InvalidStatusTimeout;

    if (proc.STATUS_PENDING != WindowsProcessSpec.STATUS_PENDING)
        return error.InvalidStatusPending;
}

pub fn validateProcessStructSizes() ProcessAbiError!void {
    if (@sizeOf(proc.STARTUPINFOA) != WindowsProcessSpec.sizeof_STARTUPINFOA)
        return error.InvalidStartupInfoASize;
    if (@sizeOf(proc.STARTUPINFOW) != WindowsProcessSpec.sizeof_STARTUPINFOW)
        return error.InvalidStartupInfoWSize;
    if (@sizeOf(proc.STARTUPINFOEXA) != WindowsProcessSpec.sizeof_STARTUPINFOEXA)
        return error.InvalidStartupInfoExASize;
    if (@sizeOf(proc.STARTUPINFOEXW) != WindowsProcessSpec.sizeof_STARTUPINFOEXW)
        return error.InvalidStartupInfoExWSize;
    if (@sizeOf(proc.PROCESS_INFORMATION) != WindowsProcessSpec.sizeof_PROCESS_INFORMATION)
        return error.InvalidProcessInformationSize;
    if (@sizeOf(proc.JOBOBJECT_BASIC_LIMIT_INFORMATION) != WindowsProcessSpec.sizeof_JOBOBJECT_BASIC_LIMIT_INFORMATION)
        return error.InvalidJobObjectBasicLimitInformationSize;
    if (@sizeOf(proc.IO_COUNTERS) != WindowsProcessSpec.sizeof_IO_COUNTERS)
        return error.InvalidIoCountersSize;
    if (@sizeOf(proc.JOBOBJECT_EXTENDED_LIMIT_INFORMATION) != WindowsProcessSpec.sizeof_JOBOBJECT_EXTENDED_LIMIT_INFORMATION)
        return error.InvalidJobObjectExtendedLimitInformationSize;
}

pub fn validateAll() ProcessAbiError!void {
    try validateProcessConstants();
    try validateProcessStructSizes();
}

fn reportProcessSizes() void {
    std.debug.print(
        \\================================================================================
        \\ Process Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "STARTUPINFOA", .spec = WindowsProcessSpec.sizeof_STARTUPINFOA, .zig = @sizeOf(proc.STARTUPINFOA) },
        .{ .name = "STARTUPINFOW", .spec = WindowsProcessSpec.sizeof_STARTUPINFOW, .zig = @sizeOf(proc.STARTUPINFOW) },
        .{ .name = "STARTUPINFOEXA", .spec = WindowsProcessSpec.sizeof_STARTUPINFOEXA, .zig = @sizeOf(proc.STARTUPINFOEXA) },
        .{ .name = "STARTUPINFOEXW", .spec = WindowsProcessSpec.sizeof_STARTUPINFOEXW, .zig = @sizeOf(proc.STARTUPINFOEXW) },
        .{ .name = "PROCESS_INFORMATION", .spec = WindowsProcessSpec.sizeof_PROCESS_INFORMATION, .zig = @sizeOf(proc.PROCESS_INFORMATION) },
        .{ .name = "JOBOBJECT_BASIC_LIMIT_INFORMATION", .spec = WindowsProcessSpec.sizeof_JOBOBJECT_BASIC_LIMIT_INFORMATION, .zig = @sizeOf(proc.JOBOBJECT_BASIC_LIMIT_INFORMATION) },
        .{ .name = "IO_COUNTERS", .spec = WindowsProcessSpec.sizeof_IO_COUNTERS, .zig = @sizeOf(proc.IO_COUNTERS) },
        .{ .name = "JOBOBJECT_EXTENDED_LIMIT_INFORMATION", .spec = WindowsProcessSpec.sizeof_JOBOBJECT_EXTENDED_LIMIT_INFORMATION, .zig = @sizeOf(proc.JOBOBJECT_EXTENDED_LIMIT_INFORMATION) },
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

pub export fn rosetta3_print_process_report() void {
    reportProcessSizes();
}

pub export fn rosetta3_validate_process() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidInfiniteConstant => 1,
        error.InvalidStandardRightsRequired => 2,
        error.InvalidSynchronizeConstant => 3,
        error.InvalidProcessDupHandle => 4,
        error.InvalidProcessQueryInformation => 5,
        error.InvalidProcessSuspendResume => 6,
        error.InvalidProcessTerminate => 7,
        error.InvalidProcessVmRead => 8,
        error.InvalidTokenAssignPrimary => 9,
        error.InvalidTokenDuplicate => 10,
        error.InvalidTokenImpersonate => 11,
        error.InvalidTokenQuery => 12,
        error.InvalidTokenQuerySource => 13,
        error.InvalidSePrivilegeEnabledByDefault => 14,
        error.InvalidSePrivilegeEnabled => 15,
        error.InvalidStartfUseShowWindow => 16,
        error.InvalidStartfUseStdHandles => 17,
        error.InvalidNormalPriorityClass => 18,
        error.InvalidJobObjectLimitKillOnJobClose => 19,
        error.InvalidStatusWait0 => 20,
        error.InvalidStatusTimeout => 21,
        error.InvalidStatusPending => 22,
        error.InvalidStartupInfoASize => 23,
        error.InvalidStartupInfoWSize => 24,
        error.InvalidStartupInfoExASize => 25,
        error.InvalidStartupInfoExWSize => 26,
        error.InvalidProcessInformationSize => 27,
        error.InvalidJobObjectBasicLimitInformationSize => 28,
        error.InvalidIoCountersSize => 29,
        error.InvalidJobObjectExtendedLimitInformationSize => 30,
    };
    return 0;
}

pub export fn rosetta3_process_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidInfiniteConstant",
        2 => "InvalidStandardRightsRequired",
        3 => "InvalidSynchronizeConstant",
        4 => "InvalidProcessDupHandle",
        5 => "InvalidProcessQueryInformation",
        6 => "InvalidProcessSuspendResume",
        7 => "InvalidProcessTerminate",
        8 => "InvalidProcessVmRead",
        9 => "InvalidTokenAssignPrimary",
        10 => "InvalidTokenDuplicate",
        11 => "InvalidTokenImpersonate",
        12 => "InvalidTokenQuery",
        13 => "InvalidTokenQuerySource",
        14 => "InvalidSePrivilegeEnabledByDefault",
        15 => "InvalidSePrivilegeEnabled",
        16 => "InvalidStartfUseShowWindow",
        17 => "InvalidStartfUseStdHandles",
        18 => "InvalidNormalPriorityClass",
        19 => "InvalidJobObjectLimitKillOnJobClose",
        20 => "InvalidStatusWait0",
        21 => "InvalidStatusTimeout",
        22 => "InvalidStatusPending",
        23 => "InvalidStartupInfoASize",
        24 => "InvalidStartupInfoWSize",
        25 => "InvalidStartupInfoExASize",
        26 => "InvalidStartupInfoExWSize",
        27 => "InvalidProcessInformationSize",
        28 => "InvalidJobObjectBasicLimitInformationSize",
        29 => "InvalidIoCountersSize",
        30 => "InvalidJobObjectExtendedLimitInformationSize",
        else => "UnknownProcessFailure",
    };
}

test "process.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
