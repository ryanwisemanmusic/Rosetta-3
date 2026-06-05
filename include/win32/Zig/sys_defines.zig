const std = @import("std");

const win32_sysdefs = @import("win32_sysdefs");
const sysinfo = win32_sysdefs;
const misc = win32_sysdefs;

pub const SysinfoAbiError = error{
    InvalidDisplayDeviceFlags,
    InvalidSystemMetrics,
    InvalidVersionConstants,
    InvalidVersionMaskConstants,
    InvalidRegistryTypeConstants,
    InvalidRegistryAccessConstants,
    InvalidLogicalProcessorRelationship,
    InvalidProcessorCacheType,
    InvalidAllProcessorGroupsConstant,
    InvalidComputerNameLength,
    InvalidSystemInfoSize,
    InvalidDisplayDeviceASize,
    InvalidDisplayDeviceWSize,
    InvalidOsVersionInfoExASize,
    InvalidOsVersionInfoExWSize,
    InvalidCacheDescriptorSize,
    InvalidSystemLogicalProcessorInfoSize,
    InvalidGroupAffinitySize,
    InvalidNumaNodeRelationshipSize,
    InvalidProcessorGroupInfoSize,
    InvalidGroupRelationshipSize,
    InvalidCacheRelationshipSize,
    InvalidProcessorRelationshipSize,
    InvalidSystemLogicalProcessorInfoExSize,
    InvalidProcessMemoryCountersSize,
    InvalidMemoryStatusExSize,
    InvalidProcessorNumberSize,
    InvalidSynchronizationBarrierFlags,
    InvalidMiscTimerConstants,
    InvalidMiscCodePageConstants,
    InvalidMiscFormatMessageConstants,
    InvalidMiscLocaleConstants,
    InvalidMiscSystemTimeSize,
    InvalidMiscTimeZoneInformationSize,
    InvalidMiscTimeCapsSize,
    InvalidMiscNlsVersionInfoSize,
};

