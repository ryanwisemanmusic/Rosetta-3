const std = @import("std");

const win32_mmsystem = @import("win32_mmsystem");

pub const MmsystemAbiError = error{
    InvalidSndFilename,
    InvalidSndAsync,
    InvalidSndAlias,
    InvalidSndNodefault,
    InvalidSndNostop,
    InvalidSndLoop,
    InvalidSndNowait,
    InvalidSndPurge,
    InvalidSndApplication,
    InvalidSndAliasId,
    InvalidSndResource,
    InvalidSndSystem,
    InvalidMmMcNotify,
    InvalidMciOpen,
    InvalidMciClose,
    InvalidMciPlay,
    InvalidMciStop,
    InvalidMciPause,
    InvalidMciSeek,
    InvalidMciSet,
    InvalidMciStatus,
    InvalidMciNotify,
    InvalidMciWait,
    InvalidMciFrom,
    InvalidMciTo,
    InvalidMciOpenType,
    InvalidMciOpenElement,
    InvalidMciPlayAlias,
    InvalidMciSetDoorOpen,
    InvalidMciSetDoorClosed,
    InvalidMciStatusLength,
    InvalidMciStatusPosition,
    InvalidMciStatusMode,
    InvalidMciModeStop,
    InvalidMciModePlay,
    InvalidMciModePause,
    InvalidMciModeOpen,
    InvalidMciAllDevicesId,
    InvalidMmsyserrNoerror,
    InvalidMmresultSize,
};

pub const WindowsMmsystemSpec = struct {
    pub const SND_FILENAME: comptime_int = 0x00020000;
    pub const SND_ASYNC: comptime_int = 0x00000001;
    pub const SND_ALIAS: comptime_int = 0x00010000;
    pub const SND_NODEFAULT: comptime_int = 0x00000002;
    pub const SND_NOSTOP: comptime_int = 0x00000010;
    pub const SND_LOOP: comptime_int = 0x00000008;
    pub const SND_NOWAIT: comptime_int = 0x00002000;
    pub const SND_PURGE: comptime_int = 0x00000040;
    pub const SND_APPLICATION: comptime_int = 0x00000080;
    pub const SND_ALIAS_ID: comptime_int = 0x00110000;
    pub const SND_RESOURCE: comptime_int = 0x00040004;
    pub const SND_SYSTEM: comptime_int = 0x00200000;

    pub const MM_MCINOTIFY: comptime_int = 0x03B9;

    pub const MCI_OPEN: comptime_int = 0x0803;
    pub const MCI_CLOSE: comptime_int = 0x0804;
    pub const MCI_PLAY: comptime_int = 0x0806;
    pub const MCI_STOP: comptime_int = 0x0808;
    pub const MCI_PAUSE: comptime_int = 0x0809;
    pub const MCI_SEEK: comptime_int = 0x080B;
    pub const MCI_SET: comptime_int = 0x080D;
    pub const MCI_STATUS: comptime_int = 0x0814;

    pub const MCI_NOTIFY: comptime_int = 0x00000001;
    pub const MCI_WAIT: comptime_int = 0x00000002;
    pub const MCI_FROM: comptime_int = 0x00000004;
    pub const MCI_TO: comptime_int = 0x00000008;
    pub const MCI_OPEN_TYPE: comptime_int = 0x00002000;
    pub const MCI_OPEN_ELEMENT: comptime_int = 0x00000200;
    pub const MCI_PLAY_ALIAS: comptime_int = 0x00000400;
    pub const MCI_SET_DOOR_OPEN: comptime_int = 0x00000100;
    pub const MCI_SET_DOOR_CLOSED: comptime_int = 0x00000200;
    pub const MCI_STATUS_LENGTH: comptime_int = 0x00000001;
    pub const MCI_STATUS_POSITION: comptime_int = 0x00000002;
    pub const MCI_STATUS_MODE: comptime_int = 0x00000008;
    pub const MCI_MODE_STOP: comptime_int = 0x04CD;
    pub const MCI_MODE_PLAY: comptime_int = 0x04CE;
    pub const MCI_MODE_PAUSE: comptime_int = 0x04CF;
    pub const MCI_MODE_OPEN: comptime_int = 0x04D2;
    pub const MCI_ALL_DEVICES_ID: comptime_int = 0xFFFFFFFF;

    pub const MMSYSERR_NOERROR: comptime_int = 0;

    pub const sizeof_MMRESULT: comptime_int = 4;
};

