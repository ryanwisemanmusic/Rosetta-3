const std = @import("std");
const jwasm = @import("jwasm_core.zig");

const Allocator = std.mem.Allocator;

pub const Symbol = struct {
    name: []const u8 = "",
    state: jwasm.SymbolType = .undefined,
    value: u64 = 0,
    segment_index: u32 = std.math.maxInt(u32),
    offset: u64 = 0,
    size: u32 = 0,
    scope: jwasm.ScopeType = .global,
    defined: bool = false,
    used: bool = false,
    pass_defined: u16 = 0,
    is_public: bool = false,
    is_extern: bool = false,
    is_forward_ref: bool = false,
    isproc: bool = false,
    isequate: bool = false,
    isvariable: bool = false,
    mem_type: jwasm.memtype = .empty,
    langtype: jwasm.lang_type = .none,
    total_length: u32 = 0,
    first_size: u32 = 0,

    pub fn isSegment(self: *const Symbol) bool {
        return self.state == .segment;
    }

    pub fn isGroup(self: *const Symbol) bool {
        return self.state == .group;
    }

    pub fn isMacro(self: *const Symbol) bool {
        return self.state == .macro;
    }

    pub fn isType(self: *const Symbol) bool {
        return self.state == .type;
    }
};

pub const SymbolTable = struct {
    allocator: Allocator,
    map: std.StringHashMap(Symbol),
    current_pass: u16 = 1,

    pub fn init(allocator: Allocator) SymbolTable {
        return SymbolTable{
            .allocator = allocator,
            .map = std.StringHashMap(Symbol).init(allocator),
        };
    }

    pub fn deinit(self: *SymbolTable) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.map.deinit();
    }

    pub fn define(self: *SymbolTable, name: []const u8, state: jwasm.SymbolType, value: u64, seg_idx: u32, offset_val: u64, size: u32) !void {
        const owned_name = try self.allocator.dupe(u8, name);
        const gop = try self.map.getOrPut(owned_name);
        if (gop.found_existing) {
            self.allocator.free(owned_name);
            gop.value_ptr.* = Symbol{
                .name = gop.value_ptr.name,
                .state = state,
                .value = value,
                .segment_index = seg_idx,
                .offset = offset_val,
                .size = size,
                .pass_defined = self.current_pass,
                .defined = true,
            };
        } else {
            gop.value_ptr.* = Symbol{
                .name = owned_name,
                .state = state,
                .value = value,
                .segment_index = seg_idx,
                .offset = offset_val,
                .size = size,
                .pass_defined = self.current_pass,
                .defined = true,
            };
        }
    }

    pub fn defineFull(self: *SymbolTable, name: []const u8, state: jwasm.SymbolType, value: u64, seg_idx: u32, offset_val: u64, size: u32, mem_type: jwasm.memtype, lang: jwasm.lang_type) !void {
        const owned_name = try self.allocator.dupe(u8, name);
        const gop = try self.map.getOrPut(owned_name);
        if (gop.found_existing) {
            self.allocator.free(owned_name);
            gop.value_ptr.* = Symbol{
                .name = gop.value_ptr.name,
                .state = state,
                .value = value,
                .segment_index = seg_idx,
                .offset = offset_val,
                .size = size,
                .mem_type = mem_type,
                .langtype = lang,
                .pass_defined = self.current_pass,
                .defined = true,
            };
        } else {
            gop.value_ptr.* = Symbol{
                .name = owned_name,
                .state = state,
                .value = value,
                .segment_index = seg_idx,
                .offset = offset_val,
                .size = size,
                .mem_type = mem_type,
                .langtype = lang,
                .pass_defined = self.current_pass,
                .defined = true,
            };
        }
    }

    pub fn lookup(self: *const SymbolTable, name: []const u8) ?Symbol {
        return self.map.get(name);
    }

    pub fn defineSimple(self: *SymbolTable, name: []const u8) !void {
        try self.define(name, .constant, 0, std.math.maxInt(u32), 0, 0);
    }

    pub fn markPublic(self: *SymbolTable, name: []const u8) !void {
        if (self.map.getPtr(name)) |sym| {
            sym.is_public = true;
        }
    }

    pub fn markExtern(self: *SymbolTable, name: []const u8, seg_idx: u32) !void {
        if (self.map.getPtr(name)) |sym| {
            sym.is_extern = true;
            sym.state = .external;
            sym.segment_index = seg_idx;
        }
    }
};

