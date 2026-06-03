const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const cpu = @import("cpu.zig");
const sys = @import("sys.zig");

pub const K6WriteOrderMode = enum(u8) {
    all = 0,
    all_except_uc_wc = 1,
    none = 2,
    _count_,
};

pub const K6WriteAllocateConfig = extern struct {
    sizeKB: u32,
    memoryHole: bool,
};

pub const K6MemoryTypeRange = extern struct {
    isValid: bool,
    offset: u32,
    sizeKB: u32,
    writeCombine: bool,
    uncacheable: bool,
};

pub const K6MemoryTypeRangeRegs = extern struct {
    configs: [2]K6MemoryTypeRange,
};

pub const K6SetMulError = enum(u8) {
    ok = 0,
    badmul = 1,
    @"error" = 2,
};

const EFER: u32 = 0xC0000080;
const WHCR: u32 = 0xC0000082;
const UWCCR: u32 = 0xC0000085;
const EPMR: u32 = 0xC0000086;
const WATMCR: u32 = 0x00000085;
const WAPMRR: u32 = 0x00000086;
const HWCR: u32 = 0x00000083;
const BADMUL: u8 = 0xFF;

const multiplierValueTable = [_]u8{
    BADMUL, BADMUL,
    BADMUL, BADMUL,
    0x04,   BADMUL,
    0x05,   0x07,
    0x02,   0x00,
    0x01,   0x03,
    0x06,
};

const MAX_MULTIPLIER_INDEX = multiplierValueTable.len - 1;

fn isNewWHCRLayout() bool {
    const cpuid_val = cpu.getCPUIDVersionInfo();
    const family = @as(u16, cpuid_val.basic.family);
    const model = @as(u16, cpuid_val.basic.model);
    const stepping = @as(u16, cpuid_val.basic.stepping);
    return (family == 5 and model > 8) or
        (family == 5 and model == 8 and stepping >= 8);
}

fn isK6Family() bool {
    const cpuid_val = cpu.getCPUIDVersionInfo();
    return cpuid_val.basic.family == 5 and cpuid_val.basic.model >= 6;
}

fn isK5WithWriteAllocate() bool {
    const cpuid_val = cpu.getCPUIDVersionInfo();
    return cpuid_val.basic.family == 5 and cpuid_val.basic.model <= 3 and cpuid_val.basic.stepping >= 4;
}

pub fn enableEPMRIOBlock(enable: bool) bool {
    const epmrBase: u32 = 0x0000FFF0 | @as(u32, @intFromBool(enable));
    var msr = cpu.MSR{ .lo = epmrBase, .hi = 0 };
    return cpu.writeMSR(EPMR, &msr);
}

pub fn setMultiplier(whole: u16, fraction: u16) K6SetMulError {
    if ((fraction != 0 and fraction != 5) or whole > 6) return .badmul;
    const multiIndex = whole * 2 + fraction / 5;
    if (multiIndex > MAX_MULTIPLIER_INDEX) return .badmul;
    var multiplierValue: u32 = multiplierValueTable[multiIndex];
    if (multiplierValue == BADMUL) return .badmul;
    if (!enableEPMRIOBlock(true)) return .@"error";
    multiplierValue &= 0x00000007;
    multiplierValue <<= 5;
    multiplierValue |= 0x00001000;
    multiplierValue |= 0x00000200;
    sys.outPortL(0xFFF8, multiplierValue);
    return if (enableEPMRIOBlock(false)) .ok else .@"error";
}

pub fn setWriteOrderMode(mode: K6WriteOrderMode) bool {
    if (@intFromEnum(mode) >= @intFromEnum(K6WriteOrderMode._count_)) return false;
    const modeBits = (@as(u32, @intFromEnum(mode)) << 2) & 0x0000000C;
    var msr: cpu.MSR = undefined;
    var success = cpu.readMSR(EFER, &msr);
    msr.lo &= 0x000000F3;
    msr.lo |= modeBits;
    success = success and cpu.writeMSR(EFER, &msr);
    return success;
}

pub fn setWriteAllocateRange(config: *const K6WriteAllocateConfig) bool {
    return setWriteAllocateRangeValues(config.sizeKB, config.memoryHole);
}

fn setWriteAllocateK6_2(sizeKB: u32, memoryHole: bool) bool {
    var msr: cpu.MSR = undefined;
    msr.lo = (sizeKB * 1024) & 0xFFC00000;
    msr.lo |= @as(u32, @intFromBool(memoryHole)) << 16;
    msr.hi = 0;
    return cpu.writeMSRAndVerify(WHCR, &msr);
}

