const std = @import("std");
const fasm = @import("fasm_core.zig");
const hash_map = std.hash_map;
const StringHashMap = std.StringHashMap;

const Allocator = std.mem.Allocator;

pub const SymbolTable = struct {
    map: StringHashMap(SymbolEntry),
    allocator: Allocator,
    pass_count: u16 = 1,
    it: ?std.StringHashMap(SymbolEntry).Iterator = null,

    const SymbolEntry = struct {
        value_low: u32 = 0,
        value_high: u32 = 0,
        flags: fasm.SymbolFlags = .{},
        pass_defined: u16 = 0,
        line_number: u32 = 0,
    };

    pub fn init(allocator: Allocator) SymbolTable {
        return SymbolTable{
            .map = StringHashMap(SymbolEntry).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SymbolTable) void {
        var map = self.map;
        var it = map.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        map.deinit();
    }

    pub fn define(self: *SymbolTable, name: []const u8, value: u64, flags: fasm.SymbolFlags) !void {
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        const entry = SymbolEntry{
            .value_low = @as(u32, @truncate(value)),
            .value_high = @as(u32, @truncate(value >> 32)),
            .flags = flags,
            .pass_defined = self.pass_count,
        };

        const result = self.map.getOrPut(owned_name) catch {
            self.allocator.free(owned_name);
            return;
        };
        if (result.found_existing) {
            self.allocator.free(owned_name);
            result.value_ptr.* = entry;
        } else {
            result.value_ptr.* = entry;
        }
    }

    pub fn lookup(self: *const SymbolTable, name: []const u8) ?u64 {
        const entry = self.map.get(name) orelse return null;
        return (@as(u64, entry.value_high) << 32) | entry.value_low;
    }

    pub fn lookupEntry(self: *const SymbolTable, name: []const u8) ?SymbolEntry {
        return self.map.get(name);
    }

    pub fn getOrPut(self: *SymbolTable, name: []const u8) !struct { entry: *SymbolEntry, found: bool } {
        const owned_name = try self.allocator.dupe(u8, name);
        const result = try self.map.getOrPut(owned_name);
        if (result.found_existing) {
            self.allocator.free(owned_name);
            return .{ .entry = result.value_ptr, .found = true };
        }
        result.value_ptr.* = SymbolEntry{};
        return .{ .entry = result.value_ptr, .found = false };
    }

    pub fn size(self: *const SymbolTable) usize {
        return self.map.count();
    }

    pub fn reset(self: *SymbolTable) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.pass_defined = 0;
        }
    }

    pub fn iterator(self: *SymbolTable) StringHashMap(SymbolEntry).Iterator {
        return self.map.iterator();
    }
};

pub const LabelStack = struct {
    items: std.ArrayListUnmanaged(LabelFrame) = .{ .items = &.{}, .capacity = 0 },

    const LabelFrame = struct {
        base_symbol: u32,
        offset: u64,
        code_type: fasm.CodeType,
    };

    pub fn init() LabelStack {
        return LabelStack{};
    }

    pub fn deinit(self: *LabelStack, allocator: Allocator) void {
        self.items.deinit(allocator);
    }

    pub fn push(self: *LabelStack, allocator: Allocator, base: u32, offset: u64, code_type: fasm.CodeType) !void {
        try self.items.append(allocator, .{
            .base_symbol = base,
            .offset = offset,
            .code_type = code_type,
        });
    }

    pub fn pop(self: *LabelStack) ?LabelFrame {
        if (self.items.items.len == 0) return null;
        return self.items.pop();
    }

    pub fn peek(self: *const LabelStack) ?LabelFrame {
        if (self.items.items.len == 0) return null;
        return self.items.items[self.items.items.len - 1];
    }

    pub fn depth(self: *const LabelStack) usize {
        return self.items.items.len;
    }
};

test "SymbolTable define and lookup" {
    var table = SymbolTable.init(std.testing.allocator);
    defer table.deinit();

    try table.define("test_label", 0x1234, .{ .defined = true });
    const val = table.lookup("test_label");
    try std.testing.expect(val != null);
    try std.testing.expectEqual(@as(u64, 0x1234), val.?);
}

test "LabelStack operations" {
    var stack = LabelStack.init();
    defer stack.deinit(std.testing.allocator);

    try stack.push(std.testing.allocator, 0, 0x100, .code_64);
    try std.testing.expectEqual(@as(usize, 1), stack.depth());

    const frame = stack.pop().?;
    try std.testing.expectEqual(@as(u64, 0x100), frame.offset);
    try std.testing.expectEqual(@as(usize, 0), stack.depth());
}
