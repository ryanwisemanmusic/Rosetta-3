const std = @import("std");
const jwasm = @import("jwasm_core.zig");

const Allocator = std.mem.Allocator;

pub const OmfRecord = struct {
    record_type: u8,
    data: []const u8,

    pub fn encode(self: OmfRecord, allocator: Allocator) ![]u8 {
        const length: u16 = @as(u16, @intCast(self.data.len));
        var buf = try std.ArrayListUnmanaged(u8).initCapacity(allocator, self.data.len + 3);
        defer buf.deinit(allocator);
        try buf.append(allocator, self.record_type);
        const len_bytes = std.mem.asBytes(&length);
        try buf.appendSlice(allocator, len_bytes[0..2]);
        try buf.appendSlice(allocator, self.data);
        const checksum = computeChecksum(buf.items);
        try buf.append(allocator, checksum);
        return buf.toOwnedSlice(allocator);
    }

    fn computeChecksum(data: []const u8) u8 {
        var sum: u8 = 0;
        for (data) |b| sum -%= b;
        return sum;
    }
};

pub const OmfWriter = struct {
    allocator: Allocator,
    buffer: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },
    translator_name: []const u8 = "JWasm 2.21",

    pub fn init(allocator: Allocator) OmfWriter {
        return OmfWriter{ .allocator = allocator };
    }

    pub fn deinit(self: *OmfWriter) void {
        self.buffer.deinit(self.allocator);
    }

    pub fn writeHeader(self: *OmfWriter, module_name: []const u8) !void {
        var data = std.ArrayListUnmanaged(u8).init(self.allocator);
        defer data.deinit(self.allocator);
        try data.appendSlice(self.allocator, module_name);
        try data.append(self.allocator, 0);
        const rec = OmfRecord{ .record_type = 0x80, .data = data.items };
        const encoded = try rec.encode(self.allocator);
        defer self.allocator.free(encoded);
        try self.buffer.appendSlice(self.allocator, encoded);
    }

    pub fn writeComment(self: *OmfWriter, comment: []const u8, comment_type: u8) !void {
        var data = std.ArrayListUnmanaged(u8).init(self.allocator);
        defer data.deinit(self.allocator);
        try data.append(self.allocator, comment_type);
        try data.appendSlice(self.allocator, comment);
        const rec = OmfRecord{ .record_type = 0x88, .data = data.items };
        const encoded = try rec.encode(self.allocator);
        defer self.allocator.free(encoded);
        try self.buffer.appendSlice(self.allocator, encoded);
    }

    pub fn writeSegmentDef(_: *OmfWriter, name: []const u8, class_name: []const u8, size: u32, seg_align: u8, combine: u8, use32: bool) !void {
        _ = name;
        _ = class_name;
        _ = size;
        _ = seg_align;
        _ = combine;
        _ = use32;
    }

    pub fn writeGroupDef(self: *OmfWriter, group_name: []const u8, seg_indices: []const u8) !void {
        _ = self;
        _ = group_name;
        _ = seg_indices;
    }

    pub fn writePublicSymbol(self: *OmfWriter, name: []const u8, seg_idx: u8, offset: u32) !void {
        _ = self;
        _ = name;
        _ = seg_idx;
        _ = offset;
    }

    pub fn writeExternalSymbol(self: *OmfWriter, name: []const u8) !void {
        _ = self;
        _ = name;
    }

    pub fn writeLNames(self: *OmfWriter, names: []const []const u8) !void {
        _ = self;
        _ = names;
    }

    pub fn toBytes(self: *OmfWriter) ![]const u8 {
        return self.buffer.items;
    }

    pub fn finish(self: *OmfWriter) !void {
        const rec = OmfRecord{ .record_type = 0x8A, .data = &.{} };
        const encoded = try rec.encode(self.allocator);
        defer self.allocator.free(encoded);
        try self.buffer.appendSlice(self.allocator, encoded);
    }
};

pub const CoffSection = struct {
    name: [8]u8,
    virtual_size: u32,
    virtual_address: u32,
    raw_size: u32,
    raw_ptr: u32,
    reloc_ptr: u32,
    line_ptr: u32,
    num_relocs: u16,
    num_lines: u16,
    characteristics: u32,
    data: []const u8,
};

pub const CoffSymbol = struct {
    name: [8]u8,
    value: u32,
    section: i16,
    type: u16,
    storage_class: u8,
    num_aux: u8,
};

