const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");
const sys = @import("sys.zig");

const dbg = debug.dbg;

pub const PCI_BUS_MAX = 255;
pub const PCI_SLOT_MAX = 31;
pub const PCI_FUNC_MAX = 7;
pub const PCI_BARS_MAX = 5;

pub const pci_HeaderType = enum(u32) {
    PCI_ENDPOINT = 0,
    PCI_PCI2PCI_BRIDGE = 1,
    PCI_PCI2CARDBUS_BRIDGE = 2,
    _,
};

pub const pci_BARType = enum(u32) {
    PCI_BAR_MEMORY = 0x00,
    PCI_BAR_IO = 0x01,
    _,
};

pub const pci_Class = enum(u32) {
    CLASS_UNCLASSIFIED = 0x00,
    CLASS_MASS_STORAGE = 0x01,
    CLASS_NETWORK = 0x02,
    CLASS_DISPLAY = 0x03,
    CLASS_MULTIMEDIA = 0x04,
    CLASS_MEMORY = 0x05,
    CLASS_BRIDGE = 0x06,
    CLASS_SIMPLE_COMMUNICATION = 0x07,
    CLASS_BASE_SYSTEM_PERIPHERAL = 0x08,
    CLASS_INPUT_DEVICES = 0x09,
    CLASS_DOCKING_STATIONS = 0x0A,
    CLASS_PROCESSORS = 0x0B,
    CLASS_SERIAL_BUS_CTRL = 0x0C,
    CLASS_WIRELESS_CTRL = 0x0D,
    CLASS_INTELLIGENT_CTRL = 0x0E,
    CLASS_SATELLITE_COMMUNICATION = 0x0F,
    CLASS_ENCRYPTION_CTRL = 0x10,
    CLASS_SIGNAL_PROCESSING_CTRL = 0x11,
    CLASS_RESERVED = 0xFF,
    _,
};

pub const pci_Device = extern struct {
    bus: u8,
    slot: u8,
    func: u8,
    dummy: u8,
};

pub const pci_BARInfo = extern struct {
    address: u32,
    type: pci_BARType,
    prefetchable: bool,
    size: u32,
};

pub const pci_DeviceInfo = extern struct {
    vendor: u16,
    device: u16,
    subVendor: u16,
    subDevice: u16,
    isMultiFunction: bool,
    classCode: pci_Class,
    subClass: u8,
    progIF: u8,
    revision: u8,
    headerType: pci_HeaderType,
    expansionRomPtr: u32,
    bars: [6]pci_BARInfo,
};

pub fn pci_makeAddress(device: pci_Device, offset: u32) u32 {
    return (@as(u32, 1) << @as(u5, @intCast(31))) |
        (@as(u32, device.bus) << @as(u5, @intCast(16))) |
        (@as(u32, device.slot) << @as(u5, @intCast(11))) |
        (@as(u32, device.func) << @as(u5, @intCast(8))) |
        (offset & 0xFC);
}

pub fn pci_read32(device: pci_Device, offset: u32) u32 {
    const address = pci_makeAddress(device, offset & 0xFC);
    sys.outPortL(0xCF8, address);
    return sys.inPortL(0xCFC);
}

pub fn pci_read16(device: pci_Device, offset: u32) u16 {
    const val = pci_read32(device, offset & 0xFC);
    const shift = @as(u5, @intCast((offset & 2) * 8));
    return @as(u16, @truncate((val >> shift) & 0xFFFF));
}

pub fn pci_read8(device: pci_Device, offset: u32) u8 {
    const val = pci_read32(device, offset & 0xFC);
    const shift = @as(u5, @intCast((offset & 3) * 8));
    return @as(u8, @truncate((val >> shift) & 0xFF));
}

pub fn pci_readBytes(device: pci_Device, buffer: *anyopaque, offset: u32, count: u32) void {
    const buf = @as([*]u8, @ptrCast(buffer));
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        buf[i] = pci_read8(device, offset + i);
    }
}

