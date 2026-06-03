const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");

pub const VolumeCtrlIdx = enum(u8) {
    master = 0,
    wave = 1,
    pcspk = 2,
    mic = 3,
    linein = 4,
    cdin = 5,
    video = 6,
    aux = 7,
    line2 = 8,
    _count_,
};

pub const CodecVolumeRegister = struct {
    name: []const u8,
    reg: u16,
    mono: bool,
    muteBit: i16,
    boostBit: i16,
    maxAttenuation: u16,
    attenuationShift: u16,
    vol_l: u16,
    vol_r: u16,
    vol_muted: bool,
    vol_boost: bool,
};

pub const Volume = extern struct {
    maxVol: u16,
    l: u16,
    r: u16,
    l_percent: f32,
    r_percent: f32,
    muted: bool,
};

pub const WriteFunc = *const fn (dev: ?*anyopaque, reg: u16, value: u16) void;
pub const ReadFunc = *const fn (dev: ?*anyopaque, reg: u16) u16;

pub const Interface = struct {
    read: ReadFunc,
    write: WriteFunc,
    dev: ?*anyopaque,
    mixer: [@intFromEnum(VolumeCtrlIdx._count_)]CodecVolumeRegister,
};

const REG_GENERAL: u16 = 0x20;
const REG_GENERAL_3D_ON: u16 = 0x2000;
const REG_PWR_STATUS: u16 = 0x26;
const REG_EXTENDED_CTRL: u16 = 0x2A;
const REG_DAC_RATE: u16 = 0x2C;
const REG_ADC_RATE: u16 = 0x32;
const REG_VENDOR_ID1: u16 = 0x7C;
const REG_VENDOR_ID2: u16 = 0x7E;

const CodecRegInit = struct {
    name: []const u8,
    reg: u16,
    mono: bool,
    muteBit: i16,
    boostBit: i16,
    maxAttenuation: u16,
    attenuationShift: u16,
};

const c_codecVolumeRegisters = [_]CodecRegInit{
    .{ .name = "Master", .reg = 0x02, .mono = false, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x1F, .attenuationShift = 0 },
    .{ .name = "Wave Out", .reg = 0x18, .mono = false, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x1F, .attenuationShift = 0 },
    .{ .name = "PC Speaker", .reg = 0x0A, .mono = true, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x0F, .attenuationShift = 1 },
    .{ .name = "Microphone", .reg = 0x0E, .mono = true, .muteBit = 15, .boostBit = 6, .maxAttenuation = 0x1F, .attenuationShift = 0 },
    .{ .name = "Line In", .reg = 0x10, .mono = false, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x1F, .attenuationShift = 0 },
    .{ .name = "CD Audio", .reg = 0x12, .mono = false, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x1F, .attenuationShift = 0 },
    .{ .name = "Video In", .reg = 0x14, .mono = false, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x1F, .attenuationShift = 0 },
    .{ .name = "Auxiliary", .reg = 0x16, .mono = false, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x1F, .attenuationShift = 0 },
    .{ .name = "Line 2", .reg = 0x04, .mono = false, .muteBit = 15, .boostBit = -1, .maxAttenuation = 0x1F, .attenuationShift = 0 },
};

const CodecIdEntry = struct {
    codecId: u32,
    mask: u32,
    name: []const u8,
};

