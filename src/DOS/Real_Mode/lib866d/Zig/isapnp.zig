const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const sys = @import("sys.zig");
const util = @import("util.zig");

const PNP_MAX_MEM_DESCRIPTORS: u8 = 4;
const PNP_MAX_IO_DESCRIPTORS: u8 = 8;
const PNP_MAX_IRQ_DESCRIPTORS: u8 = 2;
const PNP_MAX_DMA_DESCRIPTORS: u8 = 2;
const PNP_MAX_STRING_LENGTH: u8 = 128;

pub const BiosInfo = extern struct {
    signature: [4]u8,
    version: u8,
    length: u8,
    controlField: u16,
    checksum: u8,
    eventNotifyFlag: u32,
    rmEntry: ?*anyopaque,
    pmEntryOffset: u16,
    pmEntryBase: u32,
    oemDevId: u32,
    rmDataSegment: u16,
    pmDataBase: u32,
};

pub const CardId = extern union {
    dword: u32,
    bytes: [4]u8,
};

pub const Mem24Cfg = extern struct {
    base: u16,
    ctrl: u8,
    limitRange: u16,
    padding: [3]u8,
};

pub const Mem32Cfg = extern struct {
    base: u32,
    ctrl: u8,
    limitRange: u32,
    paddding: [1]u8,
};

pub const IoCfg = extern struct {
    port: u16,
};

pub const IrqCfg = extern struct {
    level: u8,
    triggerType: u1,
    activeHigh: u1,
};

pub const DmaCfg = extern struct {
    ch: u8,
};

pub const ResIrq = extern struct {
    mask: u16,
    fields: packed struct(u8) {
        activeHighEdge: u1,
        activeLowEdge: u1,
        activeHighLevel: u1,
        activeLowLevel: u1,
        _rsv: u4,
    },
};

pub const ResDma = extern struct {
    mask: u8,
    fields: packed struct(u8) {
        width: u2,
        isBusMaster: u1,
        allowCountByByte: u1,
        allowCountByWord: u1,
        dmaSpeed: u2,
        _rsv: u1,
    },
};

pub const ResIoRange = extern struct {
    fields: packed struct(u8) {
        decodeFull16Bit: u1,
        _rsv1: u7,
    },
    baseMin: u16,
    baseMax: u16,
    @"align": u8,
    len: u8,
};

pub const ResIoFixed = extern struct {
    base: u16,
    len: u8,
};

pub const ResStartDep = extern struct {
    priority: u8,
};

pub const ResEndTag = extern struct {
    checksum: u8,
};

pub const ResMem24 = extern struct {
    fields: packed struct(u8) {
        writeable: u1,
        cacheable: u1,
        isHighAddress: u1,
        width: u2,
        shadowable: u1,
        isRom: u1,
        _rsv: u1,
    },
    minBase: u16,
    maxBase: u16,
    @"align": u16,
    len: u16,
};

pub const ResMem32 = extern struct {
    fields: packed struct(u8) {
        writeable: u1,
        cacheable: u1,
        isHighAddress: u1,
        width: u2,
        shadowable: u1,
        isRom: u1,
        _rsv: u1,
    },
    minBase: u32,
    maxBase: u32,
    @"align": u32,
    len: u32,
};

pub const ResMem32Fixed = extern struct {
    fields: packed struct(u8) {
        writeable: u1,
        cacheable: u1,
        isHighAddress: u1,
        width: u2,
        shadowable: u1,
        isRom: u1,
        _rsv: u1,
    },
    base: u32,
    len: u32,
};

pub const ResAnsiString = extern struct {
    data: [PNP_MAX_STRING_LENGTH]u8,
};

pub const Resource = extern struct {
    raw: [3]u8,
    // Small/large layout follows via inline structs in code
};

pub const ResourceList = struct {
    count: usize,
    items: ?[]Resource,
};

pub const DependentFunctionList = struct {
    count: usize,
    funcs: ?[]ResourceList,
};

pub const LogicalDeviceInfo = struct {
    active: u8,
    eisaId: CardId,
    idStr: [8]u8,
    usesMem32: bool,
    mem24: [4]Mem24Cfg,
    mem32: [4]Mem32Cfg,
    io: [8]IoCfg,
    irq: [2]IrqCfg,
    dma: [2]DmaCfg,
    resources: ResourceList,
    dfList: DependentFunctionList,
};

