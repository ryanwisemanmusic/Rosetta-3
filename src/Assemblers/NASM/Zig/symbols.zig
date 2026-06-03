const std = @import("std");
const nasm = @import("nasm_core.zig");

const Allocator = std.mem.Allocator;

pub const SymbolType = enum(u32) {
    normal,
    global,
    extern_val,
    common,
    equ,
};

pub const Symbol = struct {
    name: []const u8,
    type_val: SymbolType,
    segment: i32 = nasm.NO_SEG,
    offset: i64 = 0,
    size: u64 = 0,
    defined: bool = false,
    global_flag: bool = false,
    common_flag: bool = false,

    pub fn deinit(self: *Symbol, allocator: Allocator) void {
        allocator.free(self.name);
    }
};

pub const LabelManager = struct {
    allocator: Allocator,
    symbols: std.StringHashMap(Symbol),
    local_sym_base: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    has_global: bool = false,

    pub fn init(allocator: Allocator) LabelManager {
        return LabelManager{
            .allocator = allocator,
            .symbols = std.StringHashMap(Symbol).init(allocator),
        };
    }

    pub fn deinit(self: *LabelManager) void {
        var it = self.symbols.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.symbols.deinit();
        for (self.local_sym_base.items) |s| self.allocator.free(s);
        self.local_sym_base.deinit(self.allocator);
    }

    pub fn defineSymbol(self: *LabelManager, name: []const u8, sym_type: SymbolType, segment: i32, offset: i64, size: u64) !void {
        if (self.symbols.get(name)) |existing| {
            if (existing.defined) {
                if (existing.segment != segment or existing.offset != offset) {
                    return error.SymbolRedefined;
                }
                return;
            }
        }

        const key = try self.allocator.dupe(u8, name);
        try self.symbols.put(key, Symbol{
            .name = try self.allocator.dupe(u8, name),
            .type_val = sym_type,
            .segment = segment,
            .offset = offset,
            .size = size,
            .defined = true,
            .global_flag = sym_type == .global,
            .common_flag = sym_type == .common,
        });
    }

    pub fn lookup(self: *const LabelManager, name: []const u8) ?Symbol {
        if (self.symbols.get(name)) |sym| return sym;
        return null;
    }

    pub fn makeGlobal(self: *LabelManager, name: []const u8) !void {
        if (self.symbols.getPtr(name)) |sym| {
            sym.global_flag = true;
            sym.type_val = .global;
        }
    }

    pub fn declareExternal(self: *LabelManager, name: []const u8) !void {
        if (self.symbols.contains(name)) return;
        const key = try self.allocator.dupe(u8, name);
        try self.symbols.put(key, Symbol{
            .name = try self.allocator.dupe(u8, name),
            .type_val = .extern_val,
            .defined = true,
        });
    }

    pub fn symbolCount(self: *const LabelManager) usize {
        return self.symbols.count();
    }
};

test "symbol define and lookup" {
    var lm = LabelManager.init(std.testing.allocator);
    defer lm.deinit();

    try lm.defineSymbol("myvar", .normal, 1, 0x100, 4);
    const sym = lm.lookup("myvar").?;
    try std.testing.expectEqualStrings("myvar", sym.name);
    try std.testing.expectEqual(@as(i64, 0x100), sym.offset);
}

test "symbol redefinition same values" {
    var lm = LabelManager.init(std.testing.allocator);
    defer lm.deinit();

    try lm.defineSymbol("foo", .normal, 1, 0x100, 4);
    try lm.defineSymbol("foo", .normal, 1, 0x100, 4);
}

test "symbol redefinition different values fails" {
    var lm = LabelManager.init(std.testing.allocator);
    defer lm.deinit();

    try lm.defineSymbol("foo", .normal, 1, 0x100, 4);
    try std.testing.expectError(error.SymbolRedefined, lm.defineSymbol("foo", .normal, 1, 0x200, 4));
}

test "make global" {
    var lm = LabelManager.init(std.testing.allocator);
    defer lm.deinit();

    try lm.defineSymbol("foo", .normal, 1, 0x100, 4);
    try lm.makeGlobal("foo");
    const sym = lm.lookup("foo").?;
    try std.testing.expect(sym.global_flag);
}

test "external symbol" {
    var lm = LabelManager.init(std.testing.allocator);
    defer lm.deinit();

    try lm.declareExternal("printf");
    try std.testing.expect(lm.lookup("printf") != null);
}
