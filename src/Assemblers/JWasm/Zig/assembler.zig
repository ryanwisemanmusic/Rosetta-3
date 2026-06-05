const std = @import("std");
const jwasm = @import("jwasm_core.zig");
const directives = @import("directives.zig");
const operands = @import("operands.zig");
const encoding = @import("encoding.zig");
const segments = @import("segments.zig");
const preprocessor = @import("preprocessor.zig");
const symbols = @import("symbols.zig");
const output = @import("output.zig");
const listing = @import("listing.zig");

const Allocator = std.mem.Allocator;

pub const Assembler = struct {
    allocator: Allocator,
    seg_mgr: segments.SegmentManager,
    sym_table: symbols.SymbolTable,
    macro_pp: preprocessor.Preprocessor,
    listing_state: listing.ListingState = .{},
    xref: listing.CrossReference,
    current_pass: u16 = 1,
    max_passes: u16 = 4,
    changed: bool = true,
    output_format: jwasm.OutputFormat = .omf,
    sub_format: jwasm.sformat = .none,
    omf_writer: output.OmfWriter,
    coff_writer: output.CoffWriter,
    elf_writer: output.ElfWriter,
    mz_writer: output.MzWriter,
    pe_writer: output.PeWriter,
    cpu: u16 = jwasm.P_386,
    use32: bool = false,
    use64: bool = false,
    errors: u32 = 0,
    warnings: u32 = 0,
    module_name: []const u8 = "",

    pub fn init(allocator: Allocator) Assembler {
        return Assembler{
            .allocator = allocator,
            .seg_mgr = segments.SegmentManager.init(allocator),
            .sym_table = symbols.SymbolTable.init(allocator),
            .macro_pp = preprocessor.Preprocessor.init(allocator),
            .xref = listing.CrossReference.init(allocator),
            .omf_writer = output.OmfWriter.init(allocator),
            .coff_writer = output.CoffWriter.init(allocator),
            .elf_writer = output.ElfWriter.init(allocator),
            .mz_writer = output.MzWriter.init(allocator),
            .pe_writer = output.PeWriter.init(allocator),
        };
    }

    pub fn deinit(self: *Assembler) void {
        self.seg_mgr.deinit();
        self.sym_table.deinit();
        self.macro_pp.deinit();
        self.xref.deinit();
        self.omf_writer.deinit();
        self.coff_writer.deinit();
        self.elf_writer.deinit();
        self.mz_writer.deinit();
        self.pe_writer.deinit();
    }

    pub fn assemble(self: *Assembler, source: []const u8) ![]const u8 {
        while (self.changed and self.current_pass <= self.max_passes) {
            try self.assemblePass(source);
            self.current_pass += 1;
            self.sym_table.current_pass = self.current_pass;
            self.macro_pp.pass_number = @as(u8, @intCast(self.current_pass));
        }
        return try self.finishOutput();
    }

    fn assemblePass(self: *Assembler, source: []const u8) !void {
        _ = source;
        self.changed = false;
    }

    fn finishOutput(self: *Assembler) ![]const u8 {
        try self.omf_writer.finish();
        return self.omf_writer.buffer.items;
    }

    pub fn setCpu(self: *Assembler, cpu_val: u16) !void {
        const new_level = cpu_val & 0x00F0;
        const cur_level = self.cpu & 0x00F0;
        if (new_level < cur_level) {
            return jwasm.AssemblerError.ProcessorDirectiveConflict;
        }
        self.cpu = cpu_val;
        self.use32 = new_level >= 0x30;
        self.use64 = new_level >= 0x70;
    }

    pub fn setCoprocessor(self: *Assembler, fpu_flags: u16) void {
        self.cpu = (self.cpu & 0xFFF8) | (fpu_flags & 0x0007);
    }

    pub fn getSegment(self: *Assembler, name: []const u8) ?u32 {
        return self.seg_mgr.findSegment(name);
    }

    pub fn beginSegment(self: *Assembler, name: []const u8, seg_align: jwasm.SegmentAlign, combine: jwasm.SegmentCombine, use32: bool, class_name: []const u8) !void {
        const idx = try self.seg_mgr.addSegment(name, seg_align, combine, use32, class_name);
        self.seg_mgr.current_segment = idx;
    }

    pub fn endSegment(self: *Assembler) void {
        self.seg_mgr.current_segment = null;
    }

    pub fn setModel(self: *Assembler, model: jwasm.model_type, lang: jwasm.lang_type, use32: bool) !void {
        try self.seg_mgr.setModel(model, lang, use32);
        self.use32 = use32;
    }

    pub fn setModelFull(self: *Assembler, model: jwasm.model_type, lang: jwasm.lang_type, use32: bool, use64: bool) !void {
        try self.seg_mgr.setModelFull(model, lang, use32, use64);
        self.use32 = use32;
        self.use64 = use64;
    }

    pub fn emitData(self: *Assembler, bytes: []const u8) !void {
        try self.seg_mgr.emit(bytes);
    }

    pub fn emitByte(self: *Assembler, byte: u8) !void {
        try self.emitData(&.{byte});
    }

    pub fn defineSymbol(self: *Assembler, name: []const u8, state: jwasm.SymbolType, value: u64, seg_idx: u32, offset_val: u64, size: u32) !void {
        try self.sym_table.define(name, state, value, seg_idx, offset_val, size);
    }

    pub fn selectOutputFormat(self: *Assembler, format: jwasm.OutputFormat) void {
        self.output_format = format;
    }

    pub fn selectSubFormat(self: *Assembler, sub_fmt: jwasm.sformat) void {
        self.sub_format = sub_fmt;
    }

    pub fn setModuleName(self: *Assembler, name: []const u8) void {
        self.module_name = name;
    }
};

pub fn assembleJWASM(source: []const u8, allocator: Allocator) ![]const u8 {
    var a = Assembler.init(allocator);
    defer a.deinit();
    return a.assemble(source);
}

test "assembler initialization" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setCpu(jwasm.P_386);
    try std.testing.expectEqual(jwasm.P_386, m.cpu);
}

test "segment management" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.beginSegment("_TEXT", .para, .public, false, "CODE");
    try std.testing.expect(m.getSegment("_TEXT") != null);
    try m.emitByte(0x90);
    m.endSegment();
}

test "model directive" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setModel(.small, .c, false);
    try std.testing.expectEqual(@as(jwasm.model_type, .small), m.seg_mgr.model_state.model);
}

test "model directive with flat" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setModelFull(.flat, .c, true, false);
    try std.testing.expectEqual(@as(jwasm.model_type, .flat), m.seg_mgr.model_state.model);
    try std.testing.expect(m.seg_mgr.model_state.isFlat());
}

test "symbol definition" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.defineSymbol("myvar", .internal, 0, 0, 0x100, 4);
    const sym = m.sym_table.lookup("myvar").?;
    try std.testing.expectEqual(@as(u32, 4), sym.size);
}

test "output format selection" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    m.selectOutputFormat(.coff);
    try std.testing.expectEqual(@as(jwasm.OutputFormat, .coff), m.output_format);
}

test "cpu upgrade" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setCpu(jwasm.P_386);
    try m.setCpu(jwasm.P_586);
    try std.testing.expectEqual(jwasm.P_586, m.cpu);
}

test "cpu downgrade error" {
    var m = Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setCpu(jwasm.P_686);
    const result = m.setCpu(jwasm.P_386);
    try std.testing.expect(result == error.ProcessorDirectiveConflict);
}