pub const WindowsSysinfoSpec = struct {
    pub const DISPLAY_DEVICE_ACTIVE: comptime_int = 0x00000001;
    pub const DISPLAY_DEVICE_ATTACHED: comptime_int = 0x00000002;
    pub const DISPLAY_DEVICE_PRIMARY_DEVICE: comptime_int = 0x00000004;

    pub const SM_CXSCREEN: comptime_int = 0;
    pub const SM_CYSCREEN: comptime_int = 1;
    pub const SM_CMONITORS: comptime_int = 80;

    pub const VER_EQUAL: comptime_int = 1;
    pub const VER_GREATER: comptime_int = 2;
    pub const VER_GREATER_EQUAL: comptime_int = 3;
    pub const VER_LESS: comptime_int = 4;
    pub const VER_LESS_EQUAL: comptime_int = 5;
    pub const VER_AND: comptime_int = 6;
    pub const VER_OR: comptime_int = 7;

    pub const _WIN32_WINNT_WINXP: comptime_int = 0x0501;
    pub const _WIN32_WINNT_WS03: comptime_int = 0x0502;
    pub const _WIN32_WINNT_VISTA: comptime_int = 0x0600;
    pub const _WIN32_WINNT_WIN7: comptime_int = 0x0601;
    pub const _WIN32_WINNT_WIN8: comptime_int = 0x0602;
    pub const _WIN32_WINNT_WIN81: comptime_int = 0x0603;
    pub const _WIN32_WINNT_WIN10: comptime_int = 0x0A00;

    pub const VER_MINORVERSION: comptime_int = 0x0000001;
    pub const VER_MAJORVERSION: comptime_int = 0x0000002;
    pub const VER_BUILDNUMBER: comptime_int = 0x0000004;
    pub const VER_PLATFORMID: comptime_int = 0x0000008;
    pub const VER_SERVICEPACKMINOR: comptime_int = 0x0000010;
    pub const VER_SERVICEPACKMAJOR: comptime_int = 0x0000020;

    pub const REG_NONE: comptime_int = 0;
    pub const REG_SZ: comptime_int = 1;
    pub const REG_EXPAND_SZ: comptime_int = 2;
    pub const REG_BINARY: comptime_int = 3;
    pub const REG_DWORD: comptime_int = 4;
    pub const REG_DWORD_BIG_ENDIAN: comptime_int = 5;
    pub const REG_LINK: comptime_int = 6;
    pub const REG_MULTI_SZ: comptime_int = 7;
    pub const REG_RESOURCE_LIST: comptime_int = 8;
    pub const REG_FULL_RESOURCE_DESCRIPTOR: comptime_int = 9;
    pub const REG_RESOURCE_REQUIREMENTS_LIST: comptime_int = 10;
    pub const REG_QWORD: comptime_int = 11;

    pub const KEY_QUERY_VALUE: comptime_int = 0x0001;
    pub const KEY_SET_VALUE: comptime_int = 0x0002;
    pub const KEY_CREATE_SUB_KEY: comptime_int = 0x0004;
    pub const KEY_ENUMERATE_SUB_KEYS: comptime_int = 0x0008;
    pub const KEY_NOTIFY: comptime_int = 0x0010;
    pub const KEY_CREATE_LINK: comptime_int = 0x0020;
    pub const KEY_WOW64_32KEY: comptime_int = 0x0200;
    pub const KEY_WOW64_64KEY: comptime_int = 0x0100;
    pub const KEY_WOW64_RES: comptime_int = 0x0300;

    pub const ALL_PROCESSOR_GROUPS: comptime_int = 0xffff;
    pub const MAX_COMPUTERNAME_LENGTH: comptime_int = 31;

    pub const sizeof_SYSTEM_INFO: comptime_int = 48;
    pub const sizeof_DISPLAY_DEVICEA: comptime_int = 424;
    pub const sizeof_DISPLAY_DEVICEW: comptime_int = 840;
    pub const sizeof_OSVERSIONINFOEXA: comptime_int = 156;
    pub const sizeof_OSVERSIONINFOEXW: comptime_int = 284;
    pub const sizeof_CACHE_DESCRIPTOR: comptime_int = 12;
    pub const sizeof_SYSTEM_LOGICAL_PROCESSOR_INFORMATION: comptime_int = 32;
    pub const sizeof_GROUP_AFFINITY: comptime_int = 16;
    pub const sizeof_NUMA_NODE_RELATIONSHIP: comptime_int = 40;
    pub const sizeof_PROCESSOR_GROUP_INFO: comptime_int = 48;
    pub const sizeof_GROUP_RELATIONSHIP: comptime_int = 72;
    pub const sizeof_CACHE_RELATIONSHIP: comptime_int = 48;
    pub const sizeof_PROCESSOR_RELATIONSHIP: comptime_int = 48;
    pub const sizeof_SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX: comptime_int = 80;
    pub const sizeof_PROCESS_MEMORY_COUNTERS: comptime_int = 72;
    pub const sizeof_MEMORYSTATUSEX: comptime_int = 64;
    pub const sizeof_PROCESSOR_NUMBER: comptime_int = 4;

    pub const SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY: comptime_int = 0x1;
    pub const SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY: comptime_int = 0x2;
    pub const SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE: comptime_int = 0x4;

    pub const TIMERR_BASE: comptime_int = 96;
    pub const TIMERR_NOERROR: comptime_int = 0;
    pub const TIMERR_NOCANDO: comptime_int = 97;
    pub const TIMERR_STRUCT: comptime_int = 129;

    pub const CP_INSTALLED: comptime_int = 0x00000001;
    pub const CP_SUPPORTED: comptime_int = 0x00000002;
    pub const CP_ACP: comptime_int = 0;
    pub const CP_OEMCP: comptime_int = 1;
    pub const CP_MACCP: comptime_int = 2;
    pub const CP_THREAD_ACP: comptime_int = 3;
    pub const CP_SYMBOL: comptime_int = 42;
    pub const CP_UTF7: comptime_int = 65000;
    pub const CP_UTF8: comptime_int = 65001;

    pub const FORMAT_MESSAGE_ALLOCATE_BUFFER: comptime_int = 0x00000100;
    pub const FORMAT_MESSAGE_ARGUMENT_ARRAY: comptime_int = 0x00002000;
    pub const FORMAT_MESSAGE_FROM_SYSTEM: comptime_int = 0x00001000;
    pub const FORMAT_MESSAGE_IGNORE_INSERTS: comptime_int = 0x00000200;
    pub const FORMAT_MESSAGE_FROM_HMODULE: comptime_int = 0x00000800;
    pub const FORMAT_MESSAGE_FROM_STRING: comptime_int = 0x00000400;

    pub const LCMAP_LOWERCASE: comptime_int = 0x00000100;
    pub const LCMAP_UPPERCASE: comptime_int = 0x00000200;

    pub const sizeof_SYSTEMTIME: comptime_int = 16;
    pub const sizeof_TIME_ZONE_INFORMATION: comptime_int = 172;
    pub const sizeof_TIMECAPS: comptime_int = 8;
    pub const sizeof_NLSVERSIONINFO: comptime_int = 12;
};