pub const DeviceInfo = struct {
    csn: u8,
    eisaId: CardId,
    idStr: [8]u8,
    logDev: [4]LogicalDeviceInfo,
    numLogDevs: u8,
};

pub const SupportedValueType = enum(u8) {
    ioRange = 0,
    irq = 1,
    dma = 2,
};

const PNP_ADDRESS: u16 = 0x0279;
const PNP_WRITE: u16 = 0x0A79;
const PNP_READ: u16 = 0x0213;

const PNP_REG_SET_READPORT: u8 = 0x00;
const PNP_REG_ISOLATION: u8 = 0x01;
const PNP_REG_CONFIG_CTRL: u8 = 0x02;
const PNP_CTRL_RESET_CSN: u8 = 0x04;
const PNP_CTRL_WAIT_KEY: u8 = 0x02;
const PNP_CTRL_RESET_DEV: u8 = 0x01;
const PNP_REG_WAKE_CSN: u8 = 0x03;
const PNP_REG_RESOURCEDATA: u8 = 0x04;
const PNP_REG_STATUS: u8 = 0x05;
const PNP_REG_CSN: u8 = 0x06;
const PNP_REG_LOGDEV: u8 = 0x07;
const PNP_REG_ACTIVATE: u8 = 0x30;
const PNP_REG_MEM24_0: u8 = 0x40;
const PNP_REG_MEM32_0: u8 = 0x76;
const PNP_REG_IO0_HI: u8 = 0x60;
const PNP_REG_IO0_LO: u8 = 0x61;
const PNP_REG_IRQ0_NUM: u8 = 0x70;
const PNP_REG_IRQ0_TYPE: u8 = 0x71;
const PNP_REG_DMA0: u8 = 0x74;

const PNP_S_LOG_DEV_ID: u8 = 0x02;
const PNP_S_IRQ: u8 = 0x04;
const PNP_S_DMA: u8 = 0x05;
const PNP_S_START_DEP: u8 = 0x06;
const PNP_S_END_DEP: u8 = 0x07;
const PNP_S_IO: u8 = 0x08;
const PNP_S_IO_FIXED: u8 = 0x09;
const PNP_S_END_TAG: u8 = 0x0F;
const PNP_L_ANSI_ID: u8 = 0x02;

fn decodeEisaId(id: CardId, buf: *[8]u8) void {
    const hex = "0123456789ABCDEF";
    buf[0] = 0x40 + ((id.bytes[0] & 0x7F) >> 2);
    buf[1] = 0x40 + ((id.bytes[0] & 0x03) << 3) + (id.bytes[1] >> 5);
    buf[2] = 0x40 + (id.bytes[1] & 0x1F);
    buf[3] = hex[id.bytes[2] >> 4];
    buf[4] = hex[id.bytes[2] & 0x0F];
    buf[5] = hex[id.bytes[3] >> 4];
    buf[6] = hex[id.bytes[3] & 0x0F];
    buf[7] = 0;
}

pub fn biosDetect(info: *BiosInfo) bool {
    const pnpSig = "$PnP";
    info.* = std.mem.zeroes(BiosInfo);
    _ = pnpSig;
    return false;
}

fn dependentFunctionListGrow(dfList: *DependentFunctionList) ?*ResourceList {
    const newCount = dfList.count + 1;
    const newFuncs = std.heap.page_allocator.realloc(dfList.funcs, newCount * @sizeOf(ResourceList)) catch return null;
    dfList.funcs = newFuncs;
    dfList.funcs.?[newCount - 1] = ResourceList{ .count = 0, .items = null };
    dfList.count = newCount;
    return &dfList.funcs.?[newCount - 1];
}

fn resourceListAppend(list: *ResourceList, toAdd: *const Resource) bool {
    const newCount = list.count + 1;
    const newItems = std.heap.page_allocator.realloc(list.items, newCount * @sizeOf(Resource)) catch return false;
    list.items = newItems;
    list.items.?[newCount - 1] = toAdd.*;
    list.count = newCount;
    return true;
}

