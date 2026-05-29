const std = @import("std");

const win32_all = @import("win32_all");
const file = win32_all;

pub const FileAbiError = error{
    InvalidFileShareConstants,
    InvalidGenericAccessConstants,
    InvalidStandardAccessConstants,
    InvalidFileAccessConstants,
    InvalidCreateDispositionConstants,
    InvalidFileAttributeConstants,
    InvalidFileSeekConstants,
    InvalidFileTypeConstants,
    InvalidMoveFileConstants,
    InvalidPageProtectionConstants,
    InvalidFileMapConstants,
    InvalidFileFlagConstants,
    InvalidFileNotifyChangeConstants,
    InvalidFileActionConstants,
    InvalidStatusConstants,
    InvalidUsnReasonConstants,
    InvalidCtlCodeConstants,
    InvalidFindDataASize,
    InvalidFindDataWSize,
    InvalidFileId128Size,
    InvalidFileIdDescriptorSize,
    InvalidFileBasicInfoSize,
    InvalidFileNameInfoSize,
    InvalidFileIdInfoSize,
    InvalidFileNotifyInformationSize,
    InvalidFileAttributeDataSize,
    InvalidUsnJournalDataV0Size,
    InvalidUsnRecordV2Size,
    InvalidUsnRecordV3Size,
};

pub const WindowsFileSpec = struct {
    pub const FILE_SHARE_DELETE: comptime_int = 0x00000004;
    pub const FILE_SHARE_READ: comptime_int = 0x00000001;
    pub const FILE_SHARE_WRITE: comptime_int = 0x00000002;

    pub const GENERIC_ALL: comptime_int = 0x10000000;
    pub const GENERIC_EXECUTE: comptime_int = 0x20000000;
    pub const GENERIC_READ: comptime_int = 0x80000000;
    pub const GENERIC_WRITE: comptime_int = 0x40000000;

    pub const DELETE: comptime_int = 0x00010000;
    pub const READ_CONTROL: comptime_int = 0x00020000;
    pub const SYNCHRONIZE: comptime_int = 0x00100000;

    pub const FILE_READ_DATA: comptime_int = 0x0001;
    pub const FILE_WRITE_DATA: comptime_int = 0x0002;
    pub const FILE_APPEND_DATA: comptime_int = 0x0004;
    pub const FILE_EXECUTE: comptime_int = 0x0020;
    pub const FILE_READ_ATTRIBUTES: comptime_int = 0x0080;
    pub const FILE_WRITE_ATTRIBUTES: comptime_int = 0x0100;

    pub const CREATE_ALWAYS: comptime_int = 2;
    pub const CREATE_NEW: comptime_int = 1;
    pub const OPEN_ALWAYS: comptime_int = 4;
    pub const OPEN_EXISTING: comptime_int = 3;
    pub const TRUNCATE_EXISTING: comptime_int = 5;

    pub const INVALID_FILE_ATTRIBUTES: comptime_int = 0xffffffff;
    pub const FILE_ATTRIBUTE_HIDDEN: comptime_int = 0x2;
    pub const FILE_ATTRIBUTE_NORMAL: comptime_int = 0x80;
    pub const FILE_ATTRIBUTE_DIRECTORY: comptime_int = 0x10;

    pub const FILE_BEGIN: comptime_int = 0;
    pub const FILE_CURRENT: comptime_int = 1;
    pub const FILE_END: comptime_int = 2;

    pub const FILE_TYPE_UNKNOWN: comptime_int = 0x0000;
    pub const FILE_TYPE_DISK: comptime_int = 0x0001;

    pub const MOVEFILE_COPY_ALLOWED: comptime_int = 0x2;
    pub const MOVEFILE_REPLACE_EXISTING: comptime_int = 0x1;

    pub const PAGE_READONLY: comptime_int = 0x02;
    pub const PAGE_READWRITE: comptime_int = 0x04;
    pub const PAGE_EXECUTE_READ: comptime_int = 0x20;
    pub const PAGE_EXECUTE_READWRITE: comptime_int = 0x40;

    pub const FILE_MAP_COPY: comptime_int = 0x0001;
    pub const FILE_MAP_WRITE: comptime_int = 0x0002;
    pub const FILE_MAP_READ: comptime_int = 0x0004;

    pub const FILE_FLAG_OVERLAPPED: comptime_int = 0x40000000;
    pub const FILE_FLAG_NO_BUFFERING: comptime_int = 0x20000000;

    pub const FILE_NOTIFY_CHANGE_FILE_NAME: comptime_int = 0x00000001;
    pub const FILE_NOTIFY_CHANGE_DIR_NAME: comptime_int = 0x00000002;

    pub const FILE_ACTION_ADDED: comptime_int = 0x00000001;
    pub const FILE_ACTION_REMOVED: comptime_int = 0x00000002;
    pub const FILE_ACTION_MODIFIED: comptime_int = 0x00000003;

    pub const STATUS_WAIT_0: comptime_int = 0x00000000;
    pub const STATUS_TIMEOUT: comptime_int = 0x00000102;
    pub const STATUS_PENDING: comptime_int = 0x00000103;

    pub const USN_REASON_DATA_OVERWRITE: comptime_int = 0x00000001;
    pub const USN_REASON_FILE_CREATE: comptime_int = 0x00000100;
    pub const USN_REASON_CLOSE: comptime_int = 0x80000000;

    pub const FILE_DEVICE_FILE_SYSTEM: comptime_int = 0x00000009;
    pub const METHOD_BUFFERED: comptime_int = 0;
    pub const METHOD_NEITHER: comptime_int = 3;
    pub const FILE_ANY_ACCESS: comptime_int = 0;

    pub const sizeof_WIN32_FIND_DATAA: comptime_int = 592;
    pub const sizeof_WIN32_FIND_DATAW: comptime_int = 592;
    pub const sizeof_FILE_ID_128: comptime_int = 16;
    pub const sizeof_FILE_ID_DESCRIPTOR: comptime_int = 24;
    pub const sizeof_FILE_BASIC_INFO: comptime_int = 40;
    pub const sizeof_FILE_NAME_INFO: comptime_int = 6;
    pub const sizeof_FILE_ID_INFO: comptime_int = 24;
    pub const sizeof_FILE_NOTIFY_INFORMATION: comptime_int = 16;
    pub const sizeof_WIN32_FILE_ATTRIBUTE_DATA: comptime_int = 36;
    pub const sizeof_USN_JOURNAL_DATA_V0: comptime_int = 48;
    pub const sizeof_USN_RECORD_V2: comptime_int = 64;
    pub const sizeof_USN_RECORD_V3: comptime_int = 80;
};

