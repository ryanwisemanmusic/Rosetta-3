const std = @import("std");
const fmt = @import("pe_format.zig");

pub const Section = struct {
    name: [8]u8,
    virtual_size: u32,
    virtual_address: u32,
    raw_size: u32,
    raw_offset: u32,
    characteristics: u32,
};

pub const Image = struct {
    machine: u16,
    entry_rva: u32,
    image_base: u64,
    section_alignment: u32,
    file_alignment: u32,
    size_of_image: u32,
    size_of_headers: u32,
    number_of_sections: u16,
    sections: []Section,
};

pub const ParseError = error{
    FileTooSmall,
    InvalidDosSignature,
    InvalidPeSignature,
    UnsupportedOptionalHeader,
    TruncatedSectionTable,
    OutOfMemory,
};

fn readU16(bytes: []const u8, offset: usize) ParseError!u16 {
    if (offset + 2 > bytes.len) return error.FileTooSmall;
    return @as(u16, bytes[offset]) |
        (@as(u16, bytes[offset + 1]) << 8);
}

fn readU32(bytes: []const u8, offset: usize) ParseError!u32 {
    if (offset + 4 > bytes.len) return error.FileTooSmall;
    return @as(u32, bytes[offset]) |
        (@as(u32, bytes[offset + 1]) << 8) |
        (@as(u32, bytes[offset + 2]) << 16) |
        (@as(u32, bytes[offset + 3]) << 24);
}

fn readU64(bytes: []const u8, offset: usize) ParseError!u64 {
    if (offset + 8 > bytes.len) return error.FileTooSmall;
    return @as(u64, try readU32(bytes, offset)) |
        (@as(u64, try readU32(bytes, offset + 4)) << 32);
}

pub fn parse(allocator: std.mem.Allocator, bytes: []const u8) ParseError!Image {
    if (bytes.len < 0x40) return error.FileTooSmall;
    if (try readU16(bytes, 0) != fmt.dos.signature) return error.InvalidDosSignature;

    const pe_offset = try readU32(bytes, 0x3C);
    if (pe_offset + 24 > bytes.len) return error.FileTooSmall;
    if (try readU32(bytes, pe_offset) != fmt.coff.signature) return error.InvalidPeSignature;

    const coff_offset = pe_offset + 4;
    const machine = try readU16(bytes, coff_offset + 0);
    const number_of_sections = try readU16(bytes, coff_offset + 2);
    const size_of_optional_header = try readU16(bytes, coff_offset + 16);
    const optional_offset = coff_offset + 20;
    const optional_magic = try readU16(bytes, optional_offset);

    var image_base: u64 = 0;
    var entry_rva: u32 = 0;
    var section_alignment: u32 = 0;
    var file_alignment: u32 = 0;
    var size_of_image: u32 = 0;
    var size_of_headers: u32 = 0;

    switch (optional_magic) {
        fmt.coff.optional_magic_pe32 => {
            entry_rva = try readU32(bytes, optional_offset + 16);
            image_base = try readU32(bytes, optional_offset + 28);
            section_alignment = try readU32(bytes, optional_offset + 32);
            file_alignment = try readU32(bytes, optional_offset + 36);
            size_of_image = try readU32(bytes, optional_offset + 56);
            size_of_headers = try readU32(bytes, optional_offset + 60);
        },
        fmt.coff.optional_magic_pe32_plus => {
            entry_rva = try readU32(bytes, optional_offset + 16);
            image_base = try readU64(bytes, optional_offset + 24);
            section_alignment = try readU32(bytes, optional_offset + 32);
            file_alignment = try readU32(bytes, optional_offset + 36);
            size_of_image = try readU32(bytes, optional_offset + 56);
            size_of_headers = try readU32(bytes, optional_offset + 60);
        },
        else => return error.UnsupportedOptionalHeader,
    }

    const section_table = optional_offset + size_of_optional_header;
    if (section_table + @as(usize, number_of_sections) * 40 > bytes.len) {
        return error.TruncatedSectionTable;
    }

    const sections = try allocator.alloc(Section, number_of_sections);
    errdefer allocator.free(sections);

    for (sections, 0..) |*section, i| {
        const off = section_table + i * 40;
        @memcpy(section.name[0..8], bytes[off .. off + 8]);
        section.virtual_size = try readU32(bytes, off + 8);
        section.virtual_address = try readU32(bytes, off + 12);
        section.raw_size = try readU32(bytes, off + 16);
        section.raw_offset = try readU32(bytes, off + 20);
        section.characteristics = try readU32(bytes, off + 36);
    }

    return .{
        .machine = machine,
        .entry_rva = entry_rva,
        .image_base = image_base,
        .section_alignment = section_alignment,
        .file_alignment = file_alignment,
        .size_of_image = size_of_image,
        .size_of_headers = size_of_headers,
        .number_of_sections = number_of_sections,
        .sections = sections,
    };
}

test "parse minimal PE32 header" {
    var bytes = [_]u8{0} ** 0x200;
    std.mem.writeInt(u16, bytes[0x00..0x02], fmt.dos.signature, .little);
    std.mem.writeInt(u32, bytes[0x3C..0x40], 0x80, .little);
    std.mem.writeInt(u32, bytes[0x80..0x84], fmt.coff.signature, .little);
    std.mem.writeInt(u16, bytes[0x84..0x86], fmt.coff.machine_i386, .little);
    std.mem.writeInt(u16, bytes[0x86..0x88], 1, .little);
    std.mem.writeInt(u16, bytes[0x94..0x96], 0xE0, .little);
    std.mem.writeInt(u16, bytes[0x98..0x9A], fmt.coff.optional_magic_pe32, .little);
    std.mem.writeInt(u32, bytes[0xA8..0xAC], 0x1234, .little);
    std.mem.writeInt(u32, bytes[0xB4..0xB8], 0x400000, .little);
    std.mem.writeInt(u32, bytes[0xB8..0xBC], 0x1000, .little);
    std.mem.writeInt(u32, bytes[0xBC..0xC0], 0x200, .little);
    std.mem.writeInt(u32, bytes[0xD0..0xD4], 0x5000, .little);
    std.mem.writeInt(u32, bytes[0xD4..0xD8], 0x400, .little);
    @memcpy(bytes[0x178..0x180], &[_]u8{ '.', 't', 'e', 'x', 't', 0, 0, 0 });
    std.mem.writeInt(u32, bytes[0x180..0x184], 0x1000, .little);
    std.mem.writeInt(u32, bytes[0x184..0x188], 0x1000, .little);
    std.mem.writeInt(u32, bytes[0x188..0x18C], 0x200, .little);
    std.mem.writeInt(u32, bytes[0x18C..0x190], 0x400, .little);
    std.mem.writeInt(u32, bytes[0x19C..0x1A0], 0x60000020, .little);

    const image = try parse(std.testing.allocator, &bytes);
    defer std.testing.allocator.free(image.sections);

    try std.testing.expectEqual(@as(u16, fmt.coff.machine_i386), image.machine);
    try std.testing.expectEqual(@as(u32, 0x1234), image.entry_rva);
    try std.testing.expectEqual(@as(u16, 1), image.number_of_sections);
}
