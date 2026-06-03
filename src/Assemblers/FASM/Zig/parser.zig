const std = @import("std");
const fasm = @import("fasm_core.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;

pub const ParsedLine = struct {
    label: []const u8 = "",
    instruction: []const u8 = "",
    operands: []const []const u8 = &.{},
    directive: Directive = .none,
    is_data: bool = false,
    data_type: DataType = .none,
    raw_line: []const u8 = "",
    line_number: u32 = 0,

    pub fn deinit(self: *const ParsedLine, _: Allocator) void {
        const page = std.heap.page_allocator;
        if (self.label.len > 0) page.free(self.label);
        if (self.instruction.len > 0) page.free(self.instruction);
        for (self.operands) |op| {
            page.free(op);
        }
        page.free(self.operands);
    }
};

pub const Directive = enum(u8) {
    none = 0,
    section = 1,
    segment = 2,
    @"org" = 3,
    use16 = 4,
    use32 = 5,
    use64 = 6,
    @"format" = 7,
    @"align" = 8,
    @"if" = 9,
    @"ifdef" = 10,
    @"ifndef" = 11,
    @"else" = 12,
    @"end if" = 13,
    include = 14,
    macro = 15,
    @"end macro" = 16,
    purge = 17,
    match = 18,
    restore = 19,
    @"assert" = 20,
    @"fix" = 21,
    repeat = 22,
    @"while" = 23,
    @"for" = 24,
    @"irp" = 25,
    @"irps" = 26,
    @"indx" = 27,
    match_exact = 28,
    virtual = 29,
    @"end virtual" = 30,
    load = 31,
    store = 32,
    @"record" = 33,
    namesake = 34,
    post_processed = 35,
    _,
};

pub const DataType = enum(u8) {
    none = 0,
    db = 1,
    dw = 2,
    dd = 4,
    dq = 8,
    dt = 10,
    dp = 6,
    @"file" = 255,
    _,
};

pub const SourceParser = struct {
    source: []const u8,
    position: usize = 0,
    line_number: u32 = 1,
    column: u32 = 0,

    pub fn init(source: []const u8) SourceParser {
        return SourceParser{ .source = source };
    }

    pub fn parseLine(self: *SourceParser) !?ParsedLine {
        self.skipEmptyLines();
        if (self.position >= self.source.len) return null;

        _ = self.position;
        const raw_line = self.readLine();

        var result = ParsedLine{
            .raw_line = raw_line,
            .line_number = self.line_number,
        };

        var line = raw_line;

        if (std.mem.indexOfScalar(u8, line, ';')) |comment_start| {
            line = line[0..comment_start];
        }

        line = std.mem.trim(u8, line, " \t\r");

        if (line.len == 0) {
            self.line_number += 1;
            return result;
        }

        const bracket_count = countChar(line, '{');
        const rbracket_count = countChar(line, '}');
        if (bracket_count != rbracket_count) return errors.AssemblerError.InvalidExpression;

        const colon_pos = findColonNotInBrackets(line);
        if (colon_pos) |pos| {
            result.label = try std.heap.page_allocator.dupe(u8, std.mem.trim(u8, line[0..pos], " \t"));
            line = std.mem.trim(u8, line[pos + 1 ..], " \t");
        }

        if (line.len == 0) {
            self.line_number += 1;
            return result;
        }

        var space_pos: ?usize = null;
        var depth: usize = 0;
        for (line, 0..) |ch, i| {
            switch (ch) {
                '(', '[', '{' => depth += 1,
                ')', ']', '}' => depth -= 1,
                ' ', '\t' => if (depth == 0 and space_pos == null) {
                    space_pos = i;
                    break;
                },
                else => {},
            }
        }

        if (space_pos) |pos| {
            result.instruction = try std.heap.page_allocator.dupe(u8, std.mem.trim(u8, line[0..pos], " \t"));

            const operands_str = std.mem.trim(u8, line[pos + 1 ..], " \t");
            if (operands_str.len > 0) {
                result.operands = try splitOperands(operands_str);
            }

            self.checkDirective(&result);
            self.checkDataType(&result);
        } else {
            result.instruction = try std.heap.page_allocator.dupe(u8, line);
            self.checkDirective(&result);
        }

        self.line_number += 1;
        return result;
    }

    fn skipEmptyLines(self: *SourceParser) void {
        while (self.position < self.source.len) {
            var i = self.position;
            var is_empty = true;
            while (i < self.source.len and self.source[i] != '\n') {
                if (self.source[i] != ' ' and self.source[i] != '\t' and self.source[i] != '\r') {
                    if (self.source[i] != ';') {
                        is_empty = false;
                        break;
                    }
                    while (i < self.source.len and self.source[i] != '\n') i += 1;
                }
                i += 1;
            }
            if (is_empty) {
                while (self.position < self.source.len and self.source[self.position] != '\n') {
                    self.position += 1;
                }
                if (self.position < self.source.len) self.position += 1;
                self.line_number += 1;
            } else {
                break;
            }
        }
    }

    fn readLine(self: *SourceParser) []const u8 {
        const start = self.position;
        while (self.position < self.source.len and self.source[self.position] != '\n') {
            self.position += 1;
        }
        const line = self.source[start..self.position];
        if (self.position < self.source.len) self.position += 1;
        return line;
    }

    fn checkDirective(_: *SourceParser, line: *ParsedLine) void {
        const inst = line.instruction;
        if (std.ascii.eqlIgnoreCase(inst, "section") or std.ascii.eqlIgnoreCase(inst, "segment")) {
            line.directive = .section;
        } else if (std.ascii.eqlIgnoreCase(inst, "org")) {
            line.directive = .@"org";
        } else if (std.ascii.eqlIgnoreCase(inst, "use16")) {
            line.directive = .use16;
        } else if (std.ascii.eqlIgnoreCase(inst, "use32")) {
            line.directive = .use32;
        } else if (std.ascii.eqlIgnoreCase(inst, "use64")) {
            line.directive = .use64;
        } else if (std.ascii.eqlIgnoreCase(inst, "format")) {
            line.directive = .format;
        } else if (std.ascii.eqlIgnoreCase(inst, "align")) {
            line.directive = .@"align";
        } else if (std.ascii.eqlIgnoreCase(inst, "virtual")) {
            line.directive = .virtual;
        } else if (std.ascii.eqlIgnoreCase(inst, "end virtual")) {
            line.directive = .@"end virtual";
        } else if (std.ascii.eqlIgnoreCase(inst, "repeat")) {
            line.directive = .repeat;
        } else if (std.ascii.eqlIgnoreCase(inst, "while")) {
            line.directive = .@"while";
        } else if (std.ascii.eqlIgnoreCase(inst, "if")) {
            line.directive = .@"if";
        } else if (std.ascii.eqlIgnoreCase(inst, "else")) {
            line.directive = .@"else";
        } else if (std.ascii.eqlIgnoreCase(inst, "end if")) {
            line.directive = .@"end if";
        } else if (std.ascii.eqlIgnoreCase(inst, "include")) {
            line.directive = .include;
        } else if (std.ascii.eqlIgnoreCase(inst, "macro")) {
            line.directive = .macro;
        } else if (std.ascii.eqlIgnoreCase(inst, "end macro")) {
            line.directive = .@"end macro";
        } else if (std.ascii.eqlIgnoreCase(inst, "purge")) {
            line.directive = .purge;
        } else if (std.ascii.eqlIgnoreCase(inst, "match")) {
            line.directive = .match;
        } else if (std.ascii.eqlIgnoreCase(inst, "assert")) {
            line.directive = .@"assert";
        } else if (std.ascii.eqlIgnoreCase(inst, "fix")) {
            line.directive = .@"fix";
        } else if (std.ascii.eqlIgnoreCase(inst, "load")) {
            line.directive = .load;
        } else if (std.ascii.eqlIgnoreCase(inst, "store")) {
            line.directive = .store;
        }
    }

    fn checkDataType(_: *SourceParser, line: *ParsedLine) void {
        const inst = line.instruction;
        if (std.ascii.eqlIgnoreCase(inst, "db")) {
            line.is_data = true;
            line.data_type = .db;
        } else if (std.ascii.eqlIgnoreCase(inst, "dw")) {
            line.is_data = true;
            line.data_type = .dw;
        } else if (std.ascii.eqlIgnoreCase(inst, "dd")) {
            line.is_data = true;
            line.data_type = .dd;
        } else if (std.ascii.eqlIgnoreCase(inst, "dq")) {
            line.is_data = true;
            line.data_type = .dq;
        } else if (std.ascii.eqlIgnoreCase(inst, "dt")) {
            line.is_data = true;
            line.data_type = .dt;
        } else if (std.ascii.eqlIgnoreCase(inst, "file")) {
            line.is_data = true;
            line.data_type = .@"file";
        }
    }
};

fn countChar(s: []const u8, ch: u8) usize {
    var count: usize = 0;
    for (s) |c| {
        if (c == ch) count += 1;
    }
    return count;
}

fn findColonNotInBrackets(s: []const u8) ?usize {
    var depth: usize = 0;
    for (s, 0..) |ch, i| {
        switch (ch) {
            '(', '[', '{' => depth += 1,
            ')', ']', '}' => {
                if (depth > 0) depth -= 1;
            },
            ':' => if (depth == 0 and (i + 1 >= s.len or s[i + 1] != ':')) return i,
            else => {},
        }
    }
    return null;
}

fn splitOperands(s: []const u8) ![]const []const u8 {
    const allocator = std.heap.page_allocator;
    var operands: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 };
    defer operands.deinit(allocator);

    var depth: usize = 0;
    var start: usize = 0;

    for (s, 0..) |ch, i| {
        switch (ch) {
            '(', '[', '{' => depth += 1,
            ')', ']', '}' => {
                if (depth > 0) depth -= 1;
            },
            ',' => if (depth == 0) {
                const operand = std.mem.trim(u8, s[start..i], " \t");
                if (operand.len > 0) {
                    try operands.append(allocator, try allocator.dupe(u8, operand));
                }
                start = i + 1;
            },
            else => {},
        }
    }

    const last = std.mem.trim(u8, s[start..], " \t");
    if (last.len > 0) {
        try operands.append(allocator, try allocator.dupe(u8, last));
    }

    return operands.toOwnedSlice(allocator);
}

