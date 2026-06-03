const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");

pub const Volume = extern struct {
    shortName: [8]u8,
    longName: [16]u8,
    volRegL: u8,
    startBitL: u8,
    volRegR: u8,
    startBitR: u8,
    width: u8,
    minVal: u8,
    maxVal: u8,
    volInvert: bool,
    muteRegL: u8,
    muteBitL: u8,
    muteRegR: u8,
    muteBitR: u8,
    muteInvert: bool,
};

pub const ReadFunc = *const fn (ctrl: *VolumeControl, idx: usize, reg: u8, val: *u8) bool;
pub const WriteFunc = *const fn (ctrl: *VolumeControl, idx: usize, reg: u8, val: u8) bool;

pub const VolumeControl = struct {
    read: ReadFunc,
    write: WriteFunc,
    volumeCount: usize,
    chans: ?[]Volume,
    userData: ?*anyopaque,
};

pub const ChannelMask = enum(u8) {
    none = 0,
    right = 1,
    left = 2,
    both = 3,
};

fn getBitMask(bitIdx: u8, width: u8) u16 {
    var ret: u16 = 0;
    var i: u8 = 0;
    while (i < width) : (i += 1) {
        ret |= @as(u16, 1) << @as(u4, @truncate(bitIdx + i));
    }
    return ret;
}

fn insertBits(dst: *u8, bitIdx: u8, width: u8, value: u8) void {
    const mask: u8 = @truncate(getBitMask(bitIdx, width));
    dst.* &= ~mask;
    dst.* |= (value << bitIdx) & mask;
}

fn extractBits(value: u8, bitIdx: u8, width: u8) u8 {
    const mask: u8 = @truncate(getBitMask(bitIdx, width));
    return (value & mask) >> bitIdx;
}

pub fn volumeGetAbs(ctrl: *VolumeControl, idx: usize, l: ?*u8, r: ?*u8, muteL: ?*bool, muteR: ?*bool) bool {
    var volRegL: u8 = 0;
    var volRegR: u8 = 0;
    var muteRegL: u8 = 0;
    var muteRegR: u8 = 0;
    debug.nullcheck(ctrl);
    if (idx >= ctrl.volumeCount) return false;
    const vol = &ctrl.chans.?[idx];
    if (vol.volRegL != 0xFF and !ctrl.read(ctrl, idx, vol.volRegL, &volRegL)) return false;
    if (vol.volRegR != 0xFF and !ctrl.read(ctrl, idx, vol.volRegR, &volRegR)) return false;
    if (vol.muteRegL != 0xFF and !ctrl.read(ctrl, idx, vol.muteRegL, &muteRegL)) return false;
    if (vol.muteRegR != 0xFF and !ctrl.read(ctrl, idx, vol.muteRegR, &muteRegR)) return false;
    if (l) |lp| {
        if (vol.volRegL != 0xFF and vol.startBitL != 0xFF) lp.* = extractBits(volRegL, vol.startBitL, vol.width);
    }
    if (r) |rp| {
        if (vol.volRegR != 0xFF and vol.startBitR != 0xFF) rp.* = extractBits(volRegR, vol.startBitR, vol.width);
    }
    if (vol.volInvert) {
        if (l) |lp| {
            if (vol.volRegL != 0xFF) lp.* = vol.maxVal - lp.*;
        }
        if (r) |rp| {
            if (vol.volRegR != 0xFF) rp.* = vol.maxVal - rp.*;
        }
    }
    if (muteL) |ml| {
        if (vol.muteRegL != 0xFF and vol.muteBitL != 0xFF) ml.* = (extractBits(muteRegL, vol.muteBitL, 1) ^ @intFromBool(vol.muteInvert)) != 0;
    }
    if (muteR) |mr| {
        if (vol.muteRegR != 0xFF and vol.muteBitR != 0xFF) mr.* = (extractBits(muteRegR, vol.muteBitR, 1) ^ @intFromBool(vol.muteInvert)) != 0;
    }
    return true;
}

fn volumeSetInternal(doChannel: bool, doMute: bool, ctrl: *VolumeControl, idx: usize, volume: u8, volReg: u8, volStartBit: u8, volWidth: u8, muteReg: u8, muteStartBit: u8, muteValue: u8) bool {
    if (!doChannel) return true;
    var vol: u8 = undefined;
    if (!ctrl.read(ctrl, idx, volReg, &vol)) return false;
    insertBits(&vol, volStartBit, volWidth, volume);
    var ok = ctrl.write(ctrl, idx, volReg, vol);
    if (doMute) {
        var mute: u8 = undefined;
        if (!ctrl.read(ctrl, idx, muteReg, &mute)) return false;
        insertBits(&mute, muteStartBit, 1, muteValue);
        ok = ok and ctrl.write(ctrl, idx, muteReg, mute);
    }
    return ok;
}

pub fn volumeSetAbs(ctrl: *VolumeControl, idx: usize, value: u8, sides: ChannelMask) bool {
    debug.nullcheck(ctrl);
    if (idx >= ctrl.volumeCount) return false;
    if (sides == .none) return false;
    const vol = &ctrl.chans.?[idx];
    if (value > vol.maxVal) return false;
    const doLeft = (sides == .left or sides == .both) and vol.volRegL != 0xFF and vol.startBitL != 0xFF;
    const doRight = (sides == .right or sides == .both) and vol.volRegR != 0xFF and vol.startBitR != 0xFF;
    const hasMuteL = doLeft and vol.muteRegL != 0xFF and vol.muteBitL != 0xFF;
    const hasMuteR = doRight and vol.muteRegR != 0xFF and vol.muteBitR != 0xFF;
    var muteValue: u8 = if (value == 0) 1 else 0;
    if (vol.muteInvert) muteValue = if (muteValue == 0) 1 else 0;
    var finalValue = value;
    if (vol.volInvert) finalValue = vol.maxVal - finalValue;
    var ok = volumeSetInternal(doLeft, hasMuteL, ctrl, idx, finalValue, vol.volRegL, vol.startBitL, vol.width, vol.muteRegL, vol.muteBitL, muteValue);
    ok = ok and volumeSetInternal(doRight, hasMuteR, ctrl, idx, finalValue, vol.volRegR, vol.startBitR, vol.width, vol.muteRegR, vol.muteBitR, muteValue);
    return ok;
}

pub fn beep(freq: u16, lengthMs: u32) void {
    if (freq == 0 or lengthMs == 0) return;
    const divider: u16 = @intCast(1193180 / @as(u32, freq));
    _ = divider;
    std.debug.print("\x07", .{});
}
