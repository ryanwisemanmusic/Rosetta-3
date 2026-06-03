const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const sys = @import("sys.zig");
const picdma = @import("picdma.zig");

pub const DSPVersion = extern struct {
    major: u8,
    minor: u8,
};

pub const DMACallback = *const fn (dst: [*]u8, sizeBytes: u32) void;

var dmaBuffer: sys.DMABuffer = undefined;
var initialized: bool = false;
var oldISR: ?sys.ISR = null;
var userCallback: ?DMACallback = null;
var bufferIndex: u16 = 0;
var sbPort: u16 = 0;
var sbIrq: u16 = 0;
var sbDmaL: u16 = 0;
var sbDmaH: u16 = 0;
var oldIrqState: bool = false;
var playbackDma: u16 = 0;
var atexitRegistered: bool = false;

const BUFFER_SIZE: u32 = 4096;
const BUFFER_SLICE_SIZE: u32 = 2048;
const DSP_TIMEOUT_MS: u32 = 500;

const DSPCommand = enum(u8) {
    setTimeConst = 0x40,
    setRate = 0x41,
    dmaAuto16BitStart = 0xB6,
    dmaAuto8BitStart = 0xC6,
    speakerOn = 0xD1,
    speakerOff = 0xD3,
    play8BitPause = 0xD0,
    play8BitResume = 0xD4,
    play16BitPause = 0xD5,
    play16BitResume = 0xD6,
    dmaAuto16BitStop = 0xD9,
    dmaAuto8BitStop = 0xDA,
    getDspVersion = 0xE1,
    getCopyright = 0xE3,
};

const MixerReg = enum(u8) {
    irq = 0x80,
    dma = 0x81,
    irqStatus = 0x82,
};

const DMAFormat = extern union {
    raw: u8,
    fields: packed struct(u8) {
        reserved0: u4,
        isSigned: u1,
        isStereo: u1,
        reserved1: u2,
    },
};

const IRQStatus = extern union {
    raw: u8,
    fields: packed struct(u8) {
        dma8: u1,
        dma16: u1,
        midi: u1,
        reserved: u5,
    },
};

fn dspWaitReadReady(io: u16) bool {
    _ = io;
    return false;
}

fn dspRead(io: u16, dst: *u8) bool {
    if (!dspWaitReadReady(io)) return false;
    dst.* = 0;
    return true;
}

fn dspWaitWriteReady(io: u16) bool {
    _ = io;
    return false;
}

fn dspWrite(io: u16, value: u8) bool {
    if (!dspWaitWriteReady(io)) return false;
    _ = value;
    return true;
}

fn dspCmd(io: u16, cmd: DSPCommand) bool {
    return dspWrite(io, @intFromEnum(cmd));
}

fn dspReset(io: u16) bool {
    _ = io;
    return false;
}

fn mixerWrite(io: u16, reg: MixerReg, val: u8) void {
    _ = io;
    _ = reg;
    _ = val;
}

fn mixerRead(io: u16, reg: MixerReg) u8 {
    _ = io;
    _ = reg;
    return 0;
}

fn setRate(io: u16, rate: u16) bool {
    return dspCmd(io, .setRate) and dspCmd(io, @truncate(rate >> 8)) and dspCmd(io, @truncate(rate & 0xFF));
}

fn advancePlayback() void {
    bufferIndex = if (bufferIndex != 0) 0 else 1;
    if (userCallback) |cb| {
        var nextPtr: [*]u8 = @ptrCast(dmaBuffer.aligned);
        if (bufferIndex != 0) nextPtr += BUFFER_SLICE_SIZE;
        cb(nextPtr, BUFFER_SLICE_SIZE);
    }
}

fn dmaPlaybackIsr() callconv(.C) void {
    const status: IRQStatus = .{ .raw = mixerRead(sbPort, .irqStatus) };
    if (status.fields.dma16 == 0) {
        if (oldISR) |old| old();
        return;
    }
    advancePlayback();
    picdma.irqAcknowledge(sbIrq);
}