pub fn validateMmsystemConstants() MmsystemAbiError!void {
    if (win32_mmsystem.SND_FILENAME != WindowsMmsystemSpec.SND_FILENAME) return error.InvalidSndFilename;
    if (win32_mmsystem.SND_ASYNC != WindowsMmsystemSpec.SND_ASYNC) return error.InvalidSndAsync;
    if (win32_mmsystem.SND_ALIAS != WindowsMmsystemSpec.SND_ALIAS) return error.InvalidSndAlias;
    if (win32_mmsystem.SND_NODEFAULT != WindowsMmsystemSpec.SND_NODEFAULT) return error.InvalidSndNodefault;
    if (win32_mmsystem.SND_NOSTOP != WindowsMmsystemSpec.SND_NOSTOP) return error.InvalidSndNostop;
    if (win32_mmsystem.SND_LOOP != WindowsMmsystemSpec.SND_LOOP) return error.InvalidSndLoop;
    if (win32_mmsystem.SND_NOWAIT != WindowsMmsystemSpec.SND_NOWAIT) return error.InvalidSndNowait;
    if (win32_mmsystem.SND_PURGE != WindowsMmsystemSpec.SND_PURGE) return error.InvalidSndPurge;
    if (win32_mmsystem.SND_APPLICATION != WindowsMmsystemSpec.SND_APPLICATION) return error.InvalidSndApplication;
    if (win32_mmsystem.SND_ALIAS_ID != WindowsMmsystemSpec.SND_ALIAS_ID) return error.InvalidSndAliasId;
    if (win32_mmsystem.SND_RESOURCE != WindowsMmsystemSpec.SND_RESOURCE) return error.InvalidSndResource;
    if (win32_mmsystem.SND_SYSTEM != WindowsMmsystemSpec.SND_SYSTEM) return error.InvalidSndSystem;

    if (win32_mmsystem.MM_MCINOTIFY != WindowsMmsystemSpec.MM_MCINOTIFY) return error.InvalidMmMcNotify;

    if (win32_mmsystem.MCI_OPEN != WindowsMmsystemSpec.MCI_OPEN) return error.InvalidMciOpen;
    if (win32_mmsystem.MCI_CLOSE != WindowsMmsystemSpec.MCI_CLOSE) return error.InvalidMciClose;
    if (win32_mmsystem.MCI_PLAY != WindowsMmsystemSpec.MCI_PLAY) return error.InvalidMciPlay;
    if (win32_mmsystem.MCI_STOP != WindowsMmsystemSpec.MCI_STOP) return error.InvalidMciStop;
    if (win32_mmsystem.MCI_PAUSE != WindowsMmsystemSpec.MCI_PAUSE) return error.InvalidMciPause;
    if (win32_mmsystem.MCI_SEEK != WindowsMmsystemSpec.MCI_SEEK) return error.InvalidMciSeek;
    if (win32_mmsystem.MCI_SET != WindowsMmsystemSpec.MCI_SET) return error.InvalidMciSet;
    if (win32_mmsystem.MCI_STATUS != WindowsMmsystemSpec.MCI_STATUS) return error.InvalidMciStatus;
    if (win32_mmsystem.MCI_NOTIFY != WindowsMmsystemSpec.MCI_NOTIFY) return error.InvalidMciNotify;
    if (win32_mmsystem.MCI_WAIT != WindowsMmsystemSpec.MCI_WAIT) return error.InvalidMciWait;
    if (win32_mmsystem.MCI_FROM != WindowsMmsystemSpec.MCI_FROM) return error.InvalidMciFrom;
    if (win32_mmsystem.MCI_TO != WindowsMmsystemSpec.MCI_TO) return error.InvalidMciTo;
    if (win32_mmsystem.MCI_OPEN_TYPE != WindowsMmsystemSpec.MCI_OPEN_TYPE) return error.InvalidMciOpenType;
    if (win32_mmsystem.MCI_OPEN_ELEMENT != WindowsMmsystemSpec.MCI_OPEN_ELEMENT) return error.InvalidMciOpenElement;
    if (win32_mmsystem.MCI_PLAY_ALIAS != WindowsMmsystemSpec.MCI_PLAY_ALIAS) return error.InvalidMciPlayAlias;
    if (win32_mmsystem.MCI_SET_DOOR_OPEN != WindowsMmsystemSpec.MCI_SET_DOOR_OPEN) return error.InvalidMciSetDoorOpen;
    if (win32_mmsystem.MCI_SET_DOOR_CLOSED != WindowsMmsystemSpec.MCI_SET_DOOR_CLOSED) return error.InvalidMciSetDoorClosed;
    if (win32_mmsystem.MCI_STATUS_LENGTH != WindowsMmsystemSpec.MCI_STATUS_LENGTH) return error.InvalidMciStatusLength;
    if (win32_mmsystem.MCI_STATUS_POSITION != WindowsMmsystemSpec.MCI_STATUS_POSITION) return error.InvalidMciStatusPosition;
    if (win32_mmsystem.MCI_STATUS_MODE != WindowsMmsystemSpec.MCI_STATUS_MODE) return error.InvalidMciStatusMode;
    if (win32_mmsystem.MCI_MODE_STOP != WindowsMmsystemSpec.MCI_MODE_STOP) return error.InvalidMciModeStop;
    if (win32_mmsystem.MCI_MODE_PLAY != WindowsMmsystemSpec.MCI_MODE_PLAY) return error.InvalidMciModePlay;
    if (win32_mmsystem.MCI_MODE_PAUSE != WindowsMmsystemSpec.MCI_MODE_PAUSE) return error.InvalidMciModePause;
    if (win32_mmsystem.MCI_MODE_OPEN != WindowsMmsystemSpec.MCI_MODE_OPEN) return error.InvalidMciModeOpen;
    if (win32_mmsystem.MCI_ALL_DEVICES_ID != WindowsMmsystemSpec.MCI_ALL_DEVICES_ID) return error.InvalidMciAllDevicesId;

    if (win32_mmsystem.MMSYSERR_NOERROR != WindowsMmsystemSpec.MMSYSERR_NOERROR) return error.InvalidMmsyserrNoerror;
}

