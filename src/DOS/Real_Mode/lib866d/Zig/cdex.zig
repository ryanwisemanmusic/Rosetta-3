const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");

pub const CDA_MAX_TRACKS: u8 = 99;

pub const TrackType = enum(u8) {
    audio = 0,
    data = 1,
    _4ch = 2,
    invalid = 3,
};

pub const MSF = extern struct {
    frame: u8,
    second: u8,
    minute: u8,
    reserved: u8,
};

pub const TrackEntry = extern struct {
    trackId: u8,
    type: TrackType,
    start: MSF,
    length: MSF,
};

pub const TOC = extern struct {
    trackCount: u8,
    firstTrack: u8,
    lastTrack: u8,
    totalDiscLength: MSF,
    tracks: [CDA_MAX_TRACKS + 1]TrackEntry,
};

pub const CdexInfo = extern struct {
    driveCount: usize,
    firstDriveLetter: u8,
    verMajor: u8,
    verMinor: u8,
};

const IoctlInCmd = enum(u8) {
    getDeviceHeaderAddress = 0,
    getHeadLocation,
    reserved,
    getErrorStatistics,
    getAudioChannelInfo,
    readDriveBytes,
    getDeviceStatus,
    getSectorSize,
    getVolumeSize,
    getMediaChangeStatus,
    getAudioDiscInfo,
    getAudioTrackInfo,
    getQChannelInfo,
    getSubChannelInfo,
    getUpcCode,
    getAudioStatusInfo,
    _invalid,
};

const IoctlOutCmd = enum(u8) {
    ejectDisc = 0,
    lockDoor,
    resetDrive,
    audioChannelCtrl,
    controlString,
    closeTray,
    _invalid,
};

const AddressingMode = enum(u8) {
    hsg = 0,
    redbook = 1,
    _invalid,
};

const CdexRequestCmd = enum(u8) {
    init = 0,
    ioctlIn = 3,
    ioctlOut = 12,
    readLong = 128,
    readLongPrefetch = 130,
    seek = 131,
    play = 132,
    stop = 133,
    writeLong = 134,
    writeLongVerify = 135,
    @"resume" = 136,
};

const CDAS_PLAYING: u8 = 0x11;
const CDAS_PAUSED: u8 = 0x12;
const CDAS_COMPLETE: u8 = 0x13;
const CDAS_ERROR: u8 = 0x14;
const CDAS_NODISC: u8 = 0x15;

const CdTrackCtrl = packed struct(u8) {
    reserved: u4 = 0,
    preEmphasis: u1 = 0,
    copyAllowed: u1 = 0,
    trackType: u2 = 0,
};

const MSFSwap = extern struct {
    minute: u8,
    second: u8,
    frame: u8,
    reserved: u8,
};

const IoctlAudioTrackInfo = extern struct {
    trackNumber: u8,
    start: MSF,
    controlInfo: CdTrackCtrl,
};

const IoctlAudioDiscInfo = extern struct {
    firstTrack: u8,
    lastTrack: u8,
    leadout: MSF,
};

const IoctlAudioQChannelInfo = extern struct {
    controlAdr: u8,
    currentTrack: u8,
    pointOrIndex: u8,
    timeInTrack: MSFSwap,
    timeOnDisc: MSFSwap,
};

const Ioctl = extern struct {
    command: u8,
    data: extern union {
        audioTrackInfo: IoctlAudioTrackInfo,
        audioDiscInfo: IoctlAudioDiscInfo,
        audioQChannelInfo: IoctlAudioQChannelInfo,
    },
};

const CdexRequestStatus = extern union {
    raw: u16,
    fields: packed struct(u16) {
        error_code: u8,
        done: u1,
        busy: u1,
        reserved: u5,
        @"error": u1,
    },
};

const CdPosition = extern union {
    msf: MSF,
    hsg: u32,
};

const IoctlFields = extern struct {
    media: u8,
    ctlBuf: ?*anyopaque,
    byteCount: u16,
    startingSector: u16,
    volId: ?*anyopaque,
};