pub fn pci_write32(device: pci_Device, offset: u32, value: u32) void {
    const address = pci_makeAddress(device, offset & 0xFC);
    sys.outPortL(0xCF8, address);
    sys.outPortL(0xCFC, value);
}

pub fn pci_write16(device: pci_Device, offset: u32, value: u16) void {
    const aligned = pci_read32(device, offset & 0xFC);
    const shift = @as(u5, @intCast((offset & 2) * 8));
    const mask = @as(u32, 0xFFFF) << shift;
    const new_val = (aligned & ~mask) | (@as(u32, value) << shift);
    pci_write32(device, offset & 0xFC, new_val);
}

pub fn pci_write8(device: pci_Device, offset: u32, value: u8) void {
    const aligned = pci_read32(device, offset & 0xFC);
    const shift = @as(u5, @intCast((offset & 3) * 8));
    const mask = @as(u32, 0xFF) << shift;
    const new_val = (aligned & ~mask) | (@as(u32, value) << shift);
    pci_write32(device, offset & 0xFC, new_val);
}

pub fn pci_writeBytes(device: pci_Device, buffer: *const anyopaque, offset: u32, count: u32) void {
    const buf = @as([*]const u8, @ptrCast(buffer));
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        pci_write8(device, offset + i, buf[i]);
    }
}

pub fn pci_getVendorID(device: pci_Device) u16 {
    return pci_read16(device, 0);
}

pub fn pci_getDeviceID(device: pci_Device) u16 {
    return pci_read16(device, 2);
}

pub fn pci_getClass(device: pci_Device) pci_Class {
    const val = pci_read32(device, 0x08);
    return @as(pci_Class, @enumFromInt((val >> 24) & 0xFF));
}

pub fn pci_getSubClass(device: pci_Device) u8 {
    const val = pci_read32(device, 0x08);
    return @as(u8, @truncate((val >> 16) & 0xFF));
}

pub fn pci_findDevByID(ven: u16, dev: u16, device: *pci_Device) bool {
    var iter = pci_Device{
        .bus = 0,
        .slot = 0,
        .func = 0,
        .dummy = 0,
    };

    while (iter.bus <= PCI_BUS_MAX) {
        while (iter.slot <= PCI_SLOT_MAX) {
            while (iter.func <= PCI_FUNC_MAX) {
                const vendor = pci_getVendorID(iter);
                if (vendor == ven) {
                    const devID = pci_getDeviceID(iter);
                    if (devID == dev) {
                        device.* = iter;
                        return true;
                    }
                }
                iter.func += 1;
            }
            iter.func = 0;
            iter.slot += 1;
        }
        iter.slot = 0;
        if (iter.bus == PCI_BUS_MAX) break;
        iter.bus += 1;
    }

    return false;
}

pub fn pci_getNextDevice(allocator: std.mem.Allocator, device: ?*const pci_Device) ?*pci_Device {
    var bus: u8 = 0;
    var slot: u8 = 0;
    var func: u8 = 0;

    if (device) |dev| {
        bus = dev.bus;
        slot = dev.slot;
        func = dev.func + 1;
    }

    while (bus <= PCI_BUS_MAX) {
        while (slot <= PCI_SLOT_MAX) {
            while (func <= PCI_FUNC_MAX) {
                const cur = pci_Device{
                    .bus = bus,
                    .slot = slot,
                    .func = func,
                    .dummy = 0,
                };

                if (pci_getVendorID(cur) != 0xFFFF) {
                    const htype = pci_read8(cur, 0x0E);
                    if (func == 0 and (htype & 0x80) == 0) {
                        func = PCI_FUNC_MAX;
                        continue;
                    }

                    const result = allocator.create(pci_Device) catch return null;
                    result.* = cur;
                    return result;
                }

                func += 1;
            }
            func = 0;
            slot += 1;
        }
        slot = 0;
        if (bus == PCI_BUS_MAX) break;
        bus += 1;
    }

    return null;
}