pub fn validateSysinfoConstants() SysinfoAbiError!void {
    if (sysinfo.DISPLAY_DEVICE_ACTIVE != WindowsSysinfoSpec.DISPLAY_DEVICE_ACTIVE or
        sysinfo.DISPLAY_DEVICE_ATTACHED != WindowsSysinfoSpec.DISPLAY_DEVICE_ATTACHED or
        sysinfo.DISPLAY_DEVICE_PRIMARY_DEVICE != WindowsSysinfoSpec.DISPLAY_DEVICE_PRIMARY_DEVICE)
        return error.InvalidDisplayDeviceFlags;

    if (sysinfo.SM_CXSCREEN != WindowsSysinfoSpec.SM_CXSCREEN or
        sysinfo.SM_CYSCREEN != WindowsSysinfoSpec.SM_CYSCREEN or
        sysinfo.SM_CMONITORS != WindowsSysinfoSpec.SM_CMONITORS)
        return error.InvalidSystemMetrics;

    if (sysinfo.VER_EQUAL != WindowsSysinfoSpec.VER_EQUAL or
        sysinfo.VER_GREATER != WindowsSysinfoSpec.VER_GREATER or
        sysinfo.VER_GREATER_EQUAL != WindowsSysinfoSpec.VER_GREATER_EQUAL or
        sysinfo.VER_LESS != WindowsSysinfoSpec.VER_LESS or
        sysinfo.VER_LESS_EQUAL != WindowsSysinfoSpec.VER_LESS_EQUAL or
        sysinfo.VER_AND != WindowsSysinfoSpec.VER_AND or
        sysinfo.VER_OR != WindowsSysinfoSpec.VER_OR)
        return error.InvalidVersionConstants;

    if (sysinfo._WIN32_WINNT_WINXP != WindowsSysinfoSpec._WIN32_WINNT_WINXP or
        sysinfo._WIN32_WINNT_WS03 != WindowsSysinfoSpec._WIN32_WINNT_WS03 or
        sysinfo._WIN32_WINNT_VISTA != WindowsSysinfoSpec._WIN32_WINNT_VISTA or
        sysinfo._WIN32_WINNT_WIN7 != WindowsSysinfoSpec._WIN32_WINNT_WIN7 or
        sysinfo._WIN32_WINNT_WIN8 != WindowsSysinfoSpec._WIN32_WINNT_WIN8 or
        sysinfo._WIN32_WINNT_WIN81 != WindowsSysinfoSpec._WIN32_WINNT_WIN81 or
        sysinfo._WIN32_WINNT_WIN10 != WindowsSysinfoSpec._WIN32_WINNT_WIN10)
        return error.InvalidVersionConstants;

    if (sysinfo.VER_MINORVERSION != WindowsSysinfoSpec.VER_MINORVERSION or
        sysinfo.VER_MAJORVERSION != WindowsSysinfoSpec.VER_MAJORVERSION or
        sysinfo.VER_BUILDNUMBER != WindowsSysinfoSpec.VER_BUILDNUMBER or
        sysinfo.VER_PLATFORMID != WindowsSysinfoSpec.VER_PLATFORMID or
        sysinfo.VER_SERVICEPACKMINOR != WindowsSysinfoSpec.VER_SERVICEPACKMINOR or
        sysinfo.VER_SERVICEPACKMAJOR != WindowsSysinfoSpec.VER_SERVICEPACKMAJOR)
        return error.InvalidVersionMaskConstants;

    if (sysinfo.REG_NONE != WindowsSysinfoSpec.REG_NONE or
        sysinfo.REG_SZ != WindowsSysinfoSpec.REG_SZ or
        sysinfo.REG_EXPAND_SZ != WindowsSysinfoSpec.REG_EXPAND_SZ or
        sysinfo.REG_BINARY != WindowsSysinfoSpec.REG_BINARY or
        sysinfo.REG_DWORD != WindowsSysinfoSpec.REG_DWORD or
        sysinfo.REG_DWORD_BIG_ENDIAN != WindowsSysinfoSpec.REG_DWORD_BIG_ENDIAN or
        sysinfo.REG_LINK != WindowsSysinfoSpec.REG_LINK or
        sysinfo.REG_MULTI_SZ != WindowsSysinfoSpec.REG_MULTI_SZ or
        sysinfo.REG_RESOURCE_LIST != WindowsSysinfoSpec.REG_RESOURCE_LIST or
        sysinfo.REG_FULL_RESOURCE_DESCRIPTOR != WindowsSysinfoSpec.REG_FULL_RESOURCE_DESCRIPTOR or
        sysinfo.REG_RESOURCE_REQUIREMENTS_LIST != WindowsSysinfoSpec.REG_RESOURCE_REQUIREMENTS_LIST or
        sysinfo.REG_QWORD != WindowsSysinfoSpec.REG_QWORD)
        return error.InvalidRegistryTypeConstants;

    if (sysinfo.KEY_QUERY_VALUE != WindowsSysinfoSpec.KEY_QUERY_VALUE or
        sysinfo.KEY_SET_VALUE != WindowsSysinfoSpec.KEY_SET_VALUE or
        sysinfo.KEY_CREATE_SUB_KEY != WindowsSysinfoSpec.KEY_CREATE_SUB_KEY or
        sysinfo.KEY_ENUMERATE_SUB_KEYS != WindowsSysinfoSpec.KEY_ENUMERATE_SUB_KEYS or
        sysinfo.KEY_NOTIFY != WindowsSysinfoSpec.KEY_NOTIFY or
        sysinfo.KEY_CREATE_LINK != WindowsSysinfoSpec.KEY_CREATE_LINK or
        sysinfo.KEY_WOW64_32KEY != WindowsSysinfoSpec.KEY_WOW64_32KEY or
        sysinfo.KEY_WOW64_64KEY != WindowsSysinfoSpec.KEY_WOW64_64KEY or
        sysinfo.KEY_WOW64_RES != WindowsSysinfoSpec.KEY_WOW64_RES)
        return error.InvalidRegistryAccessConstants;

    if (@intFromEnum(sysinfo.RelationProcessorCore) != 0 or
        @intFromEnum(sysinfo.RelationNumaNode) != 1 or
        @intFromEnum(sysinfo.RelationCache) != 2 or
        @intFromEnum(sysinfo.RelationProcessorPackage) != 3 or
        @intFromEnum(sysinfo.RelationGroup) != 4 or
        @intFromEnum(sysinfo.RelationAll) != 0xffff)
        return error.InvalidLogicalProcessorRelationship;

    if (@intFromEnum(sysinfo.CacheUnified) != 0 or
        @intFromEnum(sysinfo.CacheInstruction) != 1 or
        @intFromEnum(sysinfo.CacheData) != 2 or
        @intFromEnum(sysinfo.CacheTrace) != 3)
        return error.InvalidProcessorCacheType;

    if (sysinfo.ALL_PROCESSOR_GROUPS != WindowsSysinfoSpec.ALL_PROCESSOR_GROUPS)
        return error.InvalidAllProcessorGroupsConstant;

    if (sysinfo.MAX_COMPUTERNAME_LENGTH != WindowsSysinfoSpec.MAX_COMPUTERNAME_LENGTH)
        return error.InvalidComputerNameLength;

    if (sysinfo.SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY != WindowsSysinfoSpec.SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY or
        sysinfo.SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY != WindowsSysinfoSpec.SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY or
        sysinfo.SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE != WindowsSysinfoSpec.SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE)
        return error.InvalidSynchronizationBarrierFlags;

    if (misc.TIMERR_BASE != WindowsSysinfoSpec.TIMERR_BASE or
        misc.TIMERR_NOERROR != WindowsSysinfoSpec.TIMERR_NOERROR or
        misc.TIMERR_NOCANDO != WindowsSysinfoSpec.TIMERR_NOCANDO or
        misc.TIMERR_STRUCT != WindowsSysinfoSpec.TIMERR_STRUCT)
        return error.InvalidMiscTimerConstants;

    if (misc.CP_INSTALLED != WindowsSysinfoSpec.CP_INSTALLED or
        misc.CP_SUPPORTED != WindowsSysinfoSpec.CP_SUPPORTED or
        misc.CP_ACP != WindowsSysinfoSpec.CP_ACP or
        misc.CP_OEMCP != WindowsSysinfoSpec.CP_OEMCP or
        misc.CP_MACCP != WindowsSysinfoSpec.CP_MACCP or
        misc.CP_THREAD_ACP != WindowsSysinfoSpec.CP_THREAD_ACP or
        misc.CP_SYMBOL != WindowsSysinfoSpec.CP_SYMBOL or
        misc.CP_UTF7 != WindowsSysinfoSpec.CP_UTF7 or
        misc.CP_UTF8 != WindowsSysinfoSpec.CP_UTF8)
        return error.InvalidMiscCodePageConstants;

    if (misc.FORMAT_MESSAGE_ALLOCATE_BUFFER != WindowsSysinfoSpec.FORMAT_MESSAGE_ALLOCATE_BUFFER or
        misc.FORMAT_MESSAGE_ARGUMENT_ARRAY != WindowsSysinfoSpec.FORMAT_MESSAGE_ARGUMENT_ARRAY or
        misc.FORMAT_MESSAGE_FROM_SYSTEM != WindowsSysinfoSpec.FORMAT_MESSAGE_FROM_SYSTEM or
        misc.FORMAT_MESSAGE_IGNORE_INSERTS != WindowsSysinfoSpec.FORMAT_MESSAGE_IGNORE_INSERTS or
        misc.FORMAT_MESSAGE_FROM_HMODULE != WindowsSysinfoSpec.FORMAT_MESSAGE_FROM_HMODULE or
        misc.FORMAT_MESSAGE_FROM_STRING != WindowsSysinfoSpec.FORMAT_MESSAGE_FROM_STRING)
        return error.InvalidMiscFormatMessageConstants;

    if (misc.LCMAP_LOWERCASE != WindowsSysinfoSpec.LCMAP_LOWERCASE or
        misc.LCMAP_UPPERCASE != WindowsSysinfoSpec.LCMAP_UPPERCASE)
        return error.InvalidMiscLocaleConstants;
}

