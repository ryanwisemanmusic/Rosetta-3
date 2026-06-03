const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const sys = @import("sys.zig");

pub const MSR = extern struct {
    lo: u32,
    hi: u32,
};

pub const CPUIDVersionInfo = extern struct {
    basic: packed struct(u16) {
        stepping: u4,
        model: u4,
        family: u4,
        type: u2,
        __rsvd__: u2,
    },
    extended: packed struct(u16) {
        model: u4,
        family: u8,
        __rsvd__: u4,
    },
};

pub const Manufacturer = enum(u8) {
    amd = 0,
    idt,
    cyrix,
    intel,
    transmeta,
    natsemi,
    nexgen,
    rise,
    sis,
    umc,
    dmp,
    zhaoxin,
    hygon,
    rdc,
    mcst,
    via,
    amdk5es,
    mister,
    microsoft,
    apple,
    unknown,
    _count_,
};

const MfrLookupEntry = struct {
    cpuidStr: [13:0]u8,
    mfr: Manufacturer,
    clearName: []const u8,
};

fn asCpuId(s: *const [13:0]u8) [13:0]u8 {
    return s.*;
}

const manufacturerTable = [_]MfrLookupEntry{
    .{ .cpuidStr = asCpuId("AuthenticAMD"), .mfr = .amd, .clearName = "AMD" },
    .{ .cpuidStr = asCpuId("CentaurHauls"), .mfr = .idt, .clearName = "IDT/Centaur" },
    .{ .cpuidStr = asCpuId("CyrixInstead"), .mfr = .cyrix, .clearName = "Cyrix/STM/IBM" },
    .{ .cpuidStr = asCpuId("GenuineIntel"), .mfr = .intel, .clearName = "Intel" },
    .{ .cpuidStr = asCpuId("GenuineIotel"), .mfr = .intel, .clearName = "Intel" },
    .{ .cpuidStr = asCpuId("TransmetaCPU"), .mfr = .transmeta, .clearName = "Transmeta" },
    .{ .cpuidStr = asCpuId("GenuineTMx86"), .mfr = .transmeta, .clearName = "Transmeta" },
    .{ .cpuidStr = asCpuId("Geode by NSC"), .mfr = .natsemi, .clearName = "National Semiconductor" },
    .{ .cpuidStr = asCpuId("NexGenDriven"), .mfr = .nexgen, .clearName = "NexGen" },
    .{ .cpuidStr = asCpuId("RiseRiseRise"), .mfr = .rise, .clearName = "Rise" },
    .{ .cpuidStr = asCpuId("SiS SiS SiS "), .mfr = .sis, .clearName = "SiS" },
    .{ .cpuidStr = asCpuId("UMC UMC UMC "), .mfr = .umc, .clearName = "UMC" },
    .{ .cpuidStr = asCpuId("Vortex86 SoC"), .mfr = .dmp, .clearName = "DM&P" },
    .{ .cpuidStr = asCpuId("  Shanghai  "), .mfr = .zhaoxin, .clearName = "Zaoxin" },
    .{ .cpuidStr = asCpuId("HygonGenuine"), .mfr = .hygon, .clearName = "Hygon" },
    .{ .cpuidStr = asCpuId("Genuine  RDC"), .mfr = .rdc, .clearName = "RDC" },
    .{ .cpuidStr = asCpuId("E2K MACHINE "), .mfr = .mcst, .clearName = "MCST Elbrus" },
    .{ .cpuidStr = asCpuId("VIA VIA VIA "), .mfr = .via, .clearName = "VIA" },
    .{ .cpuidStr = asCpuId("AMD ISBETTER"), .mfr = .amdk5es, .clearName = "AMD (K5 ES)" },
    .{ .cpuidStr = asCpuId("GenuineAO486"), .mfr = .mister, .clearName = "MiSTer ao486" },
    .{ .cpuidStr = asCpuId("MiSTer AO486"), .mfr = .mister, .clearName = "MiSTer ao486" },
    .{ .cpuidStr = asCpuId("MicrosoftXTA"), .mfr = .microsoft, .clearName = "Microsoft" },
    .{ .cpuidStr = asCpuId("VirtualApple"), .mfr = .apple, .clearName = "Apple" },
    .{ .cpuidStr = asCpuId("            "), .mfr = .unknown, .clearName = "Unknown" },
};

pub fn getCPUIDString(outStr: []u8) bool {
    _ = outStr;
    return false;
}

pub fn getCPUIDVersionInfo() CPUIDVersionInfo {
    return undefined;
}

pub fn getManufacturer(mfrClearName: ?*?[]const u8) Manufacturer {
    _ = mfrClearName;
    return .unknown;
}

pub fn readMSR(msrId: u32, msr: *MSR) bool {
    _ = msrId;
    _ = msr;
    return false;
}

pub fn writeMSR(msrId: u32, msr: *const MSR) bool {
    _ = msrId;
    _ = msr;
    return false;
}

pub fn writeMSRAndVerify(msrId: u32, msr: *const MSR) bool {
    return writeMSR(msrId, msr);
}

pub fn readControlRegister(index: u8, out: *u32) bool {
    _ = index;
    _ = out;
    return false;
}

pub fn writeControlRegister(index: u8, in_val: *const u32) bool {
    _ = index;
    _ = in_val;
    return false;
}

pub fn isInV86Mode() bool {
    return false;
}
