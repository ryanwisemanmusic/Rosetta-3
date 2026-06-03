const std = @import("std");
const nasm = @import("nasm_core.zig");
const symbols = @import("symbols.zig");

const Allocator = std.mem.Allocator;

pub const OutputFormatHandler = struct {
    name: []const u8,
    shortname: []const u8,
    extension: []const u8,
    flags: u32 = 0,
    maxbits: u32 = 64,
};

pub const NullOutput = struct {
    allocator: Allocator,
    data: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },

    pub fn init(allocator: Allocator) NullOutput {
        return NullOutput{ .allocator = allocator };
    }

    pub fn deinit(self: *NullOutput) void {
        self.data.deinit(self.allocator);
    }

    pub fn outputBytes(_: *NullOutput, bytes: []const u8) !void {
        _ = bytes;
    }
};

pub const BinOutput = struct {
    allocator: Allocator,
    data: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },
    origin: u64 = 0,
    bits: u8 = 16,

    pub fn init(allocator: Allocator, origin_val: u64, bits_val: u8) BinOutput {
        return BinOutput{
            .allocator = allocator,
            .origin = origin_val,
            .bits = bits_val,
        };
    }

    pub fn deinit(self: *BinOutput) void {
        self.data.deinit(self.allocator);
    }

    pub fn writeBytes(self: *BinOutput, bytes: []const u8) !void {
        try self.data.appendSlice(self.allocator, bytes);
    }

    pub fn toBytes(self: *BinOutput) []const u8 {
        return self.data.items;
    }
};

pub const CoffWriter = struct {
    allocator: Allocator,
    sections: std.ArrayListUnmanaged(CoffSection) = .{ .items = &.{}, .capacity = 0 },
    symbols_list: std.ArrayListUnmanaged(CoffSymbol) = .{ .items = &.{}, .capacity = 0 },
    string_table: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },

    const CoffSection = struct {
        name: [8]u8,
        paddr: u32 = 0,
        vaddr: u32 = 0,
        size: u32 = 0,
        scnptr: u32 = 0,
        relptr: u32 = 0,
        lnnoptr: u32 = 0,
        nreloc: u16 = 0,
        nlnno: u16 = 0,
        flags: u32 = 0,
        data: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },
    };

    const CoffSymbol = struct {
        name: [8]u8,
        value: u32 = 0,
        section: i16 = 0,
        type_val: u16 = 0,
        storage_class: u8 = 0,
        aux_count: u8 = 0,
    };

    pub fn init(allocator: Allocator) CoffWriter {
        return CoffWriter{ .allocator = allocator };
    }

    pub fn deinit(self: *CoffWriter) void {
        for (self.sections.items) |*sec| sec.data.deinit(self.allocator);
        self.sections.deinit(self.allocator);
        self.symbols_list.deinit(self.allocator);
        self.string_table.deinit(self.allocator);
    }

    pub fn addSection(self: *CoffWriter, name: []const u8, flags: u32) !u32 {
        const idx = @as(u32, @intCast(self.sections.items.len));
        var sec_name: [8]u8 = .{0} ** 8;
        const copy_len = @min(name.len, 8);
        @memcpy(sec_name[0..copy_len], name[0..copy_len]);
        try self.sections.append(self.allocator, CoffSection{
            .name = sec_name,
            .flags = flags,
            .data = .{ .items = &.{}, .capacity = 0 },
        });
        return idx;
    }

    pub fn writeSectionData(self: *CoffWriter, idx: u32, data: []const u8) !void {
        if (idx < self.sections.items.len) {
            try self.sections.items[idx].data.appendSlice(self.allocator, data);
        }
    }

    pub fn toBytes(self: *CoffWriter) ![]const u8 {
        _ = self;
        return "";
    }
};

pub const ElfWriter = struct {
    allocator: Allocator,
    sections: std.ArrayListUnmanaged(ElfSection) = .{ .items = &.{}, .capacity = 0 },

    const ElfSection = struct {
        name: []const u8,
        type_val: u32 = 0,
        flags: u64 = 0,
        addr: u64 = 0,
        offset: u64 = 0,
        size: u64 = 0,
        link: u32 = 0,
        info: u32 = 0,
        addralign: u64 = 0,
        entsize: u64 = 0,
        data: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },

        pub fn deinit(self: *ElfSection, allocator: Allocator) void {
            allocator.free(self.name);
            self.data.deinit(allocator);
        }
    };

    pub fn init(allocator: Allocator) ElfWriter {
        return ElfWriter{ .allocator = allocator };
    }

    pub fn deinit(self: *ElfWriter) void {
        for (self.sections.items) |*sec| sec.deinit(self.allocator);
        self.sections.deinit(self.allocator);
    }

    pub fn addSection(self: *ElfWriter, name: []const u8, type_val: u32, flags: u64) !u32 {
        const idx = @as(u32, @intCast(self.sections.items.len));
        try self.sections.append(self.allocator, ElfSection{
            .name = try self.allocator.dupe(u8, name),
            .type_val = type_val,
            .flags = flags,
            .data = .{ .items = &.{}, .capacity = 0 },
        });
        return idx;
    }

    pub fn writeSectionData(self: *ElfWriter, idx: u32, data: []const u8) !void {
        if (idx < self.sections.items.len) {
            try self.sections.items[idx].data.appendSlice(self.allocator, data);
        }
    }
};

test "binary output" {
    var bin = BinOutput.init(std.testing.allocator, 0, 16);
    defer bin.deinit();

    try bin.writeBytes(&[_]u8{0x90, 0x90});
    try std.testing.expectEqual(@as(usize, 2), bin.toBytes().len);
}

test "COFF section management" {
    var coff = CoffWriter.init(std.testing.allocator);
    defer coff.deinit();

    const idx = try coff.addSection(".text", 0x00200000);
    try std.testing.expectEqual(@as(u32, 0), idx);
}

test "ELF section management" {
    var elf = ElfWriter.init(std.testing.allocator);
    defer elf.deinit();

    const idx = try elf.addSection(".text", 1, 6);
    try std.testing.expectEqual(@as(u32, 0), idx);
}