pub fn validateSysinfoStructSizes() SysinfoAbiError!void {
    if (@sizeOf(sysinfo.SYSTEM_INFO) != WindowsSysinfoSpec.sizeof_SYSTEM_INFO)
        return error.InvalidSystemInfoSize;
    if (@sizeOf(sysinfo.DISPLAY_DEVICEA) != WindowsSysinfoSpec.sizeof_DISPLAY_DEVICEA)
        return error.InvalidDisplayDeviceASize;
    if (@sizeOf(sysinfo.DISPLAY_DEVICEW) != WindowsSysinfoSpec.sizeof_DISPLAY_DEVICEW)
        return error.InvalidDisplayDeviceWSize;
    if (@sizeOf(sysinfo.OSVERSIONINFOEXA) != WindowsSysinfoSpec.sizeof_OSVERSIONINFOEXA)
        return error.InvalidOsVersionInfoExASize;
    if (@sizeOf(sysinfo.OSVERSIONINFOEXW) != WindowsSysinfoSpec.sizeof_OSVERSIONINFOEXW)
        return error.InvalidOsVersionInfoExWSize;
    if (@sizeOf(sysinfo.CACHE_DESCRIPTOR) != WindowsSysinfoSpec.sizeof_CACHE_DESCRIPTOR)
        return error.InvalidCacheDescriptorSize;
    if (@sizeOf(sysinfo.SYSTEM_LOGICAL_PROCESSOR_INFORMATION) != WindowsSysinfoSpec.sizeof_SYSTEM_LOGICAL_PROCESSOR_INFORMATION)
        return error.InvalidSystemLogicalProcessorInfoSize;
    if (@sizeOf(sysinfo.GROUP_AFFINITY) != WindowsSysinfoSpec.sizeof_GROUP_AFFINITY)
        return error.InvalidGroupAffinitySize;
    if (@sizeOf(sysinfo.NUMA_NODE_RELATIONSHIP) != WindowsSysinfoSpec.sizeof_NUMA_NODE_RELATIONSHIP)
        return error.InvalidNumaNodeRelationshipSize;
    if (@sizeOf(sysinfo.PROCESSOR_GROUP_INFO) != WindowsSysinfoSpec.sizeof_PROCESSOR_GROUP_INFO)
        return error.InvalidProcessorGroupInfoSize;
    if (@sizeOf(sysinfo.GROUP_RELATIONSHIP) != WindowsSysinfoSpec.sizeof_GROUP_RELATIONSHIP)
        return error.InvalidGroupRelationshipSize;
    if (@sizeOf(sysinfo.CACHE_RELATIONSHIP) != WindowsSysinfoSpec.sizeof_CACHE_RELATIONSHIP)
        return error.InvalidCacheRelationshipSize;
    if (@sizeOf(sysinfo.PROCESSOR_RELATIONSHIP) != WindowsSysinfoSpec.sizeof_PROCESSOR_RELATIONSHIP)
        return error.InvalidProcessorRelationshipSize;
    if (@sizeOf(sysinfo.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX) != WindowsSysinfoSpec.sizeof_SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX)
        return error.InvalidSystemLogicalProcessorInfoExSize;
    if (@sizeOf(sysinfo.PROCESS_MEMORY_COUNTERS) != WindowsSysinfoSpec.sizeof_PROCESS_MEMORY_COUNTERS)
        return error.InvalidProcessMemoryCountersSize;
    if (@sizeOf(sysinfo.MEMORYSTATUSEX) != WindowsSysinfoSpec.sizeof_MEMORYSTATUSEX)
        return error.InvalidMemoryStatusExSize;
    if (@sizeOf(sysinfo.PROCESSOR_NUMBER) != WindowsSysinfoSpec.sizeof_PROCESSOR_NUMBER)
        return error.InvalidProcessorNumberSize;

    if (@sizeOf(misc.SYSTEMTIME) != WindowsSysinfoSpec.sizeof_SYSTEMTIME)
        return error.InvalidMiscSystemTimeSize;
    if (@sizeOf(misc.TIME_ZONE_INFORMATION) != WindowsSysinfoSpec.sizeof_TIME_ZONE_INFORMATION)
        return error.InvalidMiscTimeZoneInformationSize;
    if (@sizeOf(misc.TIMECAPS) != WindowsSysinfoSpec.sizeof_TIMECAPS)
        return error.InvalidMiscTimeCapsSize;
    if (@sizeOf(misc.NLSVERSIONINFO) != WindowsSysinfoSpec.sizeof_NLSVERSIONINFO)
        return error.InvalidMiscNlsVersionInfoSize;
}

