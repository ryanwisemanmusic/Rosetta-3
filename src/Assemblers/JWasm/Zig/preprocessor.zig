const std = @import("std");
const jwasm = @import("jwasm_core.zig");

const Allocator = std.mem.Allocator;

pub const Macro = struct {
    name: []const u8,
    parameters: std.ArrayListUnmanaged(MacroParam) = .{ .items = &.{}, .capacity = 0 },
    locals: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    body_lines: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    is_builtin: bool = false,
    is_func: bool = false,
    has_vararg: bool = false,
    purged: bool = false,
    srcfile: u32 = 0,

    const MacroParam = struct {
        name: []const u8,
        default_value: []const u8 = "",
        is_required: bool = true,
    };

    pub fn deinit(self: *Macro, allocator: Allocator) void {
        self.parameters.deinit(allocator);
        self.locals.deinit(allocator);
        self.body_lines.deinit(allocator);
    }
};

pub const TextEquate = struct {
    name: []const u8,
    value: []const u8,
    is_variable: bool = false,
};

pub const IfState = struct {
    kind: IfKind,
    was_true: bool,
    has_else: bool,

    const IfKind = enum(u8) {
        if_ = 0,
        ifdef = 1,
        ifndef = 2,
        ifb = 3,
        ifnb = 4,
        ifidn = 5,
        ifidni = 6,
        ifdif = 7,
        ifdifi = 8,
        ife = 9,
        if1 = 10,
        if2 = 11,
        elseif = 12,
        elseifdef = 13,
        elseifndef = 14,
        elseifb = 15,
        elseifnb = 16,
        elseifidn = 17,
        elseifidni = 18,
        elseifdif = 19,
        elseifdifi = 20,
        elseife = 21,
        elseif1 = 22,
        elseif2 = 23,
    };
};

pub const GotoState = struct {
    label: []const u8,
    active: bool = false,
};