fn freeResourceList(list: *ResourceList) void {
    if (list.items) |items| {
        std.heap.page_allocator.free(items);
        list.items = null;
    }
    list.count = 0;
}

pub fn freeDeviceData(info: *DeviceInfo) void {
    for (0..info.numLogDevs) |i| {
        freeResourceList(&info.logDev[i].resources);
        for (0..info.logDev[i].dfList.count) |df| {
            freeResourceList(&info.logDev[i].dfList.funcs.?[df]);
        }
    }
}

fn readReg(reg: u8) u8 {
    sys.outPortL(PNP_ADDRESS, reg);
    sys.ioDelay(10);
    const ret = sys.inPortL(PNP_READ);
    sys.ioDelay(10);
    return @truncate(ret);
}

fn readStruct(buf: *anyopaque, reg: u8, size: usize) void {
    var dst: [*]u8 = @ptrCast(buf);
    var r = reg;
    var remaining = size;
    while (remaining > 0) {
        dst[0] = readReg(r);
        dst += 1;
        r += 1;
        remaining -= 1;
    }
}

fn writeReg(reg: u8, val: u8) void {
    sys.outPortL(PNP_ADDRESS, reg);
    sys.ioDelay(10);
    sys.outPortL(PNP_WRITE, val);
    sys.ioDelay(10);
}

fn writeStruct(buf: *const anyopaque, reg: u8, size: usize) void {
    var src: [*]const u8 = @ptrCast(buf);
    var r = reg;
    var remaining = size;
    while (remaining > 0) {
        writeReg(r, src[0]);
        src += 1;
        r += 1;
        remaining -= 1;
    }
}

fn writeStructVerify(buf: *const anyopaque, reg: u8, size: usize) bool {
    var src: [*]const u8 = @ptrCast(buf);
    var r = reg;
    var remaining = size;
    while (remaining > 0) {
        writeReg(r, src[0]);
        const written = readReg(r);
        if (written != src[0]) return false;
        src += 1;
        r += 1;
        remaining -= 1;
    }
    return true;
}

fn readResourceByte(dst: *u8) bool {
    var retries: u16 = 10;
    while (retries > 0) {
        retries -= 1;
        const status = readReg(PNP_REG_STATUS);
        if (status & 0x01 != 0) {
            dst.* = readReg(PNP_REG_RESOURCEDATA);
            return true;
        }
    }
    return false;
}

fn readResourceStructWithMaxSize(buf: *anyopaque, dstSize: usize, srcSize: usize) bool {
    var dst: [*]u8 = @ptrCast(buf);
    var remaining = srcSize;
    var dstRemaining = dstSize;
    while (remaining > 0) {
        remaining -= 1;
        var data: u8 = undefined;
        if (!readResourceByte(&data)) return false;
        if (dstRemaining > 0) {
            dstRemaining -= 1;
            dst[0] = data;
            dst += 1;
        }
    }
    return true;
}

fn sendInitKey() void {
    const initKey = [_]u8{
        0x6A, 0xB5, 0xDA, 0xED, 0xF6, 0xFB, 0x7D, 0xBE,
        0xDF, 0x6F, 0x37, 0x1B, 0x0D, 0x86, 0xC3, 0x61,
        0xB0, 0x58, 0x2C, 0x16, 0x8B, 0x45, 0xA2, 0xD1,
        0xE8, 0x74, 0x3A, 0x9D, 0xCE, 0xE7, 0x73, 0x39,
    };
    sys.outPortL(PNP_ADDRESS, 0x00);
    sys.ioDelay(10);
    sys.outPortL(PNP_ADDRESS, 0x00);
    sys.ioDelay(10);
    for (initKey) |key| {
        sys.outPortL(PNP_ADDRESS, key);
        sys.ioDelay(10);
    }
}

fn readWithDelay() u8 {
    const ret = sys.inPortL(PNP_READ);
    sys.ioDelay(10);
    return @truncate(ret);
}

fn readSerialBit() u8 {
    const data = (@as(u16, readWithDelay()) << 8) | readWithDelay();
    sys.ioDelay(250);
    return if (data == 0x55AA) 1 else 0;
}