pub fn validateAll() SysinfoAbiError!void {
    try validateSysinfoConstants();
    try validateSysinfoStructSizes();
}

fn reportSysinfoSizes() void {
    std.debug.print(
        \\================================================================================
        \\ Sysinfo Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "SYSTEM_INFO", .spec = WindowsSysinfoSpec.sizeof_SYSTEM_INFO, .zig = @sizeOf(sysinfo.SYSTEM_INFO) },
        .{ .name = "DISPLAY_DEVICEA", .spec = WindowsSysinfoSpec.sizeof_DISPLAY_DEVICEA, .zig = @sizeOf(sysinfo.DISPLAY_DEVICEA) },
        .{ .name = "DISPLAY_DEVICEW", .spec = WindowsSysinfoSpec.sizeof_DISPLAY_DEVICEW, .zig = @sizeOf(sysinfo.DISPLAY_DEVICEW) },
        .{ .name = "OSVERSIONINFOEXA", .spec = WindowsSysinfoSpec.sizeof_OSVERSIONINFOEXA, .zig = @sizeOf(sysinfo.OSVERSIONINFOEXA) },
        .{ .name = "OSVERSIONINFOEXW", .spec = WindowsSysinfoSpec.sizeof_OSVERSIONINFOEXW, .zig = @sizeOf(sysinfo.OSVERSIONINFOEXW) },
        .{ .name = "CACHE_DESCRIPTOR", .spec = WindowsSysinfoSpec.sizeof_CACHE_DESCRIPTOR, .zig = @sizeOf(sysinfo.CACHE_DESCRIPTOR) },
        .{ .name = "SYSTEM_LOGICAL_PROCESSOR_INFORMATION", .spec = WindowsSysinfoSpec.sizeof_SYSTEM_LOGICAL_PROCESSOR_INFORMATION, .zig = @sizeOf(sysinfo.SYSTEM_LOGICAL_PROCESSOR_INFORMATION) },
        .{ .name = "GROUP_AFFINITY", .spec = WindowsSysinfoSpec.sizeof_GROUP_AFFINITY, .zig = @sizeOf(sysinfo.GROUP_AFFINITY) },
        .{ .name = "NUMA_NODE_RELATIONSHIP", .spec = WindowsSysinfoSpec.sizeof_NUMA_NODE_RELATIONSHIP, .zig = @sizeOf(sysinfo.NUMA_NODE_RELATIONSHIP) },
        .{ .name = "PROCESSOR_GROUP_INFO", .spec = WindowsSysinfoSpec.sizeof_PROCESSOR_GROUP_INFO, .zig = @sizeOf(sysinfo.PROCESSOR_GROUP_INFO) },
        .{ .name = "GROUP_RELATIONSHIP", .spec = WindowsSysinfoSpec.sizeof_GROUP_RELATIONSHIP, .zig = @sizeOf(sysinfo.GROUP_RELATIONSHIP) },
        .{ .name = "CACHE_RELATIONSHIP", .spec = WindowsSysinfoSpec.sizeof_CACHE_RELATIONSHIP, .zig = @sizeOf(sysinfo.CACHE_RELATIONSHIP) },
        .{ .name = "PROCESSOR_RELATIONSHIP", .spec = WindowsSysinfoSpec.sizeof_PROCESSOR_RELATIONSHIP, .zig = @sizeOf(sysinfo.PROCESSOR_RELATIONSHIP) },
        .{ .name = "SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX", .spec = WindowsSysinfoSpec.sizeof_SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX, .zig = @sizeOf(sysinfo.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX) },
        .{ .name = "PROCESS_MEMORY_COUNTERS", .spec = WindowsSysinfoSpec.sizeof_PROCESS_MEMORY_COUNTERS, .zig = @sizeOf(sysinfo.PROCESS_MEMORY_COUNTERS) },
        .{ .name = "MEMORYSTATUSEX", .spec = WindowsSysinfoSpec.sizeof_MEMORYSTATUSEX, .zig = @sizeOf(sysinfo.MEMORYSTATUSEX) },
        .{ .name = "PROCESSOR_NUMBER", .spec = WindowsSysinfoSpec.sizeof_PROCESSOR_NUMBER, .zig = @sizeOf(sysinfo.PROCESSOR_NUMBER) },
    };
    for (table) |entry| {
        std.debug.print(
            \\ {s:<38} | {d:<10} | {d:<14}
        , .{ entry.name, entry.spec, entry.zig });
    }
    std.debug.print(
        \\================================================================================
        \\
    , .{});
}