pub fn validateMmsystemTypes() MmsystemAbiError!void {
    if (@sizeOf(win32_mmsystem.MMRESULT) != WindowsMmsystemSpec.sizeof_MMRESULT)
        return error.InvalidMmresultSize;
}

pub fn validateAll() MmsystemAbiError!void {
    try validateMmsystemConstants();
    try validateMmsystemTypes();
}

fn reportMmsystemConstants() void {
    std.debug.print(
        \\==============================================================================
        \\ MMSystem Header Constant Table (Windows spec vs Zig translated)
        \\==============================================================================
        \\ Name                           | Win32 Spec | Zig Translated
        \\-------------------------------+------------+----------------
        \\
    , .{});
    const table = [_]struct { name: []const u8, spec: comptime_int, zig: comptime_int }{
        .{ .name = "SND_FILENAME", .spec = WindowsMmsystemSpec.SND_FILENAME, .zig = win32_mmsystem.SND_FILENAME },
        .{ .name = "SND_ASYNC", .spec = WindowsMmsystemSpec.SND_ASYNC, .zig = win32_mmsystem.SND_ASYNC },
        .{ .name = "SND_ALIAS", .spec = WindowsMmsystemSpec.SND_ALIAS, .zig = win32_mmsystem.SND_ALIAS },
        .{ .name = "SND_NODEFAULT", .spec = WindowsMmsystemSpec.SND_NODEFAULT, .zig = win32_mmsystem.SND_NODEFAULT },
        .{ .name = "SND_NOSTOP", .spec = WindowsMmsystemSpec.SND_NOSTOP, .zig = win32_mmsystem.SND_NOSTOP },
        .{ .name = "SND_LOOP", .spec = WindowsMmsystemSpec.SND_LOOP, .zig = win32_mmsystem.SND_LOOP },
        .{ .name = "SND_NOWAIT", .spec = WindowsMmsystemSpec.SND_NOWAIT, .zig = win32_mmsystem.SND_NOWAIT },
        .{ .name = "SND_PURGE", .spec = WindowsMmsystemSpec.SND_PURGE, .zig = win32_mmsystem.SND_PURGE },
        .{ .name = "SND_APPLICATION", .spec = WindowsMmsystemSpec.SND_APPLICATION, .zig = win32_mmsystem.SND_APPLICATION },
        .{ .name = "SND_ALIAS_ID", .spec = WindowsMmsystemSpec.SND_ALIAS_ID, .zig = win32_mmsystem.SND_ALIAS_ID },
        .{ .name = "SND_RESOURCE", .spec = WindowsMmsystemSpec.SND_RESOURCE, .zig = win32_mmsystem.SND_RESOURCE },
        .{ .name = "SND_SYSTEM", .spec = WindowsMmsystemSpec.SND_SYSTEM, .zig = win32_mmsystem.SND_SYSTEM },
        .{ .name = "MM_MCINOTIFY", .spec = WindowsMmsystemSpec.MM_MCINOTIFY, .zig = win32_mmsystem.MM_MCINOTIFY },
        .{ .name = "MCI_OPEN", .spec = WindowsMmsystemSpec.MCI_OPEN, .zig = win32_mmsystem.MCI_OPEN },
        .{ .name = "MCI_CLOSE", .spec = WindowsMmsystemSpec.MCI_CLOSE, .zig = win32_mmsystem.MCI_CLOSE },
        .{ .name = "MCI_PLAY", .spec = WindowsMmsystemSpec.MCI_PLAY, .zig = win32_mmsystem.MCI_PLAY },
        .{ .name = "MCI_STOP", .spec = WindowsMmsystemSpec.MCI_STOP, .zig = win32_mmsystem.MCI_STOP },
        .{ .name = "MCI_PAUSE", .spec = WindowsMmsystemSpec.MCI_PAUSE, .zig = win32_mmsystem.MCI_PAUSE },
        .{ .name = "MCI_SEEK", .spec = WindowsMmsystemSpec.MCI_SEEK, .zig = win32_mmsystem.MCI_SEEK },
        .{ .name = "MCI_SET", .spec = WindowsMmsystemSpec.MCI_SET, .zig = win32_mmsystem.MCI_SET },
        .{ .name = "MCI_STATUS", .spec = WindowsMmsystemSpec.MCI_STATUS, .zig = win32_mmsystem.MCI_STATUS },
        .{ .name = "MMSYSERR_NOERROR", .spec = WindowsMmsystemSpec.MMSYSERR_NOERROR, .zig = win32_mmsystem.MMSYSERR_NOERROR },
        .{ .name = "sizeof(MMRESULT)", .spec = WindowsMmsystemSpec.sizeof_MMRESULT, .zig = @sizeOf(win32_mmsystem.MMRESULT) },
    };
    inline for (table) |entry| {
        std.debug.print(
            \\ {s:<30} | {d:<10} | {d:<14}
            \\
        , .{ entry.name, entry.spec, entry.zig });
    }
    std.debug.print(
        \\==============================================================================
        \\
    , .{});
}