pub const Preprocessor = struct {
    allocator: Allocator,
    output_lines: std.ArrayListUnmanaged(Line) = .{ .items = &.{}, .capacity = 0 },
    macros: std.StringHashMap(Macro),
    text_equates: std.StringHashMap(TextEquate),
    if_stack: std.ArrayListUnmanaged(IfState) = .{ .items = &.{}, .capacity = 0 },
    goto_labels: std.StringHashMap(u32),
    expand_macros: bool = true,
    pass_number: u8 = 1,
    macro_level: u8 = 0,
    inside_repeat: u32 = 0,

    const Line = struct {
        text: []const u8,
        file_index: u32,
        line_number: u32,
        is_macro_expansion: bool,
    };

    pub fn init(allocator: Allocator) Preprocessor {
        return Preprocessor{
            .allocator = allocator,
            .macros = std.StringHashMap(Macro).init(allocator),
            .text_equates = std.StringHashMap(TextEquate).init(allocator),
            .goto_labels = std.StringHashMap(u32).init(allocator),
        };
    }

    pub fn deinit(self: *Preprocessor) void {
        for (self.output_lines.items) |line| {
            self.allocator.free(line.text);
        }
        self.output_lines.deinit(self.allocator);
        var mit = self.macros.iterator();
        while (mit.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
        }
        self.macros.deinit();
        self.text_equates.deinit();
        self.if_stack.deinit(self.allocator);
        self.goto_labels.deinit();
    }

    pub fn processLine(self: *Preprocessor, line: []const u8, file_index: u32, line_number: u32) !void {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");

        if (trimmed.len == 0 or trimmed[0] == ';') {
            try self.emitLine(line, file_index, line_number);
            return;
        }

        const first_token = getToken(trimmed);
        const is_cond = self.isConditionalToken(first_token);

        if (self.isDirective(trimmed)) {
            if (!self.shouldSkip() or is_cond) {
                try self.handleDirective(trimmed, file_index, line_number);
            }
            return;
        }

        if (self.shouldSkip()) return;

        if (self.expand_macros and self.macros.contains(first_token)) {
            try self.expandMacro(trimmed, file_index, line_number);
            return;
        }

        const expanded = try self.expandTextEquates(trimmed);
        if (expanded) |e| {
            try self.emitLineWithMacro(e, file_index, line_number, false);
            self.allocator.free(e);
        } else {
            try self.emitLineWithMacro(trimmed, file_index, line_number, false);
        }
    }

    fn isConditionalToken(self: *Preprocessor, token: []const u8) bool {
        _ = self;
        return std.ascii.eqlIgnoreCase(token, "IF") or
            std.ascii.eqlIgnoreCase(token, "IFDEF") or
            std.ascii.eqlIgnoreCase(token, "IFNDEF") or
            std.ascii.eqlIgnoreCase(token, "IFB") or
            std.ascii.eqlIgnoreCase(token, "IFNB") or
            std.ascii.eqlIgnoreCase(token, "IFIDN") or
            std.ascii.eqlIgnoreCase(token, "IFIDNI") or
            std.ascii.eqlIgnoreCase(token, "IFDIF") or
            std.ascii.eqlIgnoreCase(token, "IFDIFI") or
            std.ascii.eqlIgnoreCase(token, "IFE") or
            std.ascii.eqlIgnoreCase(token, "IF1") or
            std.ascii.eqlIgnoreCase(token, "IF2") or
            std.ascii.eqlIgnoreCase(token, "ELSE") or
            std.ascii.eqlIgnoreCase(token, "ELSEIF") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFE") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFDEF") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFNDEF") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFB") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFNB") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFIDN") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFIDNI") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFDIF") or
            std.ascii.eqlIgnoreCase(token, "ELSEIFDIFI") or
            std.ascii.eqlIgnoreCase(token, "ELSEIF1") or
            std.ascii.eqlIgnoreCase(token, "ELSEIF2") or
            std.ascii.eqlIgnoreCase(token, "ENDIF");
    }

    fn isDirective(self: *Preprocessor, line: []const u8) bool {
        const first = getToken(line);
        return self.isConditionalToken(first) or
            std.ascii.eqlIgnoreCase(first, "MACRO") or
            std.ascii.eqlIgnoreCase(first, "ENDM") or
            std.ascii.eqlIgnoreCase(first, "EXITM") or
            std.ascii.eqlIgnoreCase(first, "GOTO") or
            std.ascii.eqlIgnoreCase(first, "LOCAL") or
            std.ascii.eqlIgnoreCase(first, "PURGE") or
            std.ascii.eqlIgnoreCase(first, "INCLUDE") or
            std.ascii.eqlIgnoreCase(first, "ECHO") or
            std.ascii.eqlIgnoreCase(first, "%OUT") or
            std.ascii.eqlIgnoreCase(first, "CATSTR") or
            std.ascii.eqlIgnoreCase(first, "INSTR") or
            std.ascii.eqlIgnoreCase(first, "SUBSTR") or
            std.ascii.eqlIgnoreCase(first, "SIZESTR") or
            std.ascii.eqlIgnoreCase(first, "TEXTEQU") or
            std.ascii.eqlIgnoreCase(first, "=") or
            std.ascii.eqlIgnoreCase(first, "EQU") or
            std.ascii.eqlIgnoreCase(first, "REPEAT") or
            std.ascii.eqlIgnoreCase(first, "REPT") or
            std.ascii.eqlIgnoreCase(first, "WHILE") or
            std.ascii.eqlIgnoreCase(first, "FOR") or
            std.ascii.eqlIgnoreCase(first, "FORC") or
            std.ascii.eqlIgnoreCase(first, "IRP") or
            std.ascii.eqlIgnoreCase(first, "IRPC");
    }

    fn handleDirective(self: *Preprocessor, line: []const u8, _file_index: u32, _line_number: u32) !void {
        _ = _file_index;
        _ = _line_number;
        const directive = getToken(line);
        const rest = std.mem.trim(u8, line[directive.len..], " \t");

        if (std.ascii.eqlIgnoreCase(directive, "MACRO")) {
            try self.defineMacro(line);
        } else if (std.ascii.eqlIgnoreCase(directive, "ENDM")) {
            if (self.macro_level > 0) self.macro_level -= 1;
        } else if (std.ascii.eqlIgnoreCase(directive, "EXITM") or std.ascii.eqlIgnoreCase(directive, "GOTO")) {} else if (std.ascii.eqlIgnoreCase(directive, "IF") or
            std.ascii.eqlIgnoreCase(directive, "IFDEF") or
            std.ascii.eqlIgnoreCase(directive, "IFNDEF") or
            std.ascii.eqlIgnoreCase(directive, "IFB") or
            std.ascii.eqlIgnoreCase(directive, "IFNB") or
            std.ascii.eqlIgnoreCase(directive, "IFIDN") or
            std.ascii.eqlIgnoreCase(directive, "IFIDNI") or
            std.ascii.eqlIgnoreCase(directive, "IFDIF") or
            std.ascii.eqlIgnoreCase(directive, "IFDIFI") or
            std.ascii.eqlIgnoreCase(directive, "IFE") or
            std.ascii.eqlIgnoreCase(directive, "IF1") or
            std.ascii.eqlIgnoreCase(directive, "IF2"))
        {
            try self.handleIf(directive, rest);
        } else if (std.ascii.eqlIgnoreCase(directive, "ELSE") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIF") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFE") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFDEF") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFNDEF") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFB") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFNB") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFIDN") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFIDNI") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFDIF") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIFDIFI") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIF1") or
            std.ascii.eqlIgnoreCase(directive, "ELSEIF2"))
        {
            if (self.if_stack.items.len > 0) {
                const top = &self.if_stack.items[self.if_stack.items.len - 1];
                if (top.has_else) return;
                top.has_else = true;
                top.was_true = !top.was_true;
            }
        } else if (std.ascii.eqlIgnoreCase(directive, "ENDIF")) {
            if (self.if_stack.items.len > 0) {
                self.if_stack.items.len -= 1;
            }
        } else if (std.ascii.eqlIgnoreCase(directive, "INCLUDE") or
            std.ascii.eqlIgnoreCase(directive, "ECHO") or
            std.ascii.eqlIgnoreCase(directive, "%OUT") or
            std.ascii.eqlIgnoreCase(directive, "TEXTEQU") or
            std.ascii.eqlIgnoreCase(directive, "=") or
            std.ascii.eqlIgnoreCase(directive, "EQU"))
        {}
    }

    fn defineMacro(self: *Preprocessor, line: []const u8) !void {
        const directive = getToken(line);
        const rest = std.mem.trim(u8, line[directive.len..], " \t");
        const name = getToken(rest);
        if (name.len == 0) return;
        const macro = Macro{
            .name = try self.allocator.dupe(u8, name),
        };
        try self.macros.put(try self.allocator.dupe(u8, name), macro);
        self.macro_level += 1;
    }

    fn handleIf(self: *Preprocessor, directive: []const u8, condition_text: []const u8) !void {
        const kind: IfState.IfKind = if (std.ascii.eqlIgnoreCase(directive, "IF")) .if_ else if (std.ascii.eqlIgnoreCase(directive, "IFDEF")) .ifdef else if (std.ascii.eqlIgnoreCase(directive, "IFNDEF")) .ifndef else if (std.ascii.eqlIgnoreCase(directive, "IFB")) .ifb else if (std.ascii.eqlIgnoreCase(directive, "IFNB")) .ifnb else if (std.ascii.eqlIgnoreCase(directive, "IFIDN")) .ifidn else if (std.ascii.eqlIgnoreCase(directive, "IFIDNI")) .ifidni else if (std.ascii.eqlIgnoreCase(directive, "IFDIF")) .ifdif else if (std.ascii.eqlIgnoreCase(directive, "IFDIFI")) .ifdifi else if (std.ascii.eqlIgnoreCase(directive, "IFE")) .ife else if (std.ascii.eqlIgnoreCase(directive, "IF1")) .if1 else .if2;
        const was_true = if (kind == .if_) try self.evaluateIfCondition(condition_text) else kind == .if1;
        try self.if_stack.append(self.allocator, IfState{
            .kind = kind,
            .was_true = was_true,
            .has_else = false,
        });
    }

    fn evaluateIfCondition(self: *Preprocessor, condition_text: []const u8) !bool {
        _ = self;
        const trimmed = std.mem.trim(u8, condition_text, " \t");
        if (trimmed.len == 0) return false;
        const val = std.fmt.parseInt(i32, trimmed, 0) catch return false;
        return val != 0;
    }

    fn expandMacro(self: *Preprocessor, _line: []const u8, _file_index: u32, _line_number: u32) !void {
        _ = self;
        _ = _line;
        _ = _file_index;
        _ = _line_number;
    }

    fn expandTextEquates(self: *Preprocessor, line: []const u8) !?[]const u8 {
        _ = self;
        _ = line;
        return null;
    }

    fn shouldSkip(self: *const Preprocessor) bool {
        var i: usize = self.if_stack.items.len;
        while (i > 0) {
            i -= 1;
            const state = self.if_stack.items[i];
            if (!state.was_true) return true;
        }
        return false;
    }

    fn emitLine(self: *Preprocessor, text: []const u8, file_index: u32, line_number: u32) !void {
        try self.emitLineWithMacro(text, file_index, line_number, false);
    }

    fn emitLineWithMacro(self: *Preprocessor, text: []const u8, file_index: u32, line_number: u32, is_macro_expansion: bool) !void {
        try self.output_lines.append(self.allocator, Line{
            .text = try self.allocator.dupe(u8, text),
            .file_index = file_index,
            .line_number = line_number,
            .is_macro_expansion = is_macro_expansion,
        });
    }
};

