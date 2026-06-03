const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");

pub const ExtraAttribs = packed struct(u16) {
    _dummy_0_: u7 = 0,
    hasLFB: u1 = 0,
    _dummy_1_: u8 = 0,
};

pub const ModeInfo = extern struct {
    attributes: ExtraAttribs,
    windowA: u8,
    windowB: u8,
    granularity: u16,
    windowSize: u16,
    segmentA: u16,
    segmentB: u16,
    winFuncPtr: ?*anyopaque,
    pitch: u16,
    width: u16,
    height: u16,
    wChar: u8,
    yChar: u8,
    planes: u8,
    bpp: u8,
    banks: u8,
    memoryModel: u8,
    bankSize: u8,
    imagePages: u8,
    __reserved_1__: u8,
    redMask: u8,
    redPosition: u8,
    greenMask: u8,
    greenPosition: u8,
    blueMask: u8,
    bluePosition: u8,
    reservedMask: u8,
    reservedPosition: u8,
    directColorAttributes: u8,
    lfbAddress: u32,
    offScreenMemAddr: u32,
    offScreenMemSize: u16,
    padding: [206]u8,
};

pub const Version = extern struct {
    minor: u8,
    major: u8,
};

pub const BiosInfo = extern struct {
    signature: [4]u8,
    version: Version,
    oemStringPtr: ?*anyopaque,
    capabilities: [4]u8,
    modeListPtr: ?*anyopaque,
    totalMemory: u16,
    padding: [496]u8,
};

pub fn getBiosInfo(biosInfo: *BiosInfo) bool {
    biosInfo.* = std.mem.zeroes(BiosInfo);
    @memcpy(biosInfo.signature[0..4], "VBE2");
    return isValidVesaBios(biosInfo);
}

pub fn isValidVesaBios(biosInfo: *const BiosInfo) bool {
    if (biosInfo.modeListPtr == null) return false;
    if (biosInfo.version.major == 0 and biosInfo.version.minor == 0) return false;
    if (!std.mem.eql(u8, biosInfo.signature[0..4], "VESA")) return false;
    return true;
}

pub fn getModeCount(biosInfo: *const BiosInfo) usize {
    if (!isValidVesaBios(biosInfo)) return 0;
    const modeList: [*]const u16 = @ptrCast(biosInfo.modeListPtr);
    var count: usize = 0;
    while (modeList[count] != 0xFFFF) count += 1;
    return count;
}

pub fn getModeInfoByModeId(modeInfo: *ModeInfo, modeId: u16) bool {
    _ = modeInfo;
    _ = modeId;
    return false;
}

pub fn getModeInfoByIndex(biosInfo: *const BiosInfo, modeInfo: *ModeInfo, index: usize) bool {
    if (index >= getModeCount(biosInfo)) return false;
    const modeList: [*]const u16 = @ptrCast(biosInfo.modeListPtr);
    return getModeInfoByModeId(modeInfo, modeList[index]);
}

pub fn getVRAMSize(biosInfo: *const BiosInfo) u32 {
    return @as(u32, biosInfo.totalMemory) * 0x10000;
}
