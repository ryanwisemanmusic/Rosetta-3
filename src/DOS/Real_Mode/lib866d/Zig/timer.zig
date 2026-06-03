const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const sys = @import("sys.zig");
const picdma = @import("picdma.zig");

pub const Callback = *const fn () void;

const CMOS_INDEX: u16 = 0x70;
const CMOS_DATA: u16 = 0x71;
const REG_STATUS_A: u8 = 0x0A;
const REG_STATUS_B: u8 = 0x0B;
const REG_STATUS_C: u8 = 0x0C;
const PIE_BIT: u8 = 0x40;
const RTC_IRQ: u16 = 8;

const RtcRateEntry = struct {
    rate: u8,
    frequency: u16,
};

const rtcRates = [_]RtcRateEntry{
    .{ .rate = 15, .frequency = 2 },
    .{ .rate = 14, .frequency = 4 },
    .{ .rate = 13, .frequency = 8 },
    .{ .rate = 12, .frequency = 16 },
    .{ .rate = 11, .frequency = 32 },
    .{ .rate = 10, .frequency = 64 },
    .{ .rate = 9, .frequency = 128 },
    .{ .rate = 8, .frequency = 256 },
    .{ .rate = 7, .frequency = 512 },
    .{ .rate = 6, .frequency = 1024 },
    .{ .rate = 5, .frequency = 2048 },
    .{ .rate = 4, .frequency = 4096 },
    .{ .rate = 3, .frequency = 8192 },
};

const NUM_RATES = rtcRates.len;

var oldIsr: ?sys.ISR = null;
var irqWasEnabled: bool = false;
var userCallback: ?Callback = null;
var savedStatusB: u8 = 0;
var activeRate: u8 = 0;
var activeFreq: u16 = 0;
var atexitRegistered: bool = false;

fn cmosRead(reg: u8) u8 {
    sys.outPortL(CMOS_INDEX, reg & 0x7F);
    sys.ioDelay(250);
    const ret = sys.inPortL(CMOS_DATA);
    sys.ioDelay(250);
    return @as(u8, @truncate(ret));
}

fn cmosWrite(reg: u8, val: u8) void {
    sys.outPortL(CMOS_INDEX, reg & 0x7F);
    sys.ioDelay(250);
    sys.outPortL(CMOS_DATA, val);
    sys.ioDelay(250);
}

fn rtcIsr() callconv(.C) void {
    if (userCallback) |cb| cb();
    _ = cmosRead(REG_STATUS_C);
    picdma.irqAcknowledge(RTC_IRQ);
}

fn findBestRate(target: u16) ?*const RtcRateEntry {
    for (&rtcRates) |*entry| {
        if (entry.frequency >= target) return entry;
    }
    return null;
}

pub fn start(desiredFrequency: u16, cb: Callback) u16 {
    debug.nullcheck(cb);
    debug.assertMsg(activeFreq == 0, "timer already running");
    debug.assertMsg(desiredFrequency >= 2, "minimum frequency is 2 Hz");
    const best = findBestRate(desiredFrequency) orelse {
        debug.assertMsg(false, "no suitable RTC rate found");
        return 0;
    };
    userCallback = cb;
    const vec = picdma.getVectorNumberForIRQ(RTC_IRQ);
    irqWasEnabled = picdma.irqIsEnabled(RTC_IRQ);
    const status = cmosRead(REG_STATUS_A);
    const statusBOut = savedStatusB | PIE_BIT;
    cmosWrite(REG_STATUS_B, statusBOut);
    cmosWrite(REG_STATUS_A, (status & 0xF0) | (best.rate & 0x0F));
    _ = cmosRead(REG_STATUS_C);
    activeRate = best.rate;
    activeFreq = best.frequency;
    picdma.irqEnable(RTC_IRQ);
    _ = vec;
    return activeFreq;
}

pub fn stop() void {
    if (activeFreq == 0) return;
    const vec = picdma.getVectorNumberForIRQ(RTC_IRQ);
    cmosWrite(REG_STATUS_B, savedStatusB);
    _ = cmosRead(REG_STATUS_C);
    if (!irqWasEnabled) picdma.irqDisable(RTC_IRQ);
    oldIsr = null;
    userCallback = null;
    activeRate = 0;
    activeFreq = 0;
    _ = vec;
}