pub fn validateFileConstants() FileAbiError!void {
    if (file.FILE_SHARE_DELETE != WindowsFileSpec.FILE_SHARE_DELETE or
        file.FILE_SHARE_READ != WindowsFileSpec.FILE_SHARE_READ or
        file.FILE_SHARE_WRITE != WindowsFileSpec.FILE_SHARE_WRITE)
        return error.InvalidFileShareConstants;

    if (file.GENERIC_ALL != WindowsFileSpec.GENERIC_ALL or
        file.GENERIC_EXECUTE != WindowsFileSpec.GENERIC_EXECUTE or
        file.GENERIC_READ != WindowsFileSpec.GENERIC_READ or
        file.GENERIC_WRITE != WindowsFileSpec.GENERIC_WRITE)
        return error.InvalidGenericAccessConstants;

    if (file.DELETE != WindowsFileSpec.DELETE or
        file.READ_CONTROL != WindowsFileSpec.READ_CONTROL or
        file.SYNCHRONIZE != WindowsFileSpec.SYNCHRONIZE)
        return error.InvalidStandardAccessConstants;

    if (file.FILE_READ_DATA != WindowsFileSpec.FILE_READ_DATA or
        file.FILE_WRITE_DATA != WindowsFileSpec.FILE_WRITE_DATA or
        file.FILE_APPEND_DATA != WindowsFileSpec.FILE_APPEND_DATA or
        file.FILE_EXECUTE != WindowsFileSpec.FILE_EXECUTE or
        file.FILE_READ_ATTRIBUTES != WindowsFileSpec.FILE_READ_ATTRIBUTES or
        file.FILE_WRITE_ATTRIBUTES != WindowsFileSpec.FILE_WRITE_ATTRIBUTES)
        return error.InvalidFileAccessConstants;

    if (file.CREATE_ALWAYS != WindowsFileSpec.CREATE_ALWAYS or
        file.CREATE_NEW != WindowsFileSpec.CREATE_NEW or
        file.OPEN_ALWAYS != WindowsFileSpec.OPEN_ALWAYS or
        file.OPEN_EXISTING != WindowsFileSpec.OPEN_EXISTING or
        file.TRUNCATE_EXISTING != WindowsFileSpec.TRUNCATE_EXISTING)
        return error.InvalidCreateDispositionConstants;

    if (file.INVALID_FILE_ATTRIBUTES != WindowsFileSpec.INVALID_FILE_ATTRIBUTES or
        file.FILE_ATTRIBUTE_HIDDEN != WindowsFileSpec.FILE_ATTRIBUTE_HIDDEN or
        file.FILE_ATTRIBUTE_NORMAL != WindowsFileSpec.FILE_ATTRIBUTE_NORMAL or
        file.FILE_ATTRIBUTE_DIRECTORY != WindowsFileSpec.FILE_ATTRIBUTE_DIRECTORY)
        return error.InvalidFileAttributeConstants;

    if (file.FILE_BEGIN != WindowsFileSpec.FILE_BEGIN or
        file.FILE_CURRENT != WindowsFileSpec.FILE_CURRENT or
        file.FILE_END != WindowsFileSpec.FILE_END)
        return error.InvalidFileSeekConstants;

    if (file.FILE_TYPE_UNKNOWN != WindowsFileSpec.FILE_TYPE_UNKNOWN or
        file.FILE_TYPE_DISK != WindowsFileSpec.FILE_TYPE_DISK)
        return error.InvalidFileTypeConstants;

    if (file.MOVEFILE_COPY_ALLOWED != WindowsFileSpec.MOVEFILE_COPY_ALLOWED or
        file.MOVEFILE_REPLACE_EXISTING != WindowsFileSpec.MOVEFILE_REPLACE_EXISTING)
        return error.InvalidMoveFileConstants;

    if (file.PAGE_READONLY != WindowsFileSpec.PAGE_READONLY or
        file.PAGE_READWRITE != WindowsFileSpec.PAGE_READWRITE or
        file.PAGE_EXECUTE_READ != WindowsFileSpec.PAGE_EXECUTE_READ or
        file.PAGE_EXECUTE_READWRITE != WindowsFileSpec.PAGE_EXECUTE_READWRITE)
        return error.InvalidPageProtectionConstants;

    if (file.FILE_MAP_COPY != WindowsFileSpec.FILE_MAP_COPY or
        file.FILE_MAP_WRITE != WindowsFileSpec.FILE_MAP_WRITE or
        file.FILE_MAP_READ != WindowsFileSpec.FILE_MAP_READ)
        return error.InvalidFileMapConstants;

    if (file.FILE_FLAG_OVERLAPPED != WindowsFileSpec.FILE_FLAG_OVERLAPPED or
        file.FILE_FLAG_NO_BUFFERING != WindowsFileSpec.FILE_FLAG_NO_BUFFERING)
        return error.InvalidFileFlagConstants;

    if (file.FILE_NOTIFY_CHANGE_FILE_NAME != WindowsFileSpec.FILE_NOTIFY_CHANGE_FILE_NAME or
        file.FILE_NOTIFY_CHANGE_DIR_NAME != WindowsFileSpec.FILE_NOTIFY_CHANGE_DIR_NAME)
        return error.InvalidFileNotifyChangeConstants;

    if (file.FILE_ACTION_ADDED != WindowsFileSpec.FILE_ACTION_ADDED or
        file.FILE_ACTION_REMOVED != WindowsFileSpec.FILE_ACTION_REMOVED or
        file.FILE_ACTION_MODIFIED != WindowsFileSpec.FILE_ACTION_MODIFIED)
        return error.InvalidFileActionConstants;

    if (file.STATUS_WAIT_0 != WindowsFileSpec.STATUS_WAIT_0 or
        file.STATUS_TIMEOUT != WindowsFileSpec.STATUS_TIMEOUT or
        file.STATUS_PENDING != WindowsFileSpec.STATUS_PENDING)
        return error.InvalidStatusConstants;

    if (file.USN_REASON_DATA_OVERWRITE != WindowsFileSpec.USN_REASON_DATA_OVERWRITE or
        file.USN_REASON_FILE_CREATE != WindowsFileSpec.USN_REASON_FILE_CREATE or
        file.USN_REASON_CLOSE != WindowsFileSpec.USN_REASON_CLOSE)
        return error.InvalidUsnReasonConstants;

    if (file.FILE_DEVICE_FILE_SYSTEM != WindowsFileSpec.FILE_DEVICE_FILE_SYSTEM or
        file.METHOD_BUFFERED != WindowsFileSpec.METHOD_BUFFERED or
        file.METHOD_NEITHER != WindowsFileSpec.METHOD_NEITHER or
        file.FILE_ANY_ACCESS != WindowsFileSpec.FILE_ANY_ACCESS)
        return error.InvalidCtlCodeConstants;
}