test "parse simple instruction" {
    var parser = SourceParser.init("mov eax, ebx\n");
    const line = (try parser.parseLine()).?;
    try std.testing.expectEqualStrings("mov", line.instruction);
    try std.testing.expectEqual(@as(usize, 2), line.operands.len);
    try std.testing.expectEqualStrings("eax", line.operands[0]);
    try std.testing.expectEqualStrings("ebx", line.operands[1]);
    try std.testing.expectEqual(@as(u32, 1), line.line_number);
}

test "parse with label" {
    var parser = SourceParser.init("start:\n");
    const line = (try parser.parseLine()).?;
    try std.testing.expectEqualStrings("start", line.label);
}

test "parse data directive" {
    var parser = SourceParser.init("db 0x90\n");
    const line = (try parser.parseLine()).?;
    try std.testing.expect(line.is_data);
    try std.testing.expectEqual(@as(DataType, .db), line.data_type);
}

test "parse directive" {
    var parser = SourceParser.init("use64\n");
    const line = (try parser.parseLine()).?;
    try std.testing.expectEqual(@as(Directive, .use64), line.directive);
}

test "operand with brackets" {
    var parser = SourceParser.init("mov eax, [ebx + ecx]\n");
    const line = (try parser.parseLine()).?;
    try std.testing.expectEqual(@as(usize, 2), line.operands.len);
    try std.testing.expectEqualStrings("eax", line.operands[0]);
    try std.testing.expectEqualStrings("[ebx + ecx]", line.operands[1]);
}

test "comments are preserved" {
    var parser = SourceParser.init("mov eax, 1 ; comment\n");
    const line = (try parser.parseLine()).?;
    try std.testing.expectEqualStrings("mov", line.instruction);
}
