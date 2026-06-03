const std = @import("std");
const nasm = @import("nasm_core.zig");
const directives = @import("directives.zig");

const Allocator = std.mem.Allocator;

pub const Smacro = struct {
    name: []const u8,
    value: []const u8,
    param_count: u32 = 0,
    is_define: bool = false,
    is_vararg: bool = false,
    is_nolist: bool = false,

    pub fn deinit(self: *Smacro, allocator: Allocator) void {
        allocator.free(self.name);
        allocator.free(self.value);
    }
};

pub const MmacroParam = struct {
    name: []const u8,
    default_val: []const u8 = "",

    pub fn deinit(self: *MmacroParam, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.default_val.len > 0) allocator.free(self.default_val);
    }
};

pub const Mmacro = struct {
    name: []const u8,
    params: std.ArrayListUnmanaged(MmacroParam) = .{ .items = &.{}, .capacity = 0 },
    body_lines: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    is_nolist: bool = false,
    is_single_line: bool = false,
    ref_count: u32 = 0,

    pub fn deinit(self: *Mmacro, allocator: Allocator) void {
        allocator.free(self.name);
        for (self.params.items) |*p| p.deinit(allocator);
        self.params.deinit(allocator);
        for (self.body_lines.items) |line| allocator.free(line);
        self.body_lines.deinit(allocator);
    }
};

pub const IfStackEntry = struct {
    kind: IfKind,
    was_true: bool,
    has_else: bool,
    was_skipping: bool,

    const IfKind = enum(u8) {
        if_dir,
        ifdef,
        ifndef,
        ifid,
        ifnid,
        ifidni,
        ifnidni,
        ifmacro,
        ifnmacro,
        ifctx,
        ifnctx,
        ifempty,
        ifnempty,
        ifstr,
        ifnstr,
        ifnum,
        ifnnum,
        elif,
        else_dir,
    };
};