pub export fn rosette_print_sysinfo_report() void {
    reportSysinfoSizes();
}

pub export fn rosette_validate_sysinfo() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidDisplayDeviceFlags => 1,
        error.InvalidSystemMetrics => 2,
        error.InvalidVersionConstants => 3,
        error.InvalidVersionMaskConstants => 4,
        error.InvalidRegistryTypeConstants => 5,
        error.InvalidRegistryAccessConstants => 6,
        error.InvalidLogicalProcessorRelationship => 7,
        error.InvalidProcessorCacheType => 8,
        error.InvalidAllProcessorGroupsConstant => 9,
        error.InvalidComputerNameLength => 10,
        error.InvalidSystemInfoSize => 11,
        error.InvalidDisplayDeviceASize => 12,
        error.InvalidDisplayDeviceWSize => 13,
        error.InvalidOsVersionInfoExASize => 14,
        error.InvalidOsVersionInfoExWSize => 15,
        error.InvalidCacheDescriptorSize => 16,
        error.InvalidSystemLogicalProcessorInfoSize => 17,
        error.InvalidGroupAffinitySize => 18,
        error.InvalidNumaNodeRelationshipSize => 19,
        error.InvalidProcessorGroupInfoSize => 20,
        error.InvalidGroupRelationshipSize => 21,
        error.InvalidCacheRelationshipSize => 22,
        error.InvalidProcessorRelationshipSize => 23,
        error.InvalidSystemLogicalProcessorInfoExSize => 24,
        error.InvalidProcessMemoryCountersSize => 25,
        error.InvalidMemoryStatusExSize => 26,
        error.InvalidProcessorNumberSize => 27,
        error.InvalidSynchronizationBarrierFlags => 28,
        error.InvalidMiscTimerConstants => 29,
        error.InvalidMiscCodePageConstants => 30,
        error.InvalidMiscFormatMessageConstants => 31,
        error.InvalidMiscLocaleConstants => 32,
        error.InvalidMiscSystemTimeSize => 33,
        error.InvalidMiscTimeZoneInformationSize => 34,
        error.InvalidMiscTimeCapsSize => 35,
        error.InvalidMiscNlsVersionInfoSize => 36,
    };
    return 0;
}

