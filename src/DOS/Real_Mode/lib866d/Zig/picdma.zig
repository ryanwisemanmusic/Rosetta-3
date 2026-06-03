const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const sys = @import("sys.zig");

const PIC1_CMD: u16 = 0x20;
const PIC1_DATA: u16 = 0x21;
const PIC2_CMD: u16 = 0xA0;
const PIC2_DATA: u16 = 0xA1;
const PIC_EOI: u8 = 0x20;

fn bit(x: u16) u16 {
    return @as(u16, 1) << @as(u4, @truncate(x));
}

fn getMaskPortAndBit(irqLevel: u16, maskPort: *u16) u8 {
    if (irqLevel >= 8) {
        maskPort.* = PIC2_DATA;
        return @as(u8, @truncate(bit(irqLevel - 8)));
    } else {
        maskPort.* = PIC1_DATA;
        return @as(u8, @truncate(bit(irqLevel)));
    }
}

pub fn irqIsEnabled(irqLevel: u16) bool {
    var maskPort: u16 = undefined;
    const b = getMaskPortAndBit(irqLevel, &maskPort);
    return (sys.inPortL(maskPort) & b) == 0;
}

pub fn irqEnable(irqLevel: u16) void {
    var maskPort: u16 = undefined;
    const b = getMaskPortAndBit(irqLevel, &maskPort);
    const mask = sys.inPortL(maskPort) & ~@as(u32, b);
    sys.outPortL(maskPort, @as(u32, mask));
    if (irqLevel >= 8) irqEnable(2);
}

pub fn irqDisable(irqLevel: u16) void {
    var maskPort: u16 = undefined;
    const b = getMaskPortAndBit(irqLevel, &maskPort);
    const mask = sys.inPortL(maskPort) | @as(u32, b);
    sys.outPortL(maskPort, @as(u32, mask));
}

pub fn irqAcknowledge(irqLevel: u16) void {
    if (irqLevel >= 8) sys.outPortL(PIC2_CMD, PIC_EOI);
    sys.outPortL(PIC1_CMD, PIC_EOI);
}

pub fn getVectorNumberForIRQ(irqLevel: u16) u16 {
    return if (irqLevel >= 8) irqLevel - 8 + 0x70 else irqLevel + 8;
}

const DMA8_MASK_REG: u16 = 0x0A;
const DMA8_MODE_REG: u16 = 0x0B;
const DMA8_FLIPFLOP_REG: u16 = 0x0C;
const DMA16_MASK_REG: u16 = 0xD4;
const DMA16_MODE_REG: u16 = 0xD6;
const DMA16_FLIPFLOP_REG: u16 = 0xD8;
const DMA_MODE_AUTOINIT: u16 = 0x58;

fn is16Bit(ch: u16) bool {
    return ch >= 4;
}

const addrPorts = [_]u16{ 0x00, 0x02, 0x04, 0x06, 0xC0, 0xC4, 0xC8, 0xCC };
const pagePorts = [_]u16{ 0x87, 0x83, 0x81, 0x82, 0x8F, 0x8B, 0x89, 0x8A };
const countPorts = [_]u16{ 0x01, 0x03, 0x05, 0x07, 0xC2, 0xC6, 0xCA, 0xCE };

fn dma_addrPort(ch: u16) u16 {
    return addrPorts[@as(usize, @intCast(ch))];
}
fn dma_pagePort(ch: u16) u16 {
    return pagePorts[@as(usize, @intCast(ch))];
}
fn dma_countPort(ch: u16) u16 {
    return countPorts[@as(usize, @intCast(ch))];
}
fn dma_maskPortFn(ch: u16) u16 {
    return if (is16Bit(ch)) DMA16_MASK_REG else DMA8_MASK_REG;
}
fn dma_flipflopPort(ch: u16) u16 {
    return if (is16Bit(ch)) DMA16_FLIPFLOP_REG else DMA8_FLIPFLOP_REG;
}
fn dma_modePort(ch: u16) u16 {
    return if (is16Bit(ch)) DMA16_MODE_REG else DMA8_MODE_REG;
}
fn dma_channelIndex(ch: u16) u16 {
    return ch & 0x03;
}

pub fn dmaDisable(channel: u16) void {
    sys.outPortL(dma_maskPortFn(channel), 0x04 | dma_channelIndex(channel));
}

pub fn dmaEnable(channel: u16) void {
    sys.outPortL(dma_maskPortFn(channel), dma_channelIndex(channel));
}

pub fn dmaSetParams(channel: u16, address: *const anyopaque, size: u16) void {
    const idx = dma_channelIndex(channel);
    var physAddr = sys.getPhysicalAddress(address);
    const page: u8 = @truncate(physAddr >> 16);
    dmaDisable(channel);
    if (is16Bit(channel)) {
        physAddr >>= 1;
        physAddr >>= 1;
    }
    sys.outPortL(dma_flipflopPort(channel), 0x00);
    sys.outPortL(dma_modePort(channel), DMA_MODE_AUTOINIT | idx);
    sys.outPortL(dma_addrPort(channel), physAddr & 0xFF);
    sys.outPortL(dma_addrPort(channel), (physAddr >> 8) & 0xFF);
    sys.outPortL(dma_pagePort(channel), page);
    sys.outPortL(dma_countPort(channel), (size - 1) & 0xFF);
    sys.outPortL(dma_countPort(channel), ((size - 1) >> 8) & 0xFF);
    dmaEnable(channel);
}