pub const Preprocessor = struct {
    allocator: Allocator,
    smacros: std.StringHashMap(Smacro),
    mmacros: std.StringHashMap(Mmacro),
    if_stack: std.ArrayListUnmanaged(IfStackEntry) = .{ .items = &.{}, .capacity = 0 },
    output_lines: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    expanding: bool = true,
    include_paths: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    macro_level: u32 = 0,

    pub fn init(allocator: Allocator) Preprocessor {
        return Preprocessor{
            .allocator = allocator,
            .smacros = std.StringHashMap(Smacro).init(allocator),
            .mmacros = std.StringHashMap(Mmacro).init(allocator),
        };
    }

    pub fn deinit(self: *Preprocessor) void {
        var sit = self.smacros.iterator();
        while (sit.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.smacros.deinit();
        var mit = self.mmacros.iterator();
        while (mit.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.mmacros.deinit();
        self.if_stack.deinit(self.allocator);
        for (self.output_lines.items) |line| self.allocator.free(line);
        self.output_lines.deinit(self.allocator);
        for (self.include_paths.items) |path| self.allocator.free(path);
        self.include_paths.deinit(self.allocator);
    }

    pub fn processLine(self: *Preprocessor, line: []const u8) !void {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0 or trimmed[0] == ';') return;

        if (trimmed[0] == '%') {
            try self.handleDirective(trimmed);
            return;
        }

        if (self.shouldSkip()) return;

        const expanded = try self.expandSmacros(trimmed);
        if (expanded) |e| {
            try self.emitLine(e);
            self.allocator.free(e);
        } else {
            try self.emitLine(trimmed);
        }
    }

    fn shouldSkip(self: *const Preprocessor) bool {
        var i: usize = self.if_stack.items.len;
        while (i > 0) {
            i -= 1;
            if (!self.if_stack.items[i].was_true) return true;
        }
        return false;
    }

    fn handleDirective(self: *Preprocessor, line: []const u8) !void {
        const first = getToken(line[1..]);
        const rest = std.mem.trim(u8, line[1 + first.len ..], " \t");

        if (std.ascii.eqlIgnoreCase(first, "define") or std.ascii.eqlIgnoreCase(first, "idefine")) {
            try self.defineSmacro(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "undef") or std.ascii.eqlIgnoreCase(first, "iundef")) {
            try self.undefSmacro(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "macro") or std.ascii.eqlIgnoreCase(first, "imacro")) {
            try self.beginMmacro(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "endm")) {
            self.endMmacro();
        } else if (std.ascii.eqlIgnoreCase(first, "if") or
            std.ascii.eqlIgnoreCase(first, "ifdef") or
            std.ascii.eqlIgnoreCase(first, "ifndef") or
            std.ascii.eqlIgnoreCase(first, "ifid") or
            std.ascii.eqlIgnoreCase(first, "ifnid") or
            std.ascii.eqlIgnoreCase(first, "ifidni") or
            std.ascii.eqlIgnoreCase(first, "ifnidni") or
            std.ascii.eqlIgnoreCase(first, "ifctx") or
            std.ascii.eqlIgnoreCase(first, "ifnctx") or
            std.ascii.eqlIgnoreCase(first, "ifempty") or
            std.ascii.eqlIgnoreCase(first, "ifnempty") or
            std.ascii.eqlIgnoreCase(first, "ifstr") or
            std.ascii.eqlIgnoreCase(first, "ifnstr") or
            std.ascii.eqlIgnoreCase(first, "ifnum") or
            std.ascii.eqlIgnoreCase(first, "ifnnum") or
            std.ascii.eqlIgnoreCase(first, "ifmacro") or
            std.ascii.eqlIgnoreCase(first, "ifnmacro"))
        {
            try self.handleIf(first, rest);
        } else if (std.ascii.eqlIgnoreCase(first, "elif") or
            std.ascii.eqlIgnoreCase(first, "elifdef") or
            std.ascii.eqlIgnoreCase(first, "elifndef") or
            std.ascii.eqlIgnoreCase(first, "elifid") or
            std.ascii.eqlIgnoreCase(first, "elifnid") or
            std.ascii.eqlIgnoreCase(first, "elifidni") or
            std.ascii.eqlIgnoreCase(first, "elifnidni") or
            std.ascii.eqlIgnoreCase(first, "elifctx") or
            std.ascii.eqlIgnoreCase(first, "elifnctx") or
            std.ascii.eqlIgnoreCase(first, "elifempty") or
            std.ascii.eqlIgnoreCase(first, "elifnempty") or
            std.ascii.eqlIgnoreCase(first, "elifstr") or
            std.ascii.eqlIgnoreCase(first, "elifnstr") or
            std.ascii.eqlIgnoreCase(first, "elifnum") or
            std.ascii.eqlIgnoreCase(first, "elifnnum") or
            std.ascii.eqlIgnoreCase(first, "elifmacro") or
            std.ascii.eqlIgnoreCase(first, "elifnmacro"))
        {
            try self.handleElif();
        } else if (std.ascii.eqlIgnoreCase(first, "else")) {
            try self.handleElse();
        } else if (std.ascii.eqlIgnoreCase(first, "endif")) {
            try self.handleEndif();
        } else if (std.ascii.eqlIgnoreCase(first, "include")) {
            try self.handleInclude(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "error")) {
            self.handleError(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "warning")) {
            self.handleWarning(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "fatal")) {
            self.handleFatal(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "line")) {
        } else if (std.ascii.eqlIgnoreCase(first, "push")) {
        } else if (std.ascii.eqlIgnoreCase(first, "pop")) {
        } else if (std.ascii.eqlIgnoreCase(first, "rep") or std.ascii.eqlIgnoreCase(first, "irep")) {
        } else if (std.ascii.eqlIgnoreCase(first, "endrep")) {
        } else if (std.ascii.eqlIgnoreCase(first, "exitrep")) {
        } else if (std.ascii.eqlIgnoreCase(first, "strlen")) {
        } else if (std.ascii.eqlIgnoreCase(first, "substr")) {
        } else if (std.ascii.eqlIgnoreCase(first, "xdefine") or std.ascii.eqlIgnoreCase(first, "ixdefine")) {
            try self.defineSmacro(rest);
        } else if (std.ascii.eqlIgnoreCase(first, "alias")) {
        } else if (std.ascii.eqlIgnoreCase(first, "clear")) {
            self.clearSmacros();
        } else {
        }
    }

    fn defineSmacro(self: *Preprocessor, line: []const u8) !void {
        const name = getToken(line);
        if (name.len == 0) return;
        const rest = std.mem.trim(u8, line[name.len..], " \t");

        var param_count: u32 = 0;
        var is_vararg = false;
        var value_start: usize = 0;

        if (rest.len > 0 and rest[0] == '(') {
            const close = findMatching(rest, '(', ')') catch rest.len;
            const params_str = rest[1..close];
            var it = std.mem.splitScalar(u8, params_str, ',');
            while (it.next()) |p| {
                const trimmed_p = std.mem.trim(u8, p, " \t");
                if (trimmed_p.len > 0) {
                    param_count += 1;
                    if (std.ascii.eqlIgnoreCase(trimmed_p, "vararg")) is_vararg = true;
                }
            }
            value_start = close + 1;
        }

        const value = std.mem.trim(u8, rest[value_start..], " \t");

        const key = try self.allocator.dupe(u8, name);
        if (self.smacros.get(key)) |_| {
            self.allocator.free(key);
            return;
        }

        try self.smacros.put(key, Smacro{
            .name = try self.allocator.dupe(u8, name),
            .value = try self.allocator.dupe(u8, value),
            .param_count = param_count,
            .is_define = true,
            .is_vararg = is_vararg,
        });
    }

    fn undefSmacro(self: *Preprocessor, name: []const u8) !void {
        const trimmed = std.mem.trim(u8, name, " \t");
        if (self.smacros.get(trimmed)) |entry| {
            var e = entry;
            e.deinit(self.allocator);
            _ = self.smacros.remove(trimmed);
            self.allocator.free(@constCast(trimmed));
        }
    }

    fn clearSmacros(self: *Preprocessor) void {
        var sit = self.smacros.iterator();
        while (sit.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.smacros.clearRetainingCapacity();
    }

    fn beginMmacro(self: *Preprocessor, line: []const u8) !void {
        _ = self;
        _ = line;
    }

    fn endMmacro(self: *Preprocessor) void {
        _ = self;
    }

    fn handleIf(self: *Preprocessor, directive: []const u8, condition: []const u8) !void {
        const kind: IfStackEntry.IfKind = if (std.ascii.eqlIgnoreCase(directive, "if")) .if_dir else if (std.ascii.eqlIgnoreCase(directive, "ifdef")) .ifdef else if (std.ascii.eqlIgnoreCase(directive, "ifndef")) .ifndef else if (std.ascii.eqlIgnoreCase(directive, "ifid")) .ifid else if (std.ascii.eqlIgnoreCase(directive, "ifnid")) .ifnid else if (std.ascii.eqlIgnoreCase(directive, "ifidni")) .ifidni else if (std.ascii.eqlIgnoreCase(directive, "ifnidni")) .ifnidni else if (std.ascii.eqlIgnoreCase(directive, "ifctx")) .ifctx else if (std.ascii.eqlIgnoreCase(directive, "ifnctx")) .ifnctx else if (std.ascii.eqlIgnoreCase(directive, "ifempty")) .ifempty else if (std.ascii.eqlIgnoreCase(directive, "ifnempty")) .ifnempty else if (std.ascii.eqlIgnoreCase(directive, "ifstr")) .ifstr else if (std.ascii.eqlIgnoreCase(directive, "ifnstr")) .ifnstr else if (std.ascii.eqlIgnoreCase(directive, "ifnum")) .ifnum else if (std.ascii.eqlIgnoreCase(directive, "ifnnum")) .ifnnum else if (std.ascii.eqlIgnoreCase(directive, "ifmacro")) .ifmacro else .ifnmacro;
        const was_true = try self.evaluateIf(kind, condition);
        try self.if_stack.append(self.allocator, IfStackEntry{
            .kind = kind,
            .was_true = was_true,
            .has_else = false,
            .was_skipping = self.shouldSkip(),
        });
    }

    fn evaluateIf(self: *Preprocessor, kind: IfStackEntry.IfKind, condition: []const u8) !bool {
        return switch (kind) {
            .if_dir => blk: {
                const trimmed = std.mem.trim(u8, condition, " \t");
                if (trimmed.len == 0) break :blk false;
                const val = std.fmt.parseInt(i64, trimmed, 0) catch return false;
                break :blk val != 0;
            },
            .ifdef => self.smacros.contains(std.mem.trim(u8, condition, " \t")),
            .ifndef => !self.smacros.contains(std.mem.trim(u8, condition, " \t")),
            else => false,
        };
    }

    fn handleElif(self: *Preprocessor) !void {
        if (self.if_stack.items.len == 0) return;
        const top = &self.if_stack.items[self.if_stack.items.len - 1];
        if (top.has_else) return;
        if (top.was_skipping) return;
        if (top.was_true) {
            top.was_true = false;
        }
    }

    fn handleElse(self: *Preprocessor) !void {
        if (self.if_stack.items.len == 0) return;
        const top = &self.if_stack.items[self.if_stack.items.len - 1];
        if (top.has_else) return;
        top.has_else = true;
        top.was_true = !top.was_true and !top.was_skipping;
    }

    fn handleEndif(self: *Preprocessor) !void {
        if (self.if_stack.items.len > 0) {
            self.if_stack.items.len -= 1;
        }
    }

    fn handleInclude(self: *Preprocessor, path: []const u8) !void {
        const trimmed = std.mem.trim(u8, path, " \t\"<>");
        if (trimmed.len > 0) {
            try self.include_paths.append(self.allocator, try self.allocator.dupe(u8, trimmed));
        }
    }

    fn handleError(self: *Preprocessor, msg: []const u8) void {
        _ = self;
        _ = msg;
    }

    fn handleWarning(self: *Preprocessor, msg: []const u8) void {
        _ = self;
        _ = msg;
    }

    fn handleFatal(self: *Preprocessor, msg: []const u8) void {
        _ = self;
        _ = msg;
    }

    fn expandSmacros(self: *Preprocessor, line: []const u8) !?[]const u8 {
        _ = self;
        _ = line;
        return null;
    }

    fn emitLine(self: *Preprocessor, text: []const u8) !void {
        try self.output_lines.append(self.allocator, try self.allocator.dupe(u8, text));
    }
};

fn getToken(s: []const u8) []const u8 {
    var start: usize = 0;
    while (start < s.len and (s[start] == ' ' or s[start] == '\t')) {
        start += 1;
    }
    if (start >= s.len) return "";
    var end = start;
    if (nasm_isidstart(s[start])) {
        end += 1;
        while (end < s.len and nasm_isidchar(s[end])) {
            end += 1;
        }
    } else {
        end += 1;
    }
    return s[start..end];
}

fn nasm_isidstart(c: u8) bool {
    return std.ascii.isAlphabetic(c) or c == '_' or c == '.' or c == '?' or c == '@';
}

fn nasm_isidchar(c: u8) bool {
    return nasm_isidstart(c) or std.ascii.isDigit(c) or c == '$' or c == '#' or c == '~';
}

fn findMatching(s: []const u8, open: u8, close: u8) !usize {
    var depth: usize = 0;
    for (s, 0..) |ch, i| {
        if (ch == open) depth += 1;
        if (ch == close) {
            if (depth == 0) return i;
            depth -= 1;
        }
    }
    return error.UnmatchedBracket;
}

test "token extraction" {
    try std.testing.expectEqualStrings("define", getToken("define foo bar"));
    try std.testing.expectEqualStrings("ifdef", getToken("ifdef MY_SYMBOL"));
}

test "smacro define and lookup" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("%define foo 42");
    try std.testing.expect(pp.smacros.contains("foo"));
}

test "conditional assembly" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("%if 0");
    try pp.processLine("mov ax, bx");
    try pp.processLine("%endif");
    try std.testing.expectEqual(@as(usize, 0), pp.output_lines.items.len);
}

test "pass through normal lines" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("mov ax, bx");
    try std.testing.expectEqual(@as(usize, 1), pp.output_lines.items.len);
}