pub export fn rosette_sysinfo_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidDisplayDeviceFlags",
        2 => "InvalidSystemMetrics",
        3 => "InvalidVersionConstants",
        4 => "InvalidVersionMaskConstants",
        5 => "InvalidRegistryTypeConstants",
        6 => "InvalidRegistryAccessConstants",
        7 => "InvalidLogicalProcessorRelationship",
        8 => "InvalidProcessorCacheType",
        9 => "InvalidAllProcessorGroupsConstant",
        10 => "InvalidComputerNameLength",
        11 => "InvalidSystemInfoSize",
        12 => "InvalidDisplayDeviceASize",
        13 => "InvalidDisplayDeviceWSize",
        14 => "InvalidOsVersionInfoExASize",
        15 => "InvalidOsVersionInfoExWSize",
        16 => "InvalidCacheDescriptorSize",
        17 => "InvalidSystemLogicalProcessorInfoSize",
        18 => "InvalidGroupAffinitySize",
        19 => "InvalidNumaNodeRelationshipSize",
        20 => "InvalidProcessorGroupInfoSize",
        21 => "InvalidGroupRelationshipSize",
        22 => "InvalidCacheRelationshipSize",
        23 => "InvalidProcessorRelationshipSize",
        24 => "InvalidSystemLogicalProcessorInfoExSize",
        25 => "InvalidProcessMemoryCountersSize",
        26 => "InvalidMemoryStatusExSize",
        27 => "InvalidProcessorNumberSize",
        28 => "InvalidSynchronizationBarrierFlags",
        29 => "InvalidMiscTimerConstants",
        30 => "InvalidMiscCodePageConstants",
        31 => "InvalidMiscFormatMessageConstants",
        32 => "InvalidMiscLocaleConstants",
        33 => "InvalidMiscSystemTimeSize",
        34 => "InvalidMiscTimeZoneInformationSize",
        35 => "InvalidMiscTimeCapsSize",
        36 => "InvalidMiscNlsVersionInfoSize",
        else => "UnknownSysinfoFailure",
    };
}

test "sysinfo.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
