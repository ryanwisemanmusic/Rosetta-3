const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");

pub const DMABuffer = struct {
    aligned: ?*anyopaque,
    alignedSize: u16,
    rawPtr: ?*anyopaque,
    rawSize: u32,
};

pub const OsWindowsMode = enum(u8) {
    pure_dos = 0,
    win_real_mode = 1,
    win_standard_mode = 2,
    win_enhanced_mode = 3,
    win_95 = 4,
    win_98 = 5,
    win_me = 6,
    unknown = 7,
    _count_,
};

pub const ISR = *const fn () callconv(.C) void;

const E820MemBlock = extern struct {
    base_low: u32,
    base_high: u32,
    length_low: u32,
    length_high: u32,
    type_field: u32,
    acpi: u32,
};

fn swapE820Entries(a: *E820MemBlock, b: *E820MemBlock) void {
    const tmp = a.*;
    a.* = b.*;
    b.* = tmp;
}

fn sortE820Entries(regions: []E820MemBlock) void {
    for (0..regions.len) |i| {
        for (i + 1..regions.len) |j| {
            if (regions[i].base_low > regions[j].base_low) {
                swapE820Entries(&regions[i], &regions[j]);
            }
        }
    }
}

fn fixE820Overlaps(regions: []E820MemBlock) void {
    for (0..regions.len - 1) |i| {
        const end = regions[i].base_low +% regions[i].length_low;
        if (end > regions[i + 1].base_low) {
            regions[i].length_low = regions[i + 1].base_low - regions[i].base_low;
        }
    }
}

fn getSortedInt15E820MemoryMap(allocator: std.mem.Allocator) ![]E820MemBlock {
    _ = allocator;
    return error.E820Failed;
}

fn getMemorySizeInt15E820Method(hasMemoryHole: ?*bool, allocator: std.mem.Allocator) u32 {
    var found_15m_hole = false;
    var result: u32 = 0;
    const regions = getSortedInt15E820MemoryMap(allocator) catch return 0;
    defer allocator.free(regions);

    for (regions, 0..) |region, i| {
        if (region.base_low >= 1 * 1024 * 1024) {
            if (i > 0) {
                const prev_end = regions[i - 1].base_low +% regions[i - 1].length_low;
                if (prev_end < region.base_low) {
                    const hole_addr = prev_end;
                    const hole_size = region.base_low - hole_addr;
                    if (hole_addr == 15 * 1024 * 1024 and hole_size == 1 * 1024 * 1024) {
                        found_15m_hole = true;
                        result +%= hole_size;
                        continue;
                    } else {
                        break;
                    }
                }
            }
            if (region.type == 2 and region.base_low == 15 * 1024 * 1024 and region.length_low == 1 * 1024 * 1024) {
                found_15m_hole = true;
            }
            result +%= region.length_low;
        }
    }

    if (result != 0) result +%= 1 * 1024 * 1024;

    if (hasMemoryHole) |hole| hole.* = found_15m_hole;
    return result;
}

fn getMemorySizeInt15E801Method(hasMemoryHole: ?*bool) u32 {
    _ = hasMemoryHole;
    return 0;
}

pub fn getMemorySize(hasMemoryHole: ?*bool, allocator: std.mem.Allocator) u32 {
    var result = getMemorySizeInt15E820Method(hasMemoryHole, allocator);
    if (result == 0) {
        result = getMemorySizeInt15E801Method(hasMemoryHole);
    }
    return result;
}

pub fn getPhysicalAddress(ptr: *const anyopaque) u32 {
    return @intCast(@intFromPtr(ptr));
}

pub fn outPortL(port: u16, outVal: u32) void {
    _ = port;
    _ = outVal;
}

pub fn inPortL(port: u16) u32 {
    _ = port;
    return 0;
}

pub fn ioDelay(loops: u16) void {
    var remaining = loops;
    while (remaining > 0) {
        asm volatile ("nop");
        remaining -= 1;
    }
}

pub fn getWindowsMode() OsWindowsMode {
    return .pure_dos;
}

pub fn allocateDMABuffer(buf: *DMABuffer, size: u32, allocator: std.mem.Allocator) bool {
    debug.nullcheck(buf);
    if (size > 0x10000) return false;

    const rawSize = size << 1;
    const raw = allocator.allocAdvanced(u8, 1, rawSize, .exact) catch return false;

    const rawPhys = getPhysicalAddress(raw.ptr);
    const pageEnd = (rawPhys & 0xFFFF0000) +% 0x10000;

    const alignedPhys = if (rawPhys +% size <= pageEnd) rawPhys else pageEnd;
    const alignedSegment = @as(u16, @intCast(alignedPhys >> 4));
    const alignedOffset = @as(u16, @intCast(alignedPhys & 0xF));

    buf.aligned = @as(*anyopaque, @ptrFromInt((@as(u32, alignedSegment) << 4) + alignedOffset));
    buf.alignedSize = @as(u16, @intCast(size));
    buf.rawPtr = raw.ptr;
    buf.rawSize = rawSize;

    return true;
}

pub fn freeDMABuffer(buf: *DMABuffer, allocator: std.mem.Allocator) void {
    debug.nullcheck(buf);
    if (buf.rawPtr) |raw| {
        allocator.free(@as([*]u8, @ptrCast(raw))[0..buf.rawSize]);
        buf.rawPtr = null;
        buf.aligned = null;
        buf.alignedSize = 0;
        buf.rawSize = 0;
    }
}

pub fn driveIsRemote(letter: u8) bool {
    _ = letter;
    return false;
}
