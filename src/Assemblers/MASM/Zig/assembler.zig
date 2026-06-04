const std = @import("std");
const masm = @import("masm_core.zig");
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
    output_format: masm.OutputFormat = .omf,
    omf_writer: output.OmfWriter,
    coff_writer: output.CoffWriter,
    cpu: encoding.CpuMode = .@"386",
    use32: bool = false,
    errors: u32 = 0,
    warnings: u32 = 0,

    pub fn init(allocator: Allocator) !Assembler {
        return Assembler{
            .allocator = allocator,
            .seg_mgr = segments.SegmentManager.init(allocator),
            .sym_table = symbols.SymbolTable.init(allocator),
            .macro_pp = preprocessor.Preprocessor.init(allocator),
            .xref = listing.CrossReference.init(allocator),
            .omf_writer = output.OmfWriter.init(allocator),
            .coff_writer = output.CoffWriter.init(allocator),
        };
    }

    pub fn deinit(self: *Assembler) void {
        self.seg_mgr.deinit();
        self.sym_table.deinit();
        self.macro_pp.deinit();
        self.xref.deinit();
        self.omf_writer.deinit();
        self.coff_writer.deinit();
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
        _ = self;
        return &.{};
    }

    pub fn setCpu(self: *Assembler, cpu: encoding.CpuMode) !void {
        if (cpu == .@"286" and self.cpu != .@"286" and self.cpu != .@"8086") {
            return masm.AssemblerError.ProcessorDirectiveConflict;
        }
        self.cpu = cpu;
    }

    pub fn setCoprocessor(self: *Assembler, has_fpu: bool) void {
        _ = self;
        _ = has_fpu;
    }

    pub fn getSegment(self: *Assembler, name: []const u8) ?u32 {
        return self.seg_mgr.findSegment(name);
    }

    pub fn beginSegment(self: *Assembler, name: []const u8, seg_align: masm.SegmentAlign, combine: masm.SegmentCombine, use32: bool, class_name: []const u8) !void {
        const idx = try self.seg_mgr.addSegment(name, seg_align, combine, use32, class_name);
        self.seg_mgr.current_segment = idx;
    }

    pub fn endSegment(self: *Assembler) void {
        self.seg_mgr.current_segment = null;
    }

    pub fn setModel(self: *Assembler, model: masm.MemoryModel, lang: masm.ModelLanguage, use32: bool) !void {
        try self.seg_mgr.setModel(model, lang, use32);
        self.use32 = use32;
    }

    pub fn emitData(self: *Assembler, bytes: []const u8) !void {
        try self.seg_mgr.emit(bytes);
    }

    pub fn emitByte(self: *Assembler, byte: u8) !void {
        try self.emitData(&.{byte});
    }

    pub fn defineSymbol(self: *Assembler, name: []const u8, kind: masm.SymbolType, value: u64, seg_idx: u32, offset_val: u64, size: u32) !void {
        try self.sym_table.define(name, kind, value, seg_idx, offset_val, size);
    }
};

pub fn assembleMASM(source: []const u8, allocator: Allocator) ![]const u8 {
    var masm_asm = try Assembler.init(allocator);
    defer masm_asm.deinit();
    return masm_asm.assemble(source);
}

test "assembler initialization" {
    var m = try Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setCpu(.@"386");
    try std.testing.expectEqual(@as(encoding.CpuMode, .@"386"), m.cpu);
}

test "segment management" {
    var m = try Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.beginSegment("_TEXT", .para, .public, false, "CODE");
    try std.testing.expect(m.getSegment("_TEXT") != null);
    try m.emitByte(0x90);
    m.endSegment();
}

test "model directive" {
    var m = try Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.setModel(.small, .c, false);
    try std.testing.expectEqual(@as(masm.MemoryModel, .small), m.seg_mgr.model_state.model);
}

test "symbol definition" {
    var m = try Assembler.init(std.testing.allocator);
    defer m.deinit();
    try m.defineSymbol("myvar", .variable, 0, 0, 0x100, 4);
    const sym = m.sym_table.lookup("myvar").?;
    try std.testing.expectEqual(@as(u32, 4), sym.size);
}
