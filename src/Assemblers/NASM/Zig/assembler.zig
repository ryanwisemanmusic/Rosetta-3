const std = @import("std");
const nasm = @import("nasm_core.zig");
const directives = @import("directives.zig");
const operands = @import("operands.zig");
const encoding = @import("encoding.zig");
const segments = @import("segments.zig");
const preprocessor = @import("preprocessor.zig");
const symbols = @import("symbols.zig");
const output_formats = @import("output.zig");
const listing = @import("listing.zig");

const Allocator = std.mem.Allocator;

pub const Assembler = struct {
    allocator: Allocator,
    seg_mgr: segments.SegmentManager,
    sym_table: symbols.LabelManager,
    pp: preprocessor.Preprocessor,
    listing_state: listing.ListingState,
    xref: listing.CrossReference,
    bits: u8,
    format: nasm.OutputFormat,
    pass: u32 = 0,
    max_passes: u32 = 3,
    cpu_level: directives.CpuLevel = .default_cpu,
    cpu_level_set: bool = false,
    error_count: u32 = 0,
    warning_count: u32 = 0,
    oflags: u32 = 0,

    pub fn init(allocator: Allocator) Assembler {
        return Assembler{
            .allocator = allocator,
            .seg_mgr = segments.SegmentManager.init(allocator),
            .sym_table = symbols.LabelManager.init(allocator),
            .pp = preprocessor.Preprocessor.init(allocator),
            .listing_state = listing.ListingState.init(allocator),
            .xref = listing.CrossReference.init(allocator),
            .bits = 16,
            .format = .bin,
        };
    }

    pub fn deinit(self: *Assembler) void {
        self.seg_mgr.deinit();
        self.sym_table.deinit();
        self.pp.deinit();
        self.listing_state.deinit();
        self.xref.deinit();
    }

    pub fn setBits(self: *Assembler, bits_val: u8) !void {
        try self.seg_mgr.setBits(bits_val);
        self.bits = bits_val;
    }

    pub fn setFormat(self: *Assembler, fmt: nasm.OutputFormat) void {
        self.format = fmt;
    }

    pub fn setCpu(self: *Assembler, cpu: directives.CpuLevel) void {
        self.cpu_level = cpu;
        self.cpu_level_set = true;
    }

    pub fn beginSection(self: *Assembler, name: []const u8, align_val: u32) !u32 {
        return try self.seg_mgr.addSection(name, align_val, self.bits == 32);
    }

    pub fn emitBytes(self: *Assembler, bytes: []const u8) !void {
        try self.seg_mgr.emit(bytes);
    }

    pub fn defineSymbol(self: *Assembler, name: []const u8, sym_type: symbols.SymbolType, segment: i32, offset: i64, size: u64) !void {
        try self.sym_table.defineSymbol(name, sym_type, segment, offset, size);
    }

    pub fn getSection(self: *Assembler, name: []const u8) ?u32 {
        return self.seg_mgr.findSection(name);
    }

    pub fn assembleLine(self: *Assembler, line: []const u8) !void {
        try self.pp.processLine(line);
    }
};

test "assembler initialization" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try std.testing.expectEqual(@as(u8, 16), m.bits);
}

test "bits mode" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setBits(64);
    try std.testing.expectEqual(@as(u8, 64), m.bits);
}

test "section management" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    const idx = try m.beginSection(".text", 16);
    try std.testing.expectEqual(@as(u32, 0), idx);
    try std.testing.expect(m.getSection(".text") != null);
}

test "symbol definition" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.defineSymbol("myvar", .normal, 0, 0x100, 4);
    try std.testing.expect(m.sym_table.lookup("myvar") != null);
}