fn prepareEnumeration() void {
    writeReg(PNP_REG_CONFIG_CTRL, PNP_CTRL_WAIT_KEY);
    sendInitKey();
    writeReg(PNP_REG_CONFIG_CTRL, PNP_CTRL_RESET_CSN);
    util.sleep(2);
    writeReg(PNP_REG_CONFIG_CTRL, PNP_CTRL_WAIT_KEY);
    sendInitKey();
    util.sleep(2);
    writeReg(PNP_REG_WAKE_CSN, 0x00);
    writeReg(PNP_REG_SET_READPORT, PNP_READ >> 2);
    util.sleep(1);
}

fn read72BitSerialId() u32 {
    var ourChecksum: u8 = 0x6A;
    var theirChecksum: u8 = 0;
    var id: u32 = 0;
    for (0..72) |i| {
        const bit = readSerialBit();
        if (i < 64) {
            ourChecksum = ((((ourChecksum ^ (ourChecksum >> 1)) & 0x01) ^ bit) << 7) | (ourChecksum >> 1);
        } else {
            theirChecksum |= @as(u8, bit) << @as(u3, @truncate(i - 64));
        }
        if (i < 32) id |= @as(u32, bit) << @as(u5, @truncate(i));
    }
    if (id == 0x00000000 or id == 0xFFFFFFFF) return 0;
    if (ourChecksum != theirChecksum) return 0;
    return id;
}

fn startDeviceEnumeration(csn: u8) u32 {
    util.sleep(1);
    sys.outPortL(PNP_ADDRESS, PNP_REG_ISOLATION);
    util.sleep(1);
    const id = read72BitSerialId();
    if (id == 0) return 0;
    writeReg(PNP_REG_CSN, csn);
    return id;
}

const ResourcePopulationStatus = enum(u8) {
    success = 0,
    @"error" = 1,
    openBus = 2,
    endOfData = 3,
};

fn populateResources(dev: *DeviceInfo) usize {
    var itemIndex: usize = 0;
    var inDF = false;
    var currentDF: ?*ResourceList = null;
    var firstDevIdParsed = false;
    var logDevIndex: usize = 0;
    var dst = &dev.logDev[logDevIndex];

    while (true) {
        var cur: Resource = std.mem.zeroes(Resource);
        if (!readResourceByte(&cur.raw[0])) return 0;
        const isLarge = (cur.raw[0] >> 7) & 1 != 0;

        if (isLarge) {
            var largeLen: u16 = undefined;
            if (!readResourceStructWithMaxSize(&largeLen, @sizeOf(u16), @sizeOf(u16))) return 0;
            @memcpy(cur.raw[1..3], std.mem.asBytes(&largeLen));
            const typeField = cur.raw[0] & 0x7F;
            const copySize = @min(cur.raw.len - 3, largeLen);
            if (typeField == 0x7F and largeLen == 0xFFFF) return logDevIndex;
            if (!readResourceStructWithMaxSize(&cur.raw[3], copySize, largeLen)) return logDevIndex;
        } else {
            const smallLen = cur.raw[0] & 0x07;
            if (!readResourceStructWithMaxSize(&cur.raw[1], smallLen, smallLen)) return logDevIndex;
        }

        const curTypeSmall = cur.raw[0] >> 3 & 0x0F;
        if (!isLarge and curTypeSmall == PNP_S_LOG_DEV_ID) {
            if (firstDevIdParsed) {
                if (inDF) {
                    currentDF = null;
                    inDF = false;
                }
                logDevIndex += 1;
                if (logDevIndex >= 4) return logDevIndex;
                dst = &dev.logDev[logDevIndex];
            } else {
                firstDevIdParsed = true;
            }
        }

        if (!isLarge and curTypeSmall == PNP_S_END_TAG) return logDevIndex + 1;

        if (!isLarge and curTypeSmall == PNP_S_START_DEP) {
            inDF = true;
            currentDF = dependentFunctionListGrow(&dst.dfList);
            continue;
        }

        if (!isLarge and curTypeSmall == PNP_S_END_DEP) {
            currentDF = null;
            inDF = false;
            continue;
        }

        if (inDF) {
            if (currentDF) |df| {
                if (!resourceListAppend(df, &cur)) return logDevIndex;
            }
        } else {
            if (!resourceListAppend(&dst.resources, &cur)) return logDevIndex;
        }

        itemIndex += 1;
    }

    return logDevIndex;
}