pub const ProcFrame = struct {
    name: []const u8,
    segment_index: u32,
    offset: u64,
    stack_frame_size: u32,
    has_local: bool,
    has_vararg: bool,
    prologue_arg: []const u8,
    lang: jwasm.lang_type,
};

pub const ProcStack = struct {
    items: std.ArrayListUnmanaged(ProcFrame) = .{ .items = &.{}, .capacity = 0 },

    pub fn deinit(self: *ProcStack, allocator: Allocator) void {
        self.items.deinit(allocator);
    }

    pub fn push(self: *ProcStack, allocator: Allocator, name: []const u8, seg_idx: u32, offset_val: u64) !void {
        try self.items.append(allocator, ProcFrame{
            .name = name,
            .segment_index = seg_idx,
            .offset = offset_val,
            .stack_frame_size = 0,
            .has_local = false,
            .has_vararg = false,
            .prologue_arg = "",
            .lang = .none,
        });
    }

    pub fn pushFull(self: *ProcStack, allocator: Allocator, name: []const u8, seg_idx: u32, offset_val: u64, lang: jwasm.lang_type) !void {
        try self.items.append(allocator, ProcFrame{
            .name = name,
            .segment_index = seg_idx,
            .offset = offset_val,
            .stack_frame_size = 0,
            .has_local = false,
            .has_vararg = false,
            .prologue_arg = "",
            .lang = lang,
        });
    }

    pub fn pop(self: *ProcStack) ?ProcFrame {
        if (self.items.items.len == 0) return null;
        return self.items.pop();
    }

    pub fn current(self: *const ProcStack) ?ProcFrame {
        if (self.items.items.len == 0) return null;
        return self.items.items[self.items.items.len - 1];
    }

    pub fn depth(self: *const ProcStack) usize {
        return self.items.items.len;
    }
};

test "symbol define and lookup" {
    var st = SymbolTable.init(std.testing.allocator);
    defer st.deinit();

    try st.define("test_var", .internal, 0, 0, 0x100, 4);
    const sym = st.lookup("test_var").?;
    try std.testing.expectEqual(@as(u64, 0x100), sym.offset);
    try std.testing.expectEqual(@as(u32, 4), sym.size);
}

test "symbol redefinition" {
    var st = SymbolTable.init(std.testing.allocator);
    defer st.deinit();

    try st.define("x", .internal, 10, std.math.maxInt(u32), 0, 0);
    try st.define("x", .internal, 20, std.math.maxInt(u32), 0, 0);
    const sym = st.lookup("x").?;
    try std.testing.expectEqual(@as(u64, 20), sym.value);
}

test "symbol public flag" {
    var st = SymbolTable.init(std.testing.allocator);
    defer st.deinit();

    try st.define("myvar", .internal, 0, 0, 0x100, 4);
    try st.markPublic("myvar");
    const sym = st.lookup("myvar").?;
    try std.testing.expect(sym.is_public);
}

test "symbol state queries" {
    var st = SymbolTable.init(std.testing.allocator);
    defer st.deinit();

    try st.define("_TEXT", .segment, 0, 0, 0, 0);
    const sym = st.lookup("_TEXT").?;
    try std.testing.expect(sym.isSegment());
}

test "proc stack" {
    var ps = ProcStack{};
    defer ps.deinit(std.testing.allocator);

    try ps.push(std.testing.allocator, "MyProc", 0, 0x100);
    try std.testing.expectEqual(@as(usize, 1), ps.depth());

    const frame = ps.pop().?;
    try std.testing.expectEqualStrings("MyProc", frame.name);
    try std.testing.expectEqual(@as(usize, 0), ps.depth());
}

test "proc stack with language" {
    var ps = ProcStack{};
    defer ps.deinit(std.testing.allocator);

    try ps.pushFull(std.testing.allocator, "WinProc", 0, 0x100, .stdcall);
    try std.testing.expectEqual(@as(jwasm.lang_type, .stdcall), ps.current().?.lang);
}

test "symbol full definition" {
    var st = SymbolTable.init(std.testing.allocator);
    defer st.deinit();

    try st.defineFull("arr", .internal, 0, 0, 0x200, 16, .dword, .none);
    const sym = st.lookup("arr").?;
    try std.testing.expectEqual(@as(u32, 16), sym.size);
}