fn setWriteAllocateK6(sizeKB: u32, memoryHole: bool) bool {
    if (sizeKB > 508 * 1024) return false;
    var msr: cpu.MSR = undefined;
    msr.lo = ((sizeKB / 1024) / 4) << 1;
    msr.lo |= @as(u32, @intFromBool(memoryHole));
    msr.hi = 0;
    return cpu.writeMSRAndVerify(WHCR, &msr);
}

fn setWriteAllocateK5(sizeKB: u32, memoryHole: bool) bool {
    _ = sizeKB;
    _ = memoryHole;
    return false;
}

pub fn setWriteAllocateRangeValues(sizeKB: u32, memoryHole: bool) bool {
    if (isNewWHCRLayout()) return setWriteAllocateK6_2(sizeKB, memoryHole);
    if (isK6Family()) return setWriteAllocateK6(sizeKB, memoryHole);
    if (isK5WithWriteAllocate()) return setWriteAllocateK5(sizeKB, memoryHole);
    return false;
}

fn getWriteAllocateK6_2(config: *K6WriteAllocateConfig) bool {
    var msr: cpu.MSR = undefined;
    if (!cpu.readMSR(WHCR, &msr)) return false;
    config.sizeKB = (msr.lo & 0xFFC00000) / 1024;
    config.memoryHole = (msr.lo >> 5) & 1 != 0;
    return true;
}

fn getWriteAllocateK6(config: *K6WriteAllocateConfig) bool {
    var msr: cpu.MSR = undefined;
    if (!cpu.readMSR(WHCR, &msr)) return false;
    const blocks = (msr.lo & 0xFF) >> 1;
    config.sizeKB = blocks * 4 * 1024;
    config.memoryHole = (msr.lo & 0x01) != 0;
    return true;
}

fn getWriteAllocateK5(config: *K6WriteAllocateConfig) bool {
    var wapmrr: cpu.MSR = undefined;
    if (!cpu.readMSR(WAPMRR, &wapmrr)) return false;
    config.sizeKB = (((wapmrr.lo & 0xFFFF) | 0xFFFF) + 1) / 1024;
    config.memoryHole = false;
    return true;
}

pub fn getWriteAllocateRange(config: *K6WriteAllocateConfig) bool {
    if (isNewWHCRLayout()) return getWriteAllocateK6_2(config);
    if (isK6Family()) return getWriteAllocateK6(config);
    if (isK5WithWriteAllocate()) return getWriteAllocateK5(config);
    return false;
}

const MTRRMask = struct { mask: u32, sizeKB: u32 };

const mtrrMaskTable = [_]MTRRMask{
    .{ .mask = (0x7FFF << 0) & 0x7FFF, .sizeKB = 128 },
    .{ .mask = (0x7FFF << 1) & 0x7FFF, .sizeKB = 256 },
    .{ .mask = (0x7FFF << 2) & 0x7FFF, .sizeKB = 512 },
    .{ .mask = (0x7FFF << 3) & 0x7FFF, .sizeKB = 1024 },
    .{ .mask = (0x7FFF << 4) & 0x7FFF, .sizeKB = 2 * 1024 },
    .{ .mask = (0x7FFF << 5) & 0x7FFF, .sizeKB = 4 * 1024 },
    .{ .mask = (0x7FFF << 6) & 0x7FFF, .sizeKB = 8 * 1024 },
    .{ .mask = (0x7FFF << 7) & 0x7FFF, .sizeKB = 16 * 1024 },
    .{ .mask = (0x7FFF << 8) & 0x7FFF, .sizeKB = 32 * 1024 },
    .{ .mask = (0x7FFF << 9) & 0x7FFF, .sizeKB = 64 * 1024 },
    .{ .mask = (0x7FFF << 10) & 0x7FFF, .sizeKB = 128 * 1024 },
    .{ .mask = (0x7FFF << 11) & 0x7FFF, .sizeKB = 256 * 1024 },
    .{ .mask = (0x7FFF << 12) & 0x7FFF, .sizeKB = 512 * 1024 },
    .{ .mask = (0x7FFF << 13) & 0x7FFF, .sizeKB = 1024 * 1024 },
    .{ .mask = (0x7FFF << 14) & 0x7FFF, .sizeKB = 2 * 1024 * 1024 },
    .{ .mask = (0x7FFF << 15) & 0x7FFF, .sizeKB = 4 * 1024 * 1024 },
};

const MTRR_MASK_COUNT = mtrrMaskTable.len;

fn getBestMTTRMaskFromSizeKB(sizeKB: u32) u32 {
    for (mtrrMaskTable) |entry| {
        if (entry.sizeKB >= sizeKB) return entry.mask;
    }
    return 0;
}