const c_supportedCodecs = [_]CodecIdEntry{
    .{ .codecId = 0x434d4941, .mask = 0xffffffff, .name = "C-Media CMI9738" },
    .{ .codecId = 0x434d4961, .mask = 0xffffffff, .name = "C-Media CMI9739" },
    .{ .codecId = 0x434d4969, .mask = 0xffffffff, .name = "C-Media CMI9780" },
    .{ .codecId = 0x434d4978, .mask = 0xffffffff, .name = "C-Media CMI9761A" },
    .{ .codecId = 0x434d4982, .mask = 0xffffffff, .name = "C-Media CMI9761B" },
    .{ .codecId = 0x434d4983, .mask = 0xffffffff, .name = "C-Media CMI9761A+" },
    .{ .codecId = 0x43525900, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4297" },
    .{ .codecId = 0x43525910, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4297A" },
    .{ .codecId = 0x43525920, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4298" },
    .{ .codecId = 0x43525928, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4294" },
    .{ .codecId = 0x43525930, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4299" },
    .{ .codecId = 0x43525948, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4201" },
    .{ .codecId = 0x43525958, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4205" },
    .{ .codecId = 0x43525960, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4291" },
    .{ .codecId = 0x43525970, .mask = 0xfffffff8, .name = "Cirrus Logic/Crystal CS4202" },
    .{ .codecId = 0x83847600, .mask = 0xffffffff, .name = "SigmaTel STAC9700" },
    .{ .codecId = 0x83847601, .mask = 0xffffffff, .name = "SigmaTel STAC9701" },
    .{ .codecId = 0x83847605, .mask = 0xffffffff, .name = "SigmaTel STAC9704" },
    .{ .codecId = 0x83847608, .mask = 0xffffffff, .name = "SigmaTel STAC9708" },
    .{ .codecId = 0x414c4300, .mask = 0xffffff00, .name = "Avance Logic ALC100" },
    .{ .codecId = 0x414c4710, .mask = 0xfffffff0, .name = "Avance Logic ALC200" },
    .{ .codecId = 0x414c4730, .mask = 0xffffffff, .name = "Avance Logic ALC101" },
    .{ .codecId = 0x414c4740, .mask = 0xfffffff0, .name = "Avance Logic ALC202" },
    .{ .codecId = 0x49434501, .mask = 0xffffffff, .name = "IC Ensemble ICE1230 / VIA VT1611" },
    .{ .codecId = 0x49434511, .mask = 0xffffffff, .name = "IC Ensemble ICE1232 / VIA VT1611A" },
    .{ .codecId = 0x49434514, .mask = 0xffffffff, .name = "IC Ensemble ICE1232A" },
    .{ .codecId = 0x49434551, .mask = 0xffffffff, .name = "IC Ensemble ICE1232A" },
    .{ .codecId = 0x56494120, .mask = 0xfffffff0, .name = "VIA VT1613" },
    .{ .codecId = 0x56494141, .mask = 0xffffffff, .name = "VIA VT1612" },
    .{ .codecId = 0x56494161, .mask = 0xffffffff, .name = "VIA VT1612A" },
    .{ .codecId = 0x00000000, .mask = 0x00000000, .name = "Unknown/Generic" },
};

fn mixerGetOne(ac: *Interface, volumeIndex: usize) void {
    var vol = &ac.mixer[volumeIndex];
    var val = ac.read(ac.dev, vol.reg);
    vol.vol_muted = false;
    vol.vol_boost = false;
    if (vol.muteBit >= 0) {
        vol.vol_muted = (val >> @as(u4, @truncate(@as(u8, @intCast(vol.muteBit))))) & 1 != 0;
        val &= ~(@as(u16, 1) << @as(u4, @truncate(@as(u8, @intCast(vol.muteBit)))));
    }
    if (vol.boostBit >= 0) {
        vol.vol_boost = (val >> @as(u4, @truncate(@as(u8, @intCast(vol.boostBit))))) & 1 != 0;
        val &= ~(@as(u16, 1) << @as(u4, @truncate(@as(u8, @intCast(vol.boostBit)))));
    }
    vol.vol_r = (val & 0x7F) >> vol.attenuationShift;
    vol.vol_l = val >> (8 + vol.attenuationShift);
    if (vol.mono) vol.vol_l = vol.vol_r;
    vol.vol_r = vol.maxAttenuation - vol.vol_r;
    vol.vol_l = vol.maxAttenuation - vol.vol_l;
}

pub fn mixerInit(ac: *Interface, readFunc: ReadFunc, writeFunc: WriteFunc, dev: ?*anyopaque) bool {
    debug.nullcheck(ac);
    debug.nullcheck(@as(*const anyopaque, @ptrCast(readFunc)));
    debug.nullcheck(@as(*const anyopaque, @ptrCast(writeFunc)));
    ac.read = readFunc;
    ac.write = writeFunc;
    ac.dev = dev;
    if (!powerUp(ac)) return false;
    for (&c_codecVolumeRegisters, &ac.mixer) |src, *dst| {
        dst.* = CodecVolumeRegister{
            .name = src.name,
            .reg = src.reg,
            .mono = src.mono,
            .muteBit = src.muteBit,
            .boostBit = src.boostBit,
            .maxAttenuation = src.maxAttenuation,
            .attenuationShift = src.attenuationShift,
            .vol_l = 0,
            .vol_r = 0,
            .vol_muted = false,
            .vol_boost = false,
        };
    }
    for (0..@intFromEnum(VolumeCtrlIdx._count_)) |i| mixerGetOne(ac, i);
    return true;
}

fn writeVerify(ac: *Interface, reg: u16, value: u16) bool {
    ac.write(ac.dev, reg, value);
    return value == ac.read(ac.dev, reg);
}

pub fn getCodecId(ac: *Interface) u32 {
    var id: u32 = ac.read(ac.dev, REG_VENDOR_ID1);
    id <<= 16;
    id |= ac.read(ac.dev, REG_VENDOR_ID2);
    return id;
}

pub fn getCodecName(ac: *Interface) []const u8 {
    const codecId = getCodecId(ac);
    for (&c_supportedCodecs) |entry| {
        const maskedId = codecId & entry.mask;
        if (maskedId == entry.codecId) return entry.name;
    }
    return "Unknown/Generic";
}

pub fn powerUp(ac: *Interface) bool {
    var timeout: i16 = 1000;
    ac.write(ac.dev, REG_PWR_STATUS, 0x0000);
    while (timeout > 0) : (timeout -= 1) {
        if (0x000F == ac.read(ac.dev, REG_PWR_STATUS)) return true;
    }
    return false;
}

pub fn getSurround(ac: *Interface) bool {
    const reg = ac.read(ac.dev, REG_GENERAL) & REG_GENERAL_3D_ON;
    return reg != 0;
}

pub fn setSurround(ac: *Interface, enable: bool) bool {
    var reg = ac.read(ac.dev, REG_GENERAL);
    reg &= ~REG_GENERAL_3D_ON;
    reg |= if (enable) REG_GENERAL_3D_ON else 0;
    return writeVerify(ac, REG_GENERAL, reg);
}

pub fn setMicBoost(ac: *Interface, enable: bool) bool {
    var reg = ac.read(ac.dev, ac.mixer[@intFromEnum(VolumeCtrlIdx.mic)].reg);
    reg &= ~(@as(u16, 1) << @as(u4, @truncate(@as(u8, @intCast(ac.mixer[@intFromEnum(VolumeCtrlIdx.mic)].boostBit)))));
    reg |= (@as(u16, @intFromBool(enable))) << @as(u4, @truncate(@as(u8, @intCast(ac.mixer[@intFromEnum(VolumeCtrlIdx.mic)].boostBit))));
    return writeVerify(ac, ac.mixer[@intFromEnum(VolumeCtrlIdx.mic)].reg, reg);
}

pub fn getChannelName(ac: *Interface, channel: VolumeCtrlIdx) []const u8 {
    if (@intFromEnum(channel) >= @intFromEnum(VolumeCtrlIdx._count_)) return "???";
    return ac.mixer[@intFromEnum(channel)].name;
}

pub fn getVolume(ac: *Interface, channel: VolumeCtrlIdx, vol: *Volume) void {
    mixerGetOne(ac, @intFromEnum(channel));
    vol.maxVol = ac.mixer[@intFromEnum(channel)].maxAttenuation;
    vol.l = ac.mixer[@intFromEnum(channel)].vol_l;
    vol.r = ac.mixer[@intFromEnum(channel)].vol_r;
    vol.l_percent = @as(f32, @floatFromInt(vol.l)) * 100.0 / @as(f32, @floatFromInt(vol.maxVol));
    vol.r_percent = @as(f32, @floatFromInt(vol.r)) * 100.0 / @as(f32, @floatFromInt(vol.maxVol));
    vol.muted = ac.mixer[@intFromEnum(channel)].vol_muted;
}

pub fn setVolume(ac: *Interface, channel: VolumeCtrlIdx, l: u16, r: u16, mute: bool) bool {
    var extraBitsMask: u16 = 0;
    const vol = &ac.mixer[@intFromEnum(channel)];
    if (l > vol.maxAttenuation or r > vol.maxAttenuation) return false;
    var value = ac.read(ac.dev, vol.reg);
    if (vol.boostBit >= 0) extraBitsMask |= @as(u16, 1) << @as(u4, @truncate(@as(u8, @intCast(vol.boostBit))));
    value &= extraBitsMask;
    const finalL = vol.maxAttenuation - l;
    const finalR = vol.maxAttenuation - r;
    value |= finalR << vol.attenuationShift;
    if (!vol.mono) value |= finalL << (8 + vol.attenuationShift);
    if (vol.muteBit >= 0) {
        value &= ~(@as(u16, 1) << @as(u4, @truncate(@as(u8, @intCast(vol.muteBit)))));
        value |= (@as(u16, @intFromBool(mute))) << @as(u4, @truncate(@as(u8, @intCast(vol.muteBit))));
    }
    const ret = writeVerify(ac, vol.reg, value);
    mixerGetOne(ac, @intFromEnum(channel));
    return ret;
}

pub fn setVolumePercent(ac: *Interface, channel: VolumeCtrlIdx, l: f32, r: f32, mute: bool) bool {
    const lInt: u16 = @intFromFloat(@round(l * @as(f32, @floatFromInt(ac.mixer[@intFromEnum(channel)].maxAttenuation)) / 100.0));
    const rInt: u16 = @intFromFloat(@round(r * @as(f32, @floatFromInt(ac.mixer[@intFromEnum(channel)].maxAttenuation)) / 100.0));
    return setVolume(ac, channel, lInt, rInt, mute);
}

pub fn setVariableSampleRate(ac: *Interface, enable: bool, rate: u16) bool {
    var extendedCtrlReg = ac.read(ac.dev, REG_EXTENDED_CTRL);
    extendedCtrlReg &= 0xFFFE;
    extendedCtrlReg |= @as(u16, @intFromBool(enable));
    if (!writeVerify(ac, REG_EXTENDED_CTRL, extendedCtrlReg)) return false;
    if (!enable) return true;
    return writeVerify(ac, REG_DAC_RATE, rate);
}
