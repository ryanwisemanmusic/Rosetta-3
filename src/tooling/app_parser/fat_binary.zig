const std = @import("std");

pub const FAT_MAGIC: u32 = 0xCAFEBABE;
pub const FAT_CIGAM: u32 = 0xBEBAFECA;
pub const FAT_MAGIC_64: u32 = 0xCAFEBABF;
pub const FAT_CIGAM_64: u32 = 0xBFBAFECA;

pub const FatArch = packed struct {
    cputype: u32,
    cpusubtype: u32,
    offset: u32,
    size: u32,
    alignment: u32,
};

pub const FatArch64 = packed struct {
    cputype: u32,
    cpusubtype: u32,
    offset: u64,
    size: u64,
    alignment: u32,
    reserved: u32,
};

pub const FatHeader = packed struct {
    magic: u32,
    narchives: u32,
};

pub const Slice = struct {
    cputype: u32,
    cpusubtype: u32,
    offset: u64,
    size: u64,
    data: []const u8,
};

pub const UniversalBinary = struct {
    is_64: bool,
    slices: []Slice,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *UniversalBinary) void {
        self.allocator.free(self.slices);
    }

    pub fn getSlice(self: UniversalBinary, cputype: u32) ?Slice {
        for (self.slices) |s| {
            if (s.cputype == cputype) return s;
        }
        return null;
    }

    pub fn has32BitSlice(self: UniversalBinary) bool {
        for (self.slices) |s| {
            if (s.cputype == macho_parser.CPU_TYPE_I386) return true;
        }
        return false;
    }

    pub fn needsExtraction(self: UniversalBinary) bool {
        if (!self.has32BitSlice()) return false;
        return self.getSlice(macho_parser.CPU_TYPE_ARM64) == null;
    }
};

const macho_parser = @import("macho_parser.zig");

pub fn parseFatBinary(allocator: std.mem.Allocator, data: []const u8) !UniversalBinary {
    if (data.len < 8) return error.TruncatedFatBinary;
    const magic = std.mem.readInt(u32, data[0..4], .big);
    const is_64 = magic == FAT_MAGIC_64 or magic == FAT_CIGAM_64;
    const is_fat = magic == FAT_MAGIC or magic == FAT_CIGAM or is_64;
    if (!is_fat) return error.NotFatBinary;

    const endian: std.builtin.Endian = if (magic == FAT_MAGIC or magic == FAT_MAGIC_64) .big else .little;
    const narchives_val = std.mem.readInt(u32, data[4..8], endian);
    if (narchives_val > 128) return error.TooManyArchitectures;

    var slices: std.ArrayList(Slice) = .empty;
    errdefer slices.deinit(allocator);

    var pos: usize = 8;
    const arch_size: usize = if (is_64) @sizeOf(FatArch64) else 5 * @sizeOf(u32);

    for (0..narchives_val) |_| {
        if (pos + arch_size > data.len) break;
        if (is_64) {
            const cpu = std.mem.readInt(u32, data[pos + 0 ..][0..4], endian);
            const sub = std.mem.readInt(u32, data[pos + 4 ..][0..4], endian);
            const offset = std.mem.readInt(u64, data[pos + 8 ..][0..8], endian);
            const size = std.mem.readInt(u64, data[pos + 16 ..][0..8], endian);
            if (offset + size <= data.len) {
                try slices.append(allocator, .{
                    .cputype = cpu,
                    .cpusubtype = sub,
                    .offset = offset,
                    .size = size,
                    .data = data[offset .. offset + size],
                });
            }
            pos += arch_size;
        } else {
            const cpu = std.mem.readInt(u32, data[pos + 0 ..][0..4], endian);
            const sub = std.mem.readInt(u32, data[pos + 4 ..][0..4], endian);
            const offset = std.mem.readInt(u32, data[pos + 8 ..][0..4], endian);
            const size = std.mem.readInt(u32, data[pos + 12 ..][0..4], endian);
            if (offset + size <= data.len) {
                try slices.append(allocator, .{
                    .cputype = cpu,
                    .cpusubtype = sub,
                    .offset = offset,
                    .size = size,
                    .data = data[offset .. offset + size],
                });
            }
            pos += arch_size;
        }
    }

    return UniversalBinary{
        .is_64 = is_64,
        .slices = try slices.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

test "parse fat binary with i386 + x86_64" {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(std.testing.allocator);
    const W = std.testing.allocator;
    try buf.appendSlice(W, &[_]u8{ 0xBE, 0xBA, 0xFE, 0xCA }); // FAT_CIGAM (little endian)
    try buf.appendSlice(W, &[_]u8{ 2, 0, 0, 0 }); // narchives = 2
    try buf.appendSlice(W, &[_]u8{ 7, 0, 0, 0 }); // cputype = i386
    try buf.appendSlice(W, &[_]u8{ 3, 0, 0, 0 }); // cpusubtype = 3
    try buf.appendSlice(W, &[_]u8{ 48, 0, 0, 0 }); // offset = 48
    try buf.appendSlice(W, &[_]u8{ 4, 0, 0, 0 }); // size = 4
    try buf.appendSlice(W, &[_]u8{ 0, 0, 0, 0 }); // alignment = 0
    try buf.appendSlice(W, &[_]u8{ 7, 0, 0, 1 }); // cputype = x86_64 (CPU_TYPE_X86_64 = 0x01000007)
    try buf.appendSlice(W, &[_]u8{ 3, 0, 0, 0 }); // cpusubtype = 3
    try buf.appendSlice(W, &[_]u8{ 52, 0, 0, 0 }); // offset = 52
    try buf.appendSlice(W, &[_]u8{ 4, 0, 0, 0 }); // size = 4
    try buf.appendSlice(W, &[_]u8{ 0, 0, 0, 0 }); // alignment = 0
    try buf.appendSlice(W, &[_]u8{ 0xFE, 0xED, 0xFA, 0xCE }); // MH_MAGIC (i386 slice)
    try buf.appendSlice(W, &[_]u8{ 0xFE, 0xED, 0xFA, 0xCF }); // MH_MAGIC_64 (x86_64 slice)

    var ub = try parseFatBinary(std.testing.allocator, buf.items);
    defer ub.deinit();
    try std.testing.expectEqual(@as(usize, 2), ub.slices.len);
    try std.testing.expectEqual(macho_parser.CPU_TYPE_I386, ub.slices[0].cputype);
    try std.testing.expectEqual(macho_parser.CPU_TYPE_X86_64, ub.slices[1].cputype);
    try std.testing.expect(ub.has32BitSlice());
    try std.testing.expect(ub.needsExtraction()); // no arm64 slice, so extraction needed
}

test "reject non-fat" {
    const data = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0 };
    const result = parseFatBinary(std.testing.allocator, &data);
    try std.testing.expectError(error.NotFatBinary, result);
}