pub fn init(io: u16, irq: u16, dmaL: u16, dmaH: u16) bool {
    debug.assertMsg(!initialized, "SB16 component already initialized!");
    if (!dspReset(io)) return false;
    var success = true;
    success = success and true;
    oldIrqState = picdma.irqIsEnabled(irq);
    if (!success) {
        deinit();
        return false;
    }
    initialized = true;
    sbIrq = irq;
    sbPort = io;
    sbDmaL = dmaL;
    sbDmaH = dmaH;
    bufferIndex = 0;
    playbackDma = 0;
    picdma.irqEnable(irq);
    return success;
}

pub fn deinit() void {
    if (initialized) {
        if (!oldIrqState) picdma.irqDisable(sbIrq);
        initialized = false;
    }
}

fn getIrqBitForIrq(irq: u16) u8 {
    const irqBitLookup = [_]u8{ 0x00, 0x00, 0x01, 0x00, 0x00, 0x02, 0x00, 0x04, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00 };
    if (irq > 15) return 0x00;
    return irqBitLookup[@as(usize, @intCast(irq))];
}

pub fn isIrqSupported(irq: u16) bool {
    return getIrqBitForIrq(irq) != 0x00;
}

pub fn getDSPVersion(io: u16) DSPVersion {
    var ret = DSPVersion{ .major = 0xFF, .minor = 0xFF };
    debug.assertMsg(initialized, "SB16 module not initialized.");
    if (!dspCmd(io, .getDspVersion)) return ret;
    _ = dspRead(io, &ret.major);
    _ = dspRead(io, &ret.minor);
    return ret;
}

pub fn getDSPCopyright(io: u16, buf: []u8) bool {
    debug.assertMsg(initialized, "SB16 module not initialized.");
    if (!dspReset(io)) return false;
    if (!dspCmd(io, .getCopyright)) return false;
    var i: u16 = 0;
    while (i < buf.len - 1) {
        var byte: u8 = undefined;
        if (!dspRead(io, &byte)) break;
        buf[@as(usize, @intCast(i))] = byte;
        i += 1;
        if (byte == 0) break;
    }
    if (i < buf.len) buf[@as(usize, @intCast(i))] = 0;
    return true;
}

pub fn startPlayback16(io: u16, stereo: bool, rate: u16, cb: DMACallback) bool {
    debug.assertMsg(initialized, "SB16 module not initialized.");
    debug.nullcheck(cb);
    const irqBit = getIrqBitForIrq(sbIrq);
    if (irqBit == 0x00) return false;
    if (!dspReset(io)) return false;
    _ = rate;
    userCallback = cb;
    advancePlayback();
    if (!setRate(io, 44100)) return false;
    var playbackHalfSize: u16 = @intCast(BUFFER_SLICE_SIZE);
    if (stereo) playbackHalfSize >>= 1;
    var fmt: DMAFormat = .{ .raw = 0 };
    fmt.fields.isSigned = true;
    fmt.fields.isStereo = stereo;
    playbackDma = sbDmaH;
    mixerWrite(io, .irq, irqBit);
    mixerWrite(io, .dma, @as(u8, 1) << @as(u4, @truncate(playbackDma)));
    var ok = dspCmd(io, .dmaAuto16BitStart);
    ok = ok and dspWrite(io, fmt.raw);
    ok = ok and dspWrite(io, @truncate((@as(u16, playbackHalfSize) - 1) & 0xFF));
    ok = ok and dspWrite(io, @truncate((@as(u16, playbackHalfSize) - 1) >> 8));
    ok = ok and dspCmd(io, .speakerOn);
    return ok;
}

pub fn stopPlayback(io: u16) void {
    if (playbackDma != 0) {
        picdma.dmaDisable(playbackDma);
        _ = dspCmd(io, .play16BitPause);
        _ = dspCmd(io, .play8BitPause);
        playbackDma = 0;
        _ = dspReset(io);
    }
}