pub fn pci_populateDeviceInfo(info: *pci_DeviceInfo, device: pci_Device) bool {
    const ven = pci_read32(device, 0);
    if (ven == 0xFFFFFFFF) {
        return false;
    }

    info.vendor = @as(u16, @truncate(ven & 0xFFFF));
    info.device = @as(u16, @truncate((ven >> 16) & 0xFFFF));

    const cc = pci_read32(device, 0x08);
    info.revision = @as(u8, @truncate(cc & 0xFF));
    info.progIF = @as(u8, @truncate((cc >> 8) & 0xFF));
    info.subClass = @as(u8, @truncate((cc >> 16) & 0xFF));
    info.classCode = @as(pci_Class, @enumFromInt((cc >> 24) & 0xFF));

    const htype_raw = pci_read8(device, 0x0E);
    info.headerType = @as(pci_HeaderType, @enumFromInt(htype_raw & 0x7F));
    info.isMultiFunction = (htype_raw & 0x80) != 0;

    const sub = pci_read32(device, 0x2C);
    info.subVendor = @as(u16, @truncate(sub & 0xFFFF));
    info.subDevice = @as(u16, @truncate((sub >> 16) & 0xFFFF));

    info.expansionRomPtr = pci_read32(device, 0x30);

    var bar_idx: u5 = 0;
    while (bar_idx < 6) : (bar_idx += 1) {
        const bar_off = @as(u32, 0x10) + @as(u32, bar_idx) * 4;
        const bar_val = pci_read32(device, bar_off);
        info.bars[bar_idx].address = bar_val;

        if ((bar_val & 1) != 0) {
            info.bars[bar_idx].type = .PCI_BAR_IO;
            info.bars[bar_idx].prefetchable = false;

            pci_write32(device, bar_off, 0xFFFFFFFF);
            const size_raw = pci_read32(device, bar_off);
            pci_write32(device, bar_off, bar_val);

            info.bars[bar_idx].size = (~(size_raw & 0xFFFFFFFC)) +% 1;
        } else {
            info.bars[bar_idx].type = .PCI_BAR_MEMORY;
            info.bars[bar_idx].prefetchable = (bar_val & @as(u32, 0x08)) != 0;

            pci_write32(device, bar_off, 0xFFFFFFFF);
            const size_raw = pci_read32(device, bar_off);
            pci_write32(device, bar_off, bar_val);

            info.bars[bar_idx].size = (~(size_raw & 0xFFFFFFF0)) +% 1;

            const bar_type = (bar_val >> 1) & 0x03;
            if (bar_type == 0x02) {
                if (bar_idx < 5) {
                    bar_idx += 1;
                    const hi_off = @as(u32, 0x10) + @as(u32, bar_idx) * 4;
                    info.bars[bar_idx].address = pci_read32(device, hi_off);
                    info.bars[bar_idx].type = .PCI_BAR_MEMORY;
                    info.bars[bar_idx].prefetchable = false;
                    info.bars[bar_idx].size = 0;
                }
            }
        }
    }

    return true;
}

pub fn pci_debugInfo(device: pci_Device) void {
    dbg("PCI Device {d}:{d}:{d}", .{ device.bus, device.slot, device.func });
    dbg("  Vendor: 0x{x:04} Device: 0x{x:04} Class: 0x{x:02} SubClass: 0x{x:02}", .{
        pci_getVendorID(device),
        pci_getDeviceID(device),
        @as(u8, @intFromEnum(pci_getClass(device))),
        pci_getSubClass(device),
    });
}

pub fn pci_test() bool {
    const test_dev = pci_Device{
        .bus = 0,
        .slot = 0,
        .func = 0,
        .dummy = 0,
    };

    const vendor = pci_getVendorID(test_dev);
    if (vendor == 0xFFFF or vendor == 0) {
        dbg("PCI test: no PCI config space accessible (vendor=0x{x:04})", .{vendor});
        return false;
    }

    dbg("PCI test: PCI config space accessible, vendor at 0:0:0 = 0x{x:04}", .{vendor});
    return true;
}