fn switchLogicalDevice(index: usize) bool {
    if (index >= 4) return false;
    const value: u8 = @truncate(index);
    return writeStructVerify(&value, PNP_REG_LOGDEV, 1);
}

fn readMem32WithByteswap(dst: *Mem32Cfg, idx: usize) void {
    readStruct(@as(*anyopaque, @ptrCast(dst)), PNP_REG_MEM32(idx), @sizeOf(Mem32Cfg));
    util.swapInPlace32(&dst.base);
    util.swapInPlace32(&dst.limitRange);
}

fn readMem24WithByteswap(dst: *Mem24Cfg, idx: usize) void {
    readStruct(@as(*anyopaque, @ptrCast(dst)), PNP_REG_MEM24(idx), @sizeOf(Mem24Cfg));
    util.swapInPlace16(&dst.base);
    util.swapInPlace16(&dst.limitRange);
}

fn readIoWithByteswap(dst: *IoCfg, idx: usize) void {
    readStruct(@as(*anyopaque, @ptrCast(dst)), PNP_REG_IO(idx), @sizeOf(IoCfg));
    util.swapInPlace16(&dst.port);
}

fn readIrq(dst: *IrqCfg, idx: usize) void {
    readStruct(@as(*anyopaque, @ptrCast(dst)), PNP_REG_IRQ(idx), @sizeOf(IrqCfg));
}

fn readDma(dst: *DmaCfg, idx: usize) void {
    readStruct(@as(*anyopaque, @ptrCast(dst)), PNP_REG_DMA(idx), @sizeOf(DmaCfg));
}

fn writeIoWithByteswap(idx: usize, toWrite: *IoCfg) bool {
    var tmp = toWrite.*;
    util.swapInPlace16(&tmp.port);
    return writeStructVerify(&tmp, PNP_REG_IO(idx), @sizeOf(IoCfg));
}

fn writeIrq(idx: usize, toWrite: *IrqCfg) bool {
    return writeStructVerify(toWrite, PNP_REG_IRQ(idx), @sizeOf(IrqCfg));
}

fn writeDma(idx: usize, toWrite: *DmaCfg) bool {
    return writeStructVerify(toWrite, PNP_REG_DMA(idx), @sizeOf(DmaCfg));
}

fn logDevPopulateData(dst: *LogicalDeviceInfo) void {
    dst.active = readReg(PNP_REG_ACTIVATE);
    for (0..4) |j| readMem32WithByteswap(&dst.mem32[j], j);
    for (0..4) |j| readMem24WithByteswap(&dst.mem24[j], j);
    for (0..8) |j| readIoWithByteswap(&dst.io[j], j);
    for (0..2) |j| readIrq(&dst.irq[j], j);
    for (0..2) |j| readDma(&dst.dma[j], j);
}

fn populateDeviceInfo(device: *DeviceInfo, csn: u8, id: u32) void {
    device.* = std.mem.zeroes(DeviceInfo);
    device.csn = csn;
    device.eisaId.dword = id;
    decodeEisaId(device.eisaId, &device.idStr);
    device.numLogDevs = @truncate(populateResources(device));
    for (0..device.numLogDevs) |i| {
        if (!switchLogicalDevice(i)) break;
        logDevPopulateData(&device.logDev[i]);
    }
}

pub fn getDeviceData(devices: []DeviceInfo) usize {
    var numCards: usize = 0;
    var csn: u8 = 1;
    prepareEnumeration();
    while (numCards < devices.len and csn < 255) {
        const id = startDeviceEnumeration(csn);
        csn += 1;
        if (id == 0) break;
        populateDeviceInfo(&devices[numCards], csn - 1, id);
        numCards += 1;
        writeReg(PNP_REG_WAKE_CSN, 0x00);
    }
    writeReg(PNP_REG_CONFIG_CTRL, PNP_CTRL_WAIT_KEY);
    return numCards;
}