pub fn validateFileStructSizes() FileAbiError!void {
    if (@sizeOf(file.WIN32_FIND_DATAA) != WindowsFileSpec.sizeof_WIN32_FIND_DATAA)
        return error.InvalidFindDataASize;
    if (@sizeOf(file.WIN32_FIND_DATAW) != WindowsFileSpec.sizeof_WIN32_FIND_DATAW)
        return error.InvalidFindDataWSize;
    if (@sizeOf(file.FILE_ID_128) != WindowsFileSpec.sizeof_FILE_ID_128)
        return error.InvalidFileId128Size;
    if (@sizeOf(file.FILE_ID_DESCRIPTOR) != WindowsFileSpec.sizeof_FILE_ID_DESCRIPTOR)
        return error.InvalidFileIdDescriptorSize;
    if (@sizeOf(file.FILE_BASIC_INFO) != WindowsFileSpec.sizeof_FILE_BASIC_INFO)
        return error.InvalidFileBasicInfoSize;
    if (@sizeOf(file.FILE_NAME_INFO) != WindowsFileSpec.sizeof_FILE_NAME_INFO)
        return error.InvalidFileNameInfoSize;
    if (@sizeOf(file.FILE_ID_INFO) != WindowsFileSpec.sizeof_FILE_ID_INFO)
        return error.InvalidFileIdInfoSize;
    if (@sizeOf(file.FILE_NOTIFY_INFORMATION) != WindowsFileSpec.sizeof_FILE_NOTIFY_INFORMATION)
        return error.InvalidFileNotifyInformationSize;
    if (@sizeOf(file.WIN32_FILE_ATTRIBUTE_DATA) != WindowsFileSpec.sizeof_WIN32_FILE_ATTRIBUTE_DATA)
        return error.InvalidFileAttributeDataSize;
    if (@sizeOf(file.USN_JOURNAL_DATA_V0) != WindowsFileSpec.sizeof_USN_JOURNAL_DATA_V0)
        return error.InvalidUsnJournalDataV0Size;
    if (@sizeOf(file.USN_RECORD_V2) != WindowsFileSpec.sizeof_USN_RECORD_V2)
        return error.InvalidUsnRecordV2Size;
    if (@sizeOf(file.USN_RECORD_V3) != WindowsFileSpec.sizeof_USN_RECORD_V3)
        return error.InvalidUsnRecordV3Size;
}

