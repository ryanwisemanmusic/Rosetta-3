const std = @import("std");
const directives = @import("directives.zig");

const Allocator = std.mem.Allocator;

pub const Macro = struct {
    name: []const u8,
    value: []const u8,

    pub fn deinit(self: *Macro, allocator: Allocator) void {
        allocator.free(self.name);
        allocator.free(self.value);
    }
};

pub const Preprocessor = struct {
    allocator: Allocator,
    macros: std.StringHashMap(Macro),
    include_paths: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    output_lines: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },

    pub fn init(allocator: Allocator) Preprocessor {
        return .{
            .allocator = allocator,
            .macros = std.StringHashMap(Macro).init(allocator),
        };
    }

    pub fn deinit(self: *Preprocessor) void {
        var it = self.macros.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.macros.deinit();
        for (self.include_paths.items) |path| self.allocator.free(path);
        self.include_paths.deinit(self.allocator);
        for (self.output_lines.items) |line| self.allocator.free(line);
        self.output_lines.deinit(self.allocator);
    }

    pub fn addIncludePath(self: *Preprocessor, path: []const u8) !void {
        try self.include_paths.append(self.allocator, try self.allocator.dupe(u8, path));
    }

    pub fn define(self: *Preprocessor, name: []const u8, value: []const u8) !void {
        if (self.macros.getPtr(name)) |existing| {
            self.allocator.free(existing.value);
            existing.value = try self.allocator.dupe(u8, value);
            return;
        }
        const key = try self.allocator.dupe(u8, name);
        try self.macros.put(key, .{
            .name = try self.allocator.dupe(u8, name),
            .value = try self.allocator.dupe(u8, value),
        });
    }

    pub fn processSource(self: *Preprocessor, source: []const u8) !void {
        var lines = std.mem.splitScalar(u8, source, '\n');
        while (lines.next()) |raw_line| try self.processLine(raw_line);
    }

    pub fn processLine(self: *Preprocessor, raw_line: []const u8) !void {
        const no_comment = stripComment(raw_line);
        const trimmed = std.mem.trim(u8, no_comment, " \t\r\n");
        if (trimmed.len == 0) return;

        if (trimmed[0] == '%') {
            try self.handleDirective(trimmed[1..]);
            return;
        }

        try self.output_lines.append(self.allocator, try self.allocator.dupe(u8, trimmed));
    }

    fn handleDirective(self: *Preprocessor, line: []const u8) !void {
        const name = directives.firstToken(line);
        const rest = std.mem.trim(u8, line[name.len..], " \t");
        const directive = directives.PreprocDirective.fromString(name) orelse return;
        switch (directive) {
            .define => {
                const macro_name = directives.firstToken(rest);
                if (macro_name.len == 0) return;
                const value = std.mem.trim(u8, rest[macro_name.len..], " \t");
                try self.define(macro_name, value);
            },
            .undef => _ = self.macros.remove(rest),
            .include => try self.output_lines.append(self.allocator, try std.fmt.allocPrint(self.allocator, "%%include {s}", .{rest})),
            .warning_dir => try self.output_lines.append(self.allocator, try std.fmt.allocPrint(self.allocator, "%%warning {s}", .{rest})),
            else => {},
        }
    }
};

pub fn stripComment(line: []const u8) []const u8 {
    var in_single = false;
    var in_double = false;
    for (line, 0..) |ch, i| {
        if (ch == '\'' and !in_double) in_single = !in_single;
        if (ch == '"' and !in_single) in_double = !in_double;
        if (ch == ';' and !in_single and !in_double) return line[0..i];
    }
    return line;
}

test "preprocessor strips comments and defines macros" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processSource(
        \\%define SYS_exit 60
        \\section .text ; comment
    );

    try std.testing.expect(pp.macros.contains("SYS_exit"));
    try std.testing.expectEqual(@as(usize, 1), pp.output_lines.items.len);
    try std.testing.expectEqualStrings("section .text", pp.output_lines.items[0]);
}