pub fn getDeviceDataByString(dst: *DeviceInfo, toFind: []const u8) bool {
    var csn: u8 = 1;
    prepareEnumeration();
    while (csn < 255) {
        var toCompare: [8]u8 = undefined;
        var id: CardId = undefined;
        id.dword = startDeviceEnumeration(csn);
        csn += 1;
        if (id.dword == 0) break;
        decodeEisaId(id, &toCompare);
        if (util.stringEquals(&toCompare, toFind)) {
            populateDeviceInfo(dst, csn - 1, id.dword);
            return true;
        }
        writeReg(PNP_REG_WAKE_CSN, 0x00);
    }
    writeReg(PNP_REG_CONFIG_CTRL, PNP_CTRL_WAIT_KEY);
    return false;
}

fn activateDeviceAndSetLogicalDevice(csn: u8, logDev: usize) bool {
    writeReg(PNP_REG_CONFIG_CTRL, PNP_CTRL_WAIT_KEY);
    sendInitKey();
    util.sleep(2);
    writeReg(PNP_REG_WAKE_CSN, csn);
    return switchLogicalDevice(logDev);
}

pub fn updateDeviceData(device: *DeviceInfo) bool {
    writeReg(PNP_REG_CONFIG_CTRL, PNP_CTRL_WAIT_KEY);
    sendInitKey();
    util.sleep(2);
    writeReg(PNP_REG_WAKE_CSN, device.csn);
    for (0..device.numLogDevs) |i| {
        if (!switchLogicalDevice(i)) break;
        logDevPopulateData(&device.logDev[i]);
    }
    return true;
}

pub fn getLogicalDevice(dst: *DeviceInfo, index: u16) ?*LogicalDeviceInfo {
    if (index >= dst.numLogDevs) return null;
    return &dst.logDev[@as(usize, @intCast(index))];
}

pub fn memRangeIsActive(ld: *LogicalDeviceInfo, index: u16) bool {
    if (ld.usesMem32) {
        return ld.mem32[@as(usize, @intCast(index))].base != 0;
    } else {
        return ld.mem24[@as(usize, @intCast(index))].base != 0;
    }
}

pub fn memRangeGetBase(ld: *LogicalDeviceInfo, index: u16) u32 {
    if (ld.usesMem32) {
        return ld.mem32[@as(usize, @intCast(index))].base;
    } else {
        return @as(u32, ld.mem24[@as(usize, @intCast(index))].base) << 8;
    }
}

pub fn memRangeGetEnd(ld: *LogicalDeviceInfo, index: u16) u32 {
    if (ld.usesMem32) {
        const m32 = &ld.mem32[@as(usize, @intCast(index))];
        return if (m32.isUpperLimit) m32.limitRange else m32.base + m32.limitRange;
    } else {
        const m24 = &ld.mem24[@as(usize, @intCast(index))];
        const base32 = @as(u32, m24.base) << 8;
        if (m24.isUpperLimit) {
            return @as(u32, m24.limitRange) << 8;
        } else {
            return (base32 + @as(u32, m24.limitRange)) << 8;
        }
    }
}

pub fn ioPortIsActive(ld: *LogicalDeviceInfo, index: u16) bool {
    return ld.io[@as(usize, @intCast(index))].port != 0;
}

pub fn ioPortGet(ld: *LogicalDeviceInfo, index: u16) u16 {
    return ld.io[@as(usize, @intCast(index))].port;
}

pub fn irqIsActive(ld: *LogicalDeviceInfo, index: u16) bool {
    return ld.irq[@as(usize, @intCast(index))].level != 0;
}

pub fn irqIsActiveHigh(ld: *LogicalDeviceInfo, index: u16) bool {
    return ld.irq[@as(usize, @intCast(index))].activeHigh != 0;
}

pub fn irqIsLevelTriggered(ld: *LogicalDeviceInfo, index: u16) bool {
    return ld.irq[@as(usize, @intCast(index))].triggerType != 0;
}

pub fn irqGet(ld: *LogicalDeviceInfo, index: u16) u8 {
    return ld.irq[@as(usize, @intCast(index))].level;
}

pub fn dmaIsActive(ld: *LogicalDeviceInfo, index: u16) bool {
    return ld.dma[@as(usize, @intCast(index))].ch != 4;
}

pub fn dmaGet(ld: *LogicalDeviceInfo, index: u16) u8 {
    return ld.dma[@as(usize, @intCast(index))].ch;
}