pub const CoffWriter = struct {
    allocator: Allocator,
    sections: std.ArrayListUnmanaged(CoffSection) = .{ .items = &.{}, .capacity = 0 },
    symbols: std.ArrayListUnmanaged(CoffSymbol) = .{ .items = &.{}, .capacity = 0 },
    string_table: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },

    pub fn init(allocator: Allocator) CoffWriter {
        return CoffWriter{ .allocator = allocator };
    }

    pub fn deinit(self: *CoffWriter) void {
        self.sections.deinit(self.allocator);
        self.symbols.deinit(self.allocator);
        self.string_table.deinit(self.allocator);
    }

    pub fn addSection(self: *CoffWriter, name: []const u8, data: []const u8, characteristics: u32) !void {
        var name_bytes: [8]u8 = .{0} ** 8;
        const copy_len = @min(name.len, 8);
        @memcpy(name_bytes[0..copy_len], name[0..copy_len]);
        try self.sections.append(self.allocator, CoffSection{
            .name = name_bytes,
            .virtual_size = @as(u32, @intCast(data.len)),
            .virtual_address = 0,
            .raw_size = @as(u32, @intCast(data.len)),
            .raw_ptr = 0,
            .reloc_ptr = 0,
            .line_ptr = 0,
            .num_relocs = 0,
            .num_lines = 0,
            .characteristics = characteristics,
            .data = data,
        });
    }

    pub fn addSymbol(self: *CoffWriter, name: []const u8, value: u32, section: i16, storage_class: u8) !void {
        var name_bytes: [8]u8 = .{0} ** 8;
        const copy_len = @min(name.len, 8);
        @memcpy(name_bytes[0..copy_len], name[0..copy_len]);
        try self.symbols.append(self.allocator, CoffSymbol{
            .name = name_bytes,
            .value = value,
            .section = section,
            .type = 0,
            .storage_class = storage_class,
            .num_aux = 0,
        });
    }

    pub fn toBytes(self: *CoffWriter) ![]const u8 {
        _ = self;
        return &.{};
    }
};

pub const ElfWriter = struct {
    allocator: Allocator,
    buffer: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },
    is_64bit: bool = false,

    pub fn init(allocator: Allocator) ElfWriter {
        return ElfWriter{ .allocator = allocator };
    }

    pub fn deinit(self: *ElfWriter) void {
        self.buffer.deinit(self.allocator);
    }

    pub fn set64Bit(self: *ElfWriter, is64: bool) void {
        self.is_64bit = is64;
    }

    pub fn writeHeader(self: *ElfWriter) !void {
        _ = self;
    }

    pub fn writeSection(_: *ElfWriter, _name: []const u8, _data: []const u8, _flags: u64) !void {
        _ = _name;
        _ = _data;
        _ = _flags;
    }

    pub fn writeSymbol(_: *ElfWriter, _name: []const u8, _value: u64, _section: u16, _binding: u8, _type_val: u8) !void {
        _ = _name;
        _ = _value;
        _ = _section;
        _ = _binding;
        _ = _type_val;
    }

    pub fn toBytes(self: *ElfWriter) ![]const u8 {
        return self.buffer.items;
    }
};

pub const MzWriter = struct {
    allocator: Allocator,
    buffer: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },

    pub fn init(allocator: Allocator) MzWriter {
        return MzWriter{ .allocator = allocator };
    }

    pub fn deinit(self: *MzWriter) void {
        self.buffer.deinit(self.allocator);
    }

    pub fn toBytes(self: *MzWriter) ![]const u8 {
        return self.buffer.items;
    }
};

pub const PeWriter = struct {
    allocator: Allocator,
    buffer: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },
    is_32bit: bool = true,

    pub fn init(allocator: Allocator) PeWriter {
        return PeWriter{ .allocator = allocator };
    }

    pub fn deinit(self: *PeWriter) void {
        self.buffer.deinit(self.allocator);
    }

    pub fn toBytes(self: *PeWriter) ![]const u8 {
        return self.buffer.items;
    }
};

pub fn getSegmentCharacteristics(seg_align: jwasm.SegmentAlign, combine: jwasm.SegmentCombine, use32: bool) u32 {
    var flags: u32 = 0;
    flags |= switch (seg_align) {
        .byte => @as(u32, 0),
        .word => @as(u32, 0x0001),
        .dword => @as(u32, 0x0002),
        .para => @as(u32, 0x0003),
        .page => @as(u32, 0x0004),
    } << 8;
    flags |= switch (combine) {
        .private, .at => @as(u32, 0x0000),
        .public => @as(u32, 0x0010),
        .stack => @as(u32, 0x0020),
        .common => @as(u32, 0x0030),
        .memory => @as(u32, 0x0040),
    };
    if (!use32) flags |= 0x0010;
    return flags;
}

pub fn getCoffCharacteristics(seg_type: jwasm.seg_type) u32 {
    return switch (seg_type) {
        .code => 0x60000020,
        .data => 0xC0000040,
        .bss => 0xC0000080,
        .stack => 0xC0000000,
        else => 0,
    };
}

test "OMF record encoding" {
    const alloc = std.testing.allocator;
    const rec = OmfRecord{ .record_type = 0x8A, .data = &.{} };
    const encoded = try rec.encode(alloc);
    defer alloc.free(encoded);
    try std.testing.expectEqual(@as(u8, 0x8A), encoded[0]);
}

test "COFF section characteristics" {
    const flags = getSegmentCharacteristics(.para, .public, false);
    try std.testing.expect(flags > 0);
}

test "COFF segment type characteristics" {
    const code_flags = getCoffCharacteristics(.code);
    const data_flags = getCoffCharacteristics(.data);
    try std.testing.expect(code_flags != data_flags);
}

test "ELF writer creation" {
    var ew = ElfWriter.init(std.testing.allocator);
    defer ew.deinit();
    try std.testing.expect(!ew.is_64bit);
    ew.set64Bit(true);
    try std.testing.expect(ew.is_64bit);
}