pub export fn rosette_print_mmsystem_report() void {
    reportMmsystemConstants();
}

pub export fn rosette_validate_mmsystem() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidSndFilename => 1,
        error.InvalidSndAsync => 2,
        error.InvalidSndAlias => 3,
        error.InvalidSndNodefault => 4,
        error.InvalidSndNostop => 5,
        error.InvalidSndLoop => 6,
        error.InvalidSndNowait => 7,
        error.InvalidSndPurge => 8,
        error.InvalidSndApplication => 9,
        error.InvalidSndAliasId => 10,
        error.InvalidSndResource => 11,
        error.InvalidSndSystem => 12,
        error.InvalidMmMcNotify => 13,
        error.InvalidMciOpen => 14,
        error.InvalidMciClose => 15,
        error.InvalidMciPlay => 16,
        error.InvalidMciStop => 17,
        error.InvalidMciPause => 18,
        error.InvalidMciSeek => 19,
        error.InvalidMciSet => 20,
        error.InvalidMciStatus => 21,
        error.InvalidMciNotify => 22,
        error.InvalidMciWait => 23,
        error.InvalidMciFrom => 24,
        error.InvalidMciTo => 25,
        error.InvalidMciOpenType => 26,
        error.InvalidMciOpenElement => 27,
        error.InvalidMciPlayAlias => 28,
        error.InvalidMciSetDoorOpen => 29,
        error.InvalidMciSetDoorClosed => 30,
        error.InvalidMciStatusLength => 31,
        error.InvalidMciStatusPosition => 32,
        error.InvalidMciStatusMode => 33,
        error.InvalidMciModeStop => 34,
        error.InvalidMciModePlay => 35,
        error.InvalidMciModePause => 36,
        error.InvalidMciModeOpen => 37,
        error.InvalidMciAllDevicesId => 38,
        error.InvalidMmsyserrNoerror => 39,
        error.InvalidMmresultSize => 40,
    };
    return 0;
}