pub fn validateAll() FileAbiError!void {
    try validateFileConstants();
    try validateFileStructSizes();
}

fn reportFileSizes() void {
    std.debug.print(
        \\================================================================================
        \\ File Struct Size Table (Windows spec vs Zig translated)
        \\================================================================================
        \\ Name                                   | Win32 Spec | Zig Translated
        \\----------------------------------------+------------+----------------
    , .{});
    const table = [_]struct { name: []const u8, spec: usize, zig: usize }{
        .{ .name = "WIN32_FIND_DATAA", .spec = WindowsFileSpec.sizeof_WIN32_FIND_DATAA, .zig = @sizeOf(file.WIN32_FIND_DATAA) },
        .{ .name = "WIN32_FIND_DATAW", .spec = WindowsFileSpec.sizeof_WIN32_FIND_DATAW, .zig = @sizeOf(file.WIN32_FIND_DATAW) },
        .{ .name = "FILE_ID_128", .spec = WindowsFileSpec.sizeof_FILE_ID_128, .zig = @sizeOf(file.FILE_ID_128) },
        .{ .name = "FILE_ID_DESCRIPTOR", .spec = WindowsFileSpec.sizeof_FILE_ID_DESCRIPTOR, .zig = @sizeOf(file.FILE_ID_DESCRIPTOR) },
        .{ .name = "FILE_BASIC_INFO", .spec = WindowsFileSpec.sizeof_FILE_BASIC_INFO, .zig = @sizeOf(file.FILE_BASIC_INFO) },
        .{ .name = "FILE_NAME_INFO", .spec = WindowsFileSpec.sizeof_FILE_NAME_INFO, .zig = @sizeOf(file.FILE_NAME_INFO) },
        .{ .name = "FILE_ID_INFO", .spec = WindowsFileSpec.sizeof_FILE_ID_INFO, .zig = @sizeOf(file.FILE_ID_INFO) },
        .{ .name = "FILE_NOTIFY_INFORMATION", .spec = WindowsFileSpec.sizeof_FILE_NOTIFY_INFORMATION, .zig = @sizeOf(file.FILE_NOTIFY_INFORMATION) },
        .{ .name = "WIN32_FILE_ATTRIBUTE_DATA", .spec = WindowsFileSpec.sizeof_WIN32_FILE_ATTRIBUTE_DATA, .zig = @sizeOf(file.WIN32_FILE_ATTRIBUTE_DATA) },
        .{ .name = "USN_JOURNAL_DATA_V0", .spec = WindowsFileSpec.sizeof_USN_JOURNAL_DATA_V0, .zig = @sizeOf(file.USN_JOURNAL_DATA_V0) },
        .{ .name = "USN_RECORD_V2", .spec = WindowsFileSpec.sizeof_USN_RECORD_V2, .zig = @sizeOf(file.USN_RECORD_V2) },
        .{ .name = "USN_RECORD_V3", .spec = WindowsFileSpec.sizeof_USN_RECORD_V3, .zig = @sizeOf(file.USN_RECORD_V3) },
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

pub export fn rosetta3_print_file_report() void {
    reportFileSizes();
}

pub export fn rosetta3_validate_file() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidFileShareConstants => 1,
        error.InvalidGenericAccessConstants => 2,
        error.InvalidStandardAccessConstants => 3,
        error.InvalidFileAccessConstants => 4,
        error.InvalidCreateDispositionConstants => 5,
        error.InvalidFileAttributeConstants => 6,
        error.InvalidFileSeekConstants => 7,
        error.InvalidFileTypeConstants => 8,
        error.InvalidMoveFileConstants => 9,
        error.InvalidPageProtectionConstants => 10,
        error.InvalidFileMapConstants => 11,
        error.InvalidFileFlagConstants => 12,
        error.InvalidFileNotifyChangeConstants => 13,
        error.InvalidFileActionConstants => 14,
        error.InvalidStatusConstants => 15,
        error.InvalidUsnReasonConstants => 16,
        error.InvalidCtlCodeConstants => 17,
        error.InvalidFindDataASize => 18,
        error.InvalidFindDataWSize => 19,
        error.InvalidFileId128Size => 20,
        error.InvalidFileIdDescriptorSize => 21,
        error.InvalidFileBasicInfoSize => 22,
        error.InvalidFileNameInfoSize => 23,
        error.InvalidFileIdInfoSize => 24,
        error.InvalidFileNotifyInformationSize => 25,
        error.InvalidFileAttributeDataSize => 26,
        error.InvalidUsnJournalDataV0Size => 27,
        error.InvalidUsnRecordV2Size => 28,
        error.InvalidUsnRecordV3Size => 29,
    };
    return 0;
}

