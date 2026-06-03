const std = @import("std");
const fasm = @import("fasm_core.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;

pub const PreprocessorState = enum(u8) {
    normal = 0,
    if_block_skip = 1,
    else_block = 2,
};

pub const PreprocessorDirective = enum(u8) {
    none = 0,
    @"if" = 1,
    @"ifdef" = 2,
    @"ifndef" = 3,
    @"else if" = 4,
    @"else" = 5,
    @"end if" = 6,
    @"include" = 7,
    @"macro" = 8,
    @"end macro" = 9,
    @"purge" = 10,
    @"match" = 11,
    @"restore" = 12,
    @"assert" = 13,
    @"fix" = 14,
    _,
};

pub const Preprocessor = struct {
    allocator: Allocator,
    lines: std.ArrayListUnmanaged(PreprocessedOutput) = .{ .items = &.{}, .capacity = 0 },
    if_nesting: std.ArrayListUnmanaged(IfState) = .{ .items = &.{}, .capacity = 0 },
    macro_definitions: std.StringHashMap(MacroDefinition),
    include_paths: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    state: PreprocessorState = .normal,

    const PreprocessedOutput = struct {
        text: []const u8,
        file_ref: u32,
        line_number: u32,
    };

    const IfState = struct {
        was_true: bool,
        has_else: bool,
    };

    const MacroDefinition = struct {
        name: []const u8,
        parameters: []const []const u8,
        body: []const u8,
        line_number: u32,
    };

    pub fn init(allocator: Allocator) Preprocessor {
        return Preprocessor{
            .allocator = allocator,
            .lines = .{ .items = &.{}, .capacity = 0 },
            .if_nesting = .{ .items = &.{}, .capacity = 0 },
            .macro_definitions = std.StringHashMap(MacroDefinition).init(allocator),
            .include_paths = .{ .items = &.{}, .capacity = 0 },
        };
    }

    pub fn deinit(self: *Preprocessor) void {
        for (self.lines.items) |line| {
            self.allocator.free(line.text);
        }
        self.lines.deinit(self.allocator);
        self.if_nesting.deinit(self.allocator);
        var it = self.macro_definitions.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.macro_definitions.deinit();
        for (self.include_paths.items) |path| {
            self.allocator.free(path);
        }
        self.include_paths.deinit(self.allocator);
    }

    pub fn addIncludePath(self: *Preprocessor, path: []const u8) !void {
        try self.include_paths.append(self.allocator, try self.allocator.dupe(u8, path));
    }

    pub fn processLine(self: *Preprocessor, line: []const u8, file_ref: u32, line_number: u32) !void {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0) {
            try self.lines.append(self.allocator, .{
                .text = "",
                .file_ref = file_ref,
                .line_number = line_number,
            });
            return;
        }

        if (trimmed[0] == ';') return;

        if (trimmed[0] == '#') {
            try self.handleDirective(trimmed, file_ref, line_number);
            return;
        }

        switch (self.state) {
            .if_block_skip => {},
            .else_block, .normal => {
                try self.lines.append(self.allocator, .{
                    .text = try self.allocator.dupe(u8, trimmed),
                    .file_ref = file_ref,
                    .line_number = line_number,
                });
            },
        }
    }

    fn handleDirective(self: *Preprocessor, line: []const u8, _file_ref: u32, _line_number: u32) !void {
        const directive_line = std.mem.trim(u8, line["#".len..], " \t");
        if (directive_line.len == 0) return;

        const space_pos = std.mem.indexOfScalar(u8, directive_line, ' ') orelse
            std.mem.indexOfScalar(u8, directive_line, '\t') orelse directive_line.len;

        const directive_name = directive_line[0..space_pos];
        const args = std.mem.trim(u8, directive_line[space_pos..], " \t");

        if (std.ascii.eqlIgnoreCase(directive_name, "if")) {
            try self.if_nesting.append(self.allocator, .{
                .was_true = (args.len > 0),
                .has_else = false,
            });
            if (args.len == 0) {
                self.state = .if_block_skip;
            }
        } else if (std.ascii.eqlIgnoreCase(directive_name, "ifdef")) {
            const defined = self.macro_definitions.contains(args);
            try self.if_nesting.append(self.allocator, .{
                .was_true = defined,
                .has_else = false,
            });
            if (!defined) {
                self.state = .if_block_skip;
            }
        } else if (std.ascii.eqlIgnoreCase(directive_name, "ifndef")) {
            const defined = self.macro_definitions.contains(args);
            try self.if_nesting.append(self.allocator, .{
                .was_true = !defined,
                .has_else = false,
            });
            if (defined) {
                self.state = .if_block_skip;
            }
        } else if (std.ascii.eqlIgnoreCase(directive_name, "else")) {
            if (self.if_nesting.items.len > 0) {
                const top = &self.if_nesting.items[self.if_nesting.items.len - 1];
                if (top.has_else) return;
                top.has_else = true;
                if (top.was_true) {
                    self.state = .if_block_skip;
                } else {
                    self.state = .else_block;
                }
            }
        } else if (std.ascii.eqlIgnoreCase(directive_name, "end") or
                   std.ascii.eqlIgnoreCase(directive_name, "endif")) {
            if (self.if_nesting.items.len > 0) {
                _ = self.if_nesting.pop();
                self.state = if (self.if_nesting.items.len > 0 and
                    self.if_nesting.items[self.if_nesting.items.len - 1].was_true)
                    .else_block else .normal;
            }
        } else if (std.ascii.eqlIgnoreCase(directive_name, "include")) {
            _ = @as([]const u8, args);
            _ = @as(u32, _file_ref);
            _ = @as(u32, _line_number);
        }
    }
};

pub fn isMacroDefinition(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \t\r\n");
    return std.ascii.startsWithIgnoreCase(trimmed, "macro ") or
        std.ascii.startsWithIgnoreCase(trimmed, "#macro ");
}

test "preprocessor basic line handling" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("mov eax, 1", 0, 1);
    try std.testing.expectEqual(@as(usize, 1), pp.lines.items.len);
}

test "preprocessor comment lines" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("; comment", 0, 1);
    try std.testing.expectEqual(@as(usize, 0), pp.lines.items.len);
}

test "preprocessor ifdef directive" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("#ifdef UNDEFINED", 0, 1);
    try pp.processLine("mov eax, 1", 0, 2);
    try pp.processLine("#endif", 0, 3);
    try std.testing.expectEqual(@as(usize, 0), pp.lines.items.len);
}
