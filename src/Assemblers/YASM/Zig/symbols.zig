const std = @import("std");

const Allocator = std.mem.Allocator;

pub const SymbolKind = enum {
    local,
    global,
    extern_ref,
    common,
    equ,
};

pub const Symbol = struct {
    name: []const u8,
    kind: SymbolKind,
    section_index: ?u32 = null,
    value: i64 = 0,
    size: u64 = 0,
    defined: bool = false,

    pub fn deinit(self: *Symbol, allocator: Allocator) void {
        allocator.free(self.name);
    }
};

pub const SymbolTable = struct {
    allocator: Allocator,
    entries: std.StringHashMap(Symbol),

    pub fn init(allocator: Allocator) SymbolTable {
        return .{
            .allocator = allocator,
            .entries = std.StringHashMap(Symbol).init(allocator),
        };
    }

    pub fn deinit(self: *SymbolTable) void {
        var it = self.entries.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.entries.deinit();
    }

    pub fn define(self: *SymbolTable, name: []const u8, kind: SymbolKind, section_index: ?u32, value: i64, size: u64) !void {
        if (self.entries.getPtr(name)) |existing| {
            existing.kind = kind;
            existing.section_index = section_index;
            existing.value = value;
            existing.size = size;
            existing.defined = true;
            return;
        }

        const key = try self.allocator.dupe(u8, name);
        try self.entries.put(key, .{
            .name = try self.allocator.dupe(u8, name),
            .kind = kind,
            .section_index = section_index,
            .value = value,
            .size = size,
            .defined = true,
        });
    }

    pub fn declareExtern(self: *SymbolTable, name: []const u8) !void {
        if (self.entries.contains(name)) return;
        const key = try self.allocator.dupe(u8, name);
        try self.entries.put(key, .{
            .name = try self.allocator.dupe(u8, name),
            .kind = .extern_ref,
        });
    }

    pub fn markGlobal(self: *SymbolTable, name: []const u8) !void {
        if (self.entries.getPtr(name)) |existing| {
            existing.kind = .global;
            return;
        }
        try self.define(name, .global, null, 0, 0);
    }

    pub fn lookup(self: *const SymbolTable, name: []const u8) ?Symbol {
        return self.entries.get(name);
    }

    pub fn count(self: *const SymbolTable) usize {
        return self.entries.count();
    }
};

test "symbol table tracks globals and externs" {
    var table = SymbolTable.init(std.testing.allocator);
    defer table.deinit();

    try table.markGlobal("_start");
    try table.declareExtern("printf");
    try std.testing.expectEqual(SymbolKind.global, table.lookup("_start").?.kind);
    try std.testing.expectEqual(SymbolKind.extern_ref, table.lookup("printf").?.kind);
}