pub export fn rosetta3_file_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidFileShareConstants",
        2 => "InvalidGenericAccessConstants",
        3 => "InvalidStandardAccessConstants",
        4 => "InvalidFileAccessConstants",
        5 => "InvalidCreateDispositionConstants",
        6 => "InvalidFileAttributeConstants",
        7 => "InvalidFileSeekConstants",
        8 => "InvalidFileTypeConstants",
        9 => "InvalidMoveFileConstants",
        10 => "InvalidPageProtectionConstants",
        11 => "InvalidFileMapConstants",
        12 => "InvalidFileFlagConstants",
        13 => "InvalidFileNotifyChangeConstants",
        14 => "InvalidFileActionConstants",
        15 => "InvalidStatusConstants",
        16 => "InvalidUsnReasonConstants",
        17 => "InvalidCtlCodeConstants",
        18 => "InvalidFindDataASize",
        19 => "InvalidFindDataWSize",
        20 => "InvalidFileId128Size",
        21 => "InvalidFileIdDescriptorSize",
        22 => "InvalidFileBasicInfoSize",
        23 => "InvalidFileNameInfoSize",
        24 => "InvalidFileIdInfoSize",
        25 => "InvalidFileNotifyInformationSize",
        26 => "InvalidFileAttributeDataSize",
        27 => "InvalidUsnJournalDataV0Size",
        28 => "InvalidUsnRecordV2Size",
        29 => "InvalidUsnRecordV3Size",
        else => "UnknownFileFailure",
    };
}

test "file.h matches pseudo-Windows constants and sizes" {
    try validateAll();
}