pub fn getCurrentValueByTypeAndIndex(ld: *LogicalDeviceInfo, @"type": SupportedValueType, index: u16, value: *u16) bool {
    switch (@"type") {
        .ioRange => {
            if (index >= PNP_MAX_IO_DESCRIPTORS) return false;
            value.* = ioPortGet(ld, index);
            return true;
        },
        .irq => {
            if (index >= PNP_MAX_IRQ_DESCRIPTORS) return false;
            value.* = irqGet(ld, index);
            return true;
        },
        .dma => {
            if (index >= PNP_MAX_DMA_DESCRIPTORS) return false;
            value.* = dmaGet(ld, index);
            return true;
        },
    }
}

pub fn setCurrentValueByTypeAndIndex(dev: *DeviceInfo, logDev: usize, @"type": SupportedValueType, index: u16, value: u16) bool {
    if (logDev >= dev.numLogDevs) return false;
    if (!activateDeviceAndSetLogicalDevice(dev.csn, logDev)) return false;
    switch (@"type") {
        .ioRange => {
            if (index >= PNP_MAX_IO_DESCRIPTORS) return false;
            var io: IoCfg = undefined;
            readIoWithByteswap(&io, @as(usize, @intCast(index)));
            io.port = value;
            return writeIoWithByteswap(@as(usize, @intCast(index)), &io);
        },
        .irq => {
            if (index >= PNP_MAX_IRQ_DESCRIPTORS) return false;
            if (value > 15) return false;
            var irq: IrqCfg = undefined;
            readIrq(&irq, @as(usize, @intCast(index)));
            irq.level = @truncate(value);
            return writeIrq(@as(usize, @intCast(index)), &irq);
        },
        .dma => {
            if (index >= PNP_MAX_DMA_DESCRIPTORS) return false;
            if (value > 7) return false;
            var dma: DmaCfg = undefined;
            readDma(&dma, @as(usize, @intCast(index)));
            dma.ch = @truncate(value);
            return writeDma(@as(usize, @intCast(index)), &dma);
        },
    }
}

pub fn setLogicalDeviceActive(dev: *DeviceInfo, logDev: usize, active: bool) bool {
    const value: u8 = if (active) 1 else 0;
    if (logDev >= dev.numLogDevs) return false;
    if (!activateDeviceAndSetLogicalDevice(dev.csn, logDev)) return false;
    return writeStructVerify(&value, PNP_REG_ACTIVATE, 1);
}

fn getResourceByIndex(rl: *ResourceList, index: usize) *Resource {
    return &rl.items.?[index];
}

fn getResourceCountByTag(rl: *ResourceList, isLarge: bool, @"type": u8) usize {
    var matches: usize = 0;
    for (0..rl.count) |i| {
        const cur = getResourceByIndex(rl, i);
        const curLarge = (cur.raw[0] >> 7) & 1 != 0;
        const curType = if (isLarge) cur.raw[0] & 0x7F else (cur.raw[0] >> 3) & 0x0F;
        if (isLarge and curLarge and curType == @"type") matches += 1;
        if (!isLarge and !curLarge and curType == @"type") matches += 1;
    }
    return matches;
}

fn getResourceByTag(rl: *ResourceList, isLarge: bool, @"type": u8, index: usize, totalCount: ?*usize) ?*Resource {
    if (totalCount) |tc| tc.* = getResourceCountByTag(rl, isLarge, @"type");
    var leftBeforeRet = index;
    for (0..rl.count) |i| {
        const cur = getResourceByIndex(rl, i);
        const curLarge = (cur.raw[0] >> 7) & 1 != 0;
        const curType = if (isLarge) cur.raw[0] & 0x7F else (cur.raw[0] >> 3) & 0x0F;
        if (isLarge and curLarge and curType == @"type") {
            if (leftBeforeRet == 0) return cur;
            leftBeforeRet -= 1;
        }
        if (!isLarge and !curLarge and curType == @"type") {
            if (leftBeforeRet == 0) return cur;
            leftBeforeRet -= 1;
        }
    }
    return null;
}

pub fn resIrq(rl: *ResourceList, index: usize, totalCount: ?*usize) ?*Resource {
    return getResourceByTag(rl, false, PNP_S_IRQ, index, totalCount);
}