fn getToken(s: []const u8) []const u8 {
    var start: usize = 0;
    while (start < s.len and (s[start] == ' ' or s[start] == '\t')) {
        start += 1;
    }
    const trimmed = s[start..];
    if (trimmed.len == 0) return "";
    var i: usize = 0;
    while (i < trimmed.len and trimmed[i] != ' ' and trimmed[i] != '\t') {
        i += 1;
    }
    return trimmed[0..i];
}

test "token extraction" {
    try std.testing.expectEqualStrings("MACRO", getToken("MACRO test a,b"));
    try std.testing.expectEqualStrings("IFDEF", getToken("IFDEF MY_SYMBOL"));
    try std.testing.expectEqualStrings("REPEAT", getToken("REPEAT 10"));
}

test "preprocessor conditional assembly" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("IF 0", 0, 1);
    try pp.processLine("mov ax, bx", 0, 2);
    try pp.processLine("ENDIF", 0, 3);
    try std.testing.expectEqual(@as(usize, 0), pp.output_lines.items.len);
}

test "preprocessor passes through normal lines" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("mov ax, bx", 0, 1);
    try std.testing.expectEqual(@as(usize, 1), pp.output_lines.items.len);
}

test "preprocessor ELSE clause" {
    var pp = Preprocessor.init(std.testing.allocator);
    defer pp.deinit();

    try pp.processLine("IF 0", 0, 1);
    try pp.processLine("nop", 0, 2);
    try pp.processLine("ELSE", 0, 3);
    try pp.processLine("mov ax, bx", 0, 4);
    try pp.processLine("ENDIF", 0, 5);
    try std.testing.expectEqual(@as(usize, 1), pp.output_lines.items.len);
}