fn getSizeKBFromMTRRMask(mask: u32, lengthOut: *u32) bool {
    for (mtrrMaskTable) |entry| {
        if (entry.mask == mask) {
            lengthOut.* = entry.sizeKB;
            return true;
        }
    }
    lengthOut.* = 0;
    return false;
}

fn decodeMTRRs(mtrr: *K6MemoryTypeRangeRegs, msr: *const cpu.MSR) void {
    mtrr.configs[0].offset = msr.lo & 0xFFFE0000;
    mtrr.configs[0].uncacheable = (msr.lo & 0x01) != 0;
    mtrr.configs[0].writeCombine = (msr.lo & 0x02) != 0;
    mtrr.configs[0].isValid = getSizeKBFromMTRRMask((msr.lo & 0x0001FFFC) >> 2, &mtrr.configs[0].sizeKB);
    mtrr.configs[0].isValid = mtrr.configs[0].isValid and (msr.lo != 0);

    mtrr.configs[1].offset = msr.hi & 0xFFFE0000;
    mtrr.configs[1].uncacheable = (msr.hi & 0x01) != 0;
    mtrr.configs[1].writeCombine = (msr.hi & 0x02) != 0;
    mtrr.configs[1].isValid = getSizeKBFromMTRRMask((msr.hi & 0x0001FFFC) >> 2, &mtrr.configs[1].sizeKB);
    mtrr.configs[1].isValid = mtrr.configs[1].isValid and (msr.hi != 0);
}

pub fn getMemoryTypeRanges(regs: *K6MemoryTypeRangeRegs) bool {
    var msr: cpu.MSR = undefined;
    if (!cpu.readMSR(UWCCR, &msr)) return false;
    decodeMTRRs(regs, &msr);
    return true;
}

fn encodeMTRRs(msr: *cpu.MSR, mtrr: *const K6MemoryTypeRangeRegs) void {
    msr.* = .{ .lo = 0, .hi = 0 };
    if (mtrr.configs[0].isValid) {
        msr.lo = (mtrr.configs[0].offset & 0xFFFE0000) |
            (getBestMTTRMaskFromSizeKB(mtrr.configs[0].sizeKB) << 2) |
            (@as(u32, @intFromBool(mtrr.configs[0].writeCombine)) << 1) |
            @as(u32, @intFromBool(mtrr.configs[0].uncacheable));
    }
    if (mtrr.configs[1].isValid) {
        msr.hi = (mtrr.configs[1].offset & 0xFFFE0000) |
            (getBestMTTRMaskFromSizeKB(mtrr.configs[1].sizeKB) << 2) |
            (@as(u32, @intFromBool(mtrr.configs[1].writeCombine)) << 1) |
            @as(u32, @intFromBool(mtrr.configs[1].uncacheable));
    }
}

pub fn setMemoryTypeRanges(regs: *const K6MemoryTypeRangeRegs) bool {
    var msr: cpu.MSR = undefined;
    encodeMTRRs(&msr, regs);
    return cpu.writeMSRAndVerify(UWCCR, &msr);
}

pub fn setL1Cache(enable: bool) bool {
    var cr0: u32 = undefined;
    var success = cpu.readControlRegister(0, &cr0);
    cr0 &= 0x9FFFFFFF;
    cr0 |= if (enable) 0 else 0x60000000;
    success = success and cpu.writeControlRegister(0, &cr0);
    return success;
}

pub fn setL2Cache(enable: bool) bool {
    var msr: cpu.MSR = undefined;
    var success = cpu.readMSR(EFER, &msr);
    msr.lo &= 0xFFFFFFEF;
    msr.lo |= if (enable) 0 else 0x00000010;
    success = success and cpu.writeMSR(EFER, &msr);
    return success;
}

pub fn getL1CacheStatus() bool {
    var cr0: u32 = 0;
    _ = cpu.readControlRegister(0, &cr0);
    return (cr0 & 0x40000000) == 0;
}

pub fn getL2CacheStatus() bool {
    var msr: cpu.MSR = undefined;
    _ = cpu.readMSR(EFER, &msr);
    return (msr.lo & 0x00000010) == 0;
}

pub fn setDataPrefetch(enable: bool) bool {
    var msr: cpu.MSR = undefined;
    var success = cpu.readMSR(EFER, &msr);
    msr.lo &= 0xFFFFFFFD;
    msr.lo |= if (enable) 0x00000002 else 0;
    success = success and cpu.writeMSR(EFER, &msr);
    return success;
}