pub fn resIoFixed(rl: *ResourceList, index: usize, totalCount: ?*usize) ?*Resource {
    return getResourceByTag(rl, false, PNP_S_IO_FIXED, index, totalCount);
}

pub fn resIoRange(rl: *ResourceList, index: usize, totalCount: ?*usize) ?*Resource {
    return getResourceByTag(rl, false, PNP_S_IO, index, totalCount);
}

pub fn resDma(rl: *ResourceList, index: usize, totalCount: ?*usize) ?*Resource {
    return getResourceByTag(rl, false, PNP_S_DMA, index, totalCount);
}

pub fn resString(rl: *ResourceList, buf: []u8) bool {
    const strRes = getResourceByTag(rl, true, PNP_L_ANSI_ID, 0, null) orelse return false;
    const len = @min(@as(usize, PNP_MAX_STRING_LENGTH), buf.len - 1);
    @memcpy(buf[0..len], strRes.raw[3 .. 3 + len]);
    buf[len] = 0;
    return true;
}

pub fn getSupportedIRQsFromDFs(dst: *util.DynU16, ld: *LogicalDeviceInfo, index: usize) bool {
    dst.count = 0;
    for (0..ld.dfList.count) |dfIdx| {
        const res = resIrq(&ld.dfList.funcs.?[dfIdx], index, null) orelse continue;
        var i: u16 = 0;
        while (i < 16) : (i += 1) {
            if (res.raw[1] & @as(u8, @truncate(util.BIT(i))) != 0) {
                if (!util.dynU16Add(dst, i)) return false;
            }
        }
    }
    util.dynU16Sort(dst);
    util.dynU16Deduplicate(dst);
    return true;
}

pub fn getSupportedIORangeBasesFromDFs(dst: *util.DynU16, ld: *LogicalDeviceInfo, index: usize) bool {
    dst.count = 0;
    for (0..ld.dfList.count) |dfIdx| {
        const res = resIoRange(&ld.dfList.funcs.?[dfIdx], index, null) orelse continue;
        const rangePtr = @as(*const ResIoRange, @ptrCast(&res.raw[1]));
        var base: u16 = rangePtr.baseMin;
        while (base <= rangePtr.baseMax) {
            if (!util.dynU16Add(dst, base)) return false;
            base += rangePtr.@"align";
        }
    }
    util.dynU16Sort(dst);
    util.dynU16Deduplicate(dst);
    return true;
}

pub fn getSupportedDMAsFromDFs(dst: *util.DynU16, ld: *LogicalDeviceInfo, index: usize) bool {
    dst.count = 0;
    for (0..ld.dfList.count) |dfIdx| {
        const res = resDma(&ld.dfList.funcs.?[dfIdx], index, null) orelse continue;
        var i: u16 = 0;
        while (i < 8) : (i += 1) {
            if (res.raw[1] & @as(u8, @truncate(util.BIT(i))) != 0) {
                if (!util.dynU16Add(dst, i)) return false;
            }
        }
    }
    util.dynU16Sort(dst);
    util.dynU16Deduplicate(dst);
    return true;
}

pub fn getSupportedResourceValuesFromDFsByType(dst: *util.DynU16, ld: *LogicalDeviceInfo, @"type": SupportedValueType, index: usize) bool {
    switch (@"type") {
        .ioRange => return getSupportedIORangeBasesFromDFs(dst, ld, index),
        .irq => return getSupportedIRQsFromDFs(dst, ld, index),
        .dma => return getSupportedDMAsFromDFs(dst, ld, index),
    }
}

fn PNP_REG_MEM24(x: usize) u8 {
    return PNP_REG_MEM24_0 + @as(u8, @truncate(8 * x));
}
fn PNP_REG_MEM32(x: usize) u8 {
    return if (x == 0) PNP_REG_MEM32_0 else @as(u8, @truncate(0x80 + 16 * x));
}
fn PNP_REG_IO(x: usize) u8 {
    return PNP_REG_IO0_HI + @as(u8, @truncate(2 * x));
}
fn PNP_REG_IRQ(x: usize) u8 {
    return PNP_REG_IRQ0_NUM + @as(u8, @truncate(2 * x));
}
fn PNP_REG_DMA(x: usize) u8 {
    return PNP_REG_DMA0 + @as(u8, @truncate(x));
}