const PlayFields = extern struct {
    addressingMode: u8,
    start: CdPosition,
    length: CdPosition,
};

const CdexRequest = extern struct {
    length: u8,
    unit: u8,
    command: u8,
    status: CdexRequestStatus,
    reserved: [8]u8,
    data: extern union {
        ioctl: IoctlFields,
        play: PlayFields,
    },
};

fn letterToIndex(letter: u8) u16 {
    return std.ascii.toLower(letter) - 'a';
}

fn driveIsCdexDrive(letter: u8) bool {
    _ = letter;
    return false;
}

pub fn msfToFrames(m: MSF) u32 {
    return @as(u32, m.minute) * 60 * 75 + @as(u32, m.second) * 75 + m.frame;
}

pub fn framesToMSF(raw: u32) MSF {
    return MSF{
        .reserved = 0,
        .frame = @truncate(raw % 75),
        .second = @truncate((raw / 75) % 60),
        .minute = @truncate(raw / 75 / 60),
    };
}

fn calculateDistance(from: MSF, to: MSF) MSF {
    const framesFrom = msfToFrames(from);
    const framesTo = msfToFrames(to);
    const distance = if (framesTo > framesFrom) framesTo - framesFrom else framesFrom - framesTo;
    return framesToMSF(distance);
}

fn msfToHSG(m: MSF) u32 {
    return msfToFrames(m) - 150;
}
fn hsgToMSF(hsg_val: u32) MSF {
    return framesToMSF(hsg_val + 150);
}

fn getIoctlTransferSize(ioctlCmd: u8, requestCmd: u8) u16 {
    _ = ioctlCmd;
    _ = requestCmd;
    return 0;
}

fn cdexRequest(letter: u8, req: *CdexRequest) bool {
    _ = letter;
    _ = req;
    return false;
}

fn cdexIoctl(letter: u8, ctl: *Ioctl, requestCmd: u8, statusCode: ?*CdexRequestStatus) bool {
    _ = letter;
    _ = ctl;
    _ = requestCmd;
    _ = statusCode;
    return false;
}

fn cdexIoctlIn(letter: u8, ctl: *Ioctl, cmd: IoctlInCmd, statusCode: ?*CdexRequestStatus) bool {
    ctl.command = @intFromEnum(cmd);
    return cdexIoctl(letter, ctl, @intFromEnum(CdexRequestCmd.ioctlIn), statusCode);
}

fn cdexIoctlOut(letter: u8, ctl: *Ioctl, cmd: IoctlOutCmd, statusCode: ?*CdexRequestStatus) bool {
    ctl.command = @intFromEnum(cmd);
    return cdexIoctl(letter, ctl, @intFromEnum(CdexRequestCmd.ioctlOut), statusCode);
}

pub fn getCdexInfo(info: ?*CdexInfo) bool {
    _ = info;
    return false;
}

pub fn cda_getTOC(letter: u8, toc: *TOC) bool {
    _ = letter;
    toc.* = std.mem.zeroes(TOC);
    return false;
}

pub fn cda_getFirstAudioTrack(toc: *const TOC) u8 {
    for (toc.tracks[0..toc.trackCount], 0..) |*t, i| {
        if (t.type == .audio) return @truncate(i);
    }
    return 0xFF;
}

pub fn cda_tocGetTrack(toc: *const TOC, track: u8) ?*const TrackEntry {
    if (track >= toc.trackCount) return null;
    return &toc.tracks[@as(usize, @intCast(track))];
}

pub fn cda_playTrack(letter: u8, toc: *const TOC, track: u8) bool {
    _ = letter;
    _ = toc;
    _ = track;
    return false;
}

pub fn cda_stop(letter: u8) bool {
    _ = letter;
    return false;
}

pub fn cda_getPlaybackPosition(letter: u8, inTrack: ?*MSF, onDisc: ?*MSF) bool {
    _ = letter;
    _ = inTrack;
    _ = onDisc;
    return false;
}