pub export fn rosette_mmsystem_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidSndFilename",
        2 => "InvalidSndAsync",
        3 => "InvalidSndAlias",
        4 => "InvalidSndNodefault",
        5 => "InvalidSndNostop",
        6 => "InvalidSndLoop",
        7 => "InvalidSndNowait",
        8 => "InvalidSndPurge",
        9 => "InvalidSndApplication",
        10 => "InvalidSndAliasId",
        11 => "InvalidSndResource",
        12 => "InvalidSndSystem",
        13 => "InvalidMmMcNotify",
        14 => "InvalidMciOpen",
        15 => "InvalidMciClose",
        16 => "InvalidMciPlay",
        17 => "InvalidMciStop",
        18 => "InvalidMciPause",
        19 => "InvalidMciSeek",
        20 => "InvalidMciSet",
        21 => "InvalidMciStatus",
        22 => "InvalidMciNotify",
        23 => "InvalidMciWait",
        24 => "InvalidMciFrom",
        25 => "InvalidMciTo",
        26 => "InvalidMciOpenType",
        27 => "InvalidMciOpenElement",
        28 => "InvalidMciPlayAlias",
        29 => "InvalidMciSetDoorOpen",
        30 => "InvalidMciSetDoorClosed",
        31 => "InvalidMciStatusLength",
        32 => "InvalidMciStatusPosition",
        33 => "InvalidMciStatusMode",
        34 => "InvalidMciModeStop",
        35 => "InvalidMciModePlay",
        36 => "InvalidMciModePause",
        37 => "InvalidMciModeOpen",
        38 => "InvalidMciAllDevicesId",
        39 => "InvalidMmsyserrNoerror",
        40 => "InvalidMmresultSize",
        else => "UnknownMmsystemFailure",
    };
}

test "mmsystem.h matches pseudo-Windows constants" {
    try validateAll();
}
