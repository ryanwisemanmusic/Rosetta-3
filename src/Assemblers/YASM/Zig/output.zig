const std = @import("std");
const yasm = @import("yasm_core.zig");

pub const ArtifactKind = enum {
    empty,
    flat_binary,
    elf32,
    elf64,
    macho32,
    macho64,
    coff,
    unknown,
};

pub const ArtifactInfo = struct {
    kind: ArtifactKind,
    machine: u16 = 0,
    bits: u8 = 0,
    little_endian: bool = true,
};

pub fn inspectArtifact(bytes: []const u8) ArtifactInfo {
    if (bytes.len == 0) return .{ .kind = .empty };
    if (bytes.len >= 20 and std.mem.eql(u8, bytes[0..4], "\x7fELF")) {
        const class = bytes[4];
        const data = bytes[5];
        const machine = readU16(bytes[18..20], data == 1);
        return .{
            .kind = if (class == 2) .elf64 else .elf32,
            .machine = machine,
            .bits = if (class == 2) 64 else 32,
            .little_endian = data == 1,
        };
    }
    if (bytes.len >= 4) {
        const magic_le = readU32(bytes[0..4], true);
        const magic_be = readU32(bytes[0..4], false);
        if (magic_le == 0xfeedfacf or magic_be == 0xfeedfacf) return .{ .kind = .macho64, .bits = 64 };
        if (magic_le == 0xfeedface or magic_be == 0xfeedface) return .{ .kind = .macho32, .bits = 32 };
        if (bytes.len >= 20) {
            const machine = readU16(bytes[0..2], true);
            const sections = readU16(bytes[2..4], true);
            if ((machine == 0x014c or machine == 0x8664) and sections > 0) {
                return .{ .kind = .coff, .machine = machine, .bits = if (machine == 0x8664) 64 else 32 };
            }
        }
    }
    return .{ .kind = .flat_binary };
}

pub fn validateForFormat(format: yasm.OutputFormat, bytes: []const u8) bool {
    const info = inspectArtifact(bytes);
    return switch (format) {
        .bin => info.kind == .flat_binary or info.kind == .empty,
        .dbg => info.kind != .unknown,
        .elf32, .elfx32 => info.kind == .elf32,
        .elf64 => info.kind == .elf64 and info.machine == 0x3e,
        .macho32 => info.kind == .macho32,
        .macho64 => info.kind == .macho64,
        .coff, .win32 => info.kind == .coff and info.bits == 32,
        .win64 => info.kind == .coff and info.bits == 64,
        .rdf, .xdf => info.kind != .unknown,
    };
}

pub fn emitPlaceholderObject(allocator: std.mem.Allocator, format: yasm.OutputFormat) ![]u8 {
    if (format == .elf64) {
        var bytes = try allocator.alloc(u8, 64);
        @memset(bytes, 0);
        bytes[0] = 0x7f;
        bytes[1] = 'E';
        bytes[2] = 'L';
        bytes[3] = 'F';
        bytes[4] = 2;
        bytes[5] = 1;
        bytes[6] = 1;
        bytes[16] = 1;
        bytes[18] = 0x3e;
        bytes[20] = 1;
        return bytes;
    }
    return try allocator.dupe(u8, "");
}

fn readU16(bytes: []const u8, little: bool) u16 {
    if (little) return @as(u16, bytes[0]) | (@as(u16, bytes[1]) << 8);
    return (@as(u16, bytes[0]) << 8) | @as(u16, bytes[1]);
}

fn readU32(bytes: []const u8, little: bool) u32 {
    if (little) {
        return @as(u32, bytes[0]) |
            (@as(u32, bytes[1]) << 8) |
            (@as(u32, bytes[2]) << 16) |
            (@as(u32, bytes[3]) << 24);
    }
    return (@as(u32, bytes[0]) << 24) |
        (@as(u32, bytes[1]) << 16) |
        (@as(u32, bytes[2]) << 8) |
        @as(u32, bytes[3]);
}

test "inspect generated elf64 placeholder" {
    const bytes = try emitPlaceholderObject(std.testing.allocator, .elf64);
    defer std.testing.allocator.free(bytes);
    const info = inspectArtifact(bytes);
    try std.testing.expectEqual(ArtifactKind.elf64, info.kind);
    try std.testing.expect(validateForFormat(.elf64, bytes));
}
