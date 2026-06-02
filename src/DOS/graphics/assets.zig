const std = @import("std");

pub const TextAsset = struct {
    name: []u8,
    text: []u8,
};

pub const ScalarAsset = struct {
    name: []u8,
    value: i64,
};

pub const AssetBundle = struct {
    allocator: std.mem.Allocator,
    texts: []TextAsset,
    scalars: []ScalarAsset,

    pub fn deinit(self: *AssetBundle) void {
        for (self.texts) |entry| {
            self.allocator.free(entry.name);
            self.allocator.free(entry.text);
        }
        self.allocator.free(self.texts);

        for (self.scalars) |entry| {
            self.allocator.free(entry.name);
        }
        self.allocator.free(self.scalars);
    }

    pub fn findText(self: AssetBundle, name: []const u8) ?[]const u8 {
        for (self.texts) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.name, name)) return entry.text;
        }
        return null;
    }

    pub fn findScalar(self: AssetBundle, name: []const u8) ?i64 {
        for (self.scalars) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.name, name)) return entry.value;
        }
        return null;
    }
};

pub fn parseDosAsmSource(allocator: std.mem.Allocator, source: []const u8) !AssetBundle {
    var texts: std.ArrayListUnmanaged(TextAsset) = .empty;
    var scalars: std.ArrayListUnmanaged(ScalarAsset) = .empty;
    errdefer {
        for (texts.items) |entry| {
            allocator.free(entry.name);
            allocator.free(entry.text);
        }
        texts.deinit(allocator);
        for (scalars.items) |entry| allocator.free(entry.name);
        scalars.deinit(allocator);
    }

    var lines = std.mem.splitScalar(u8, source, '\n');
    var in_data_section = false;

    var current_name: ?[]u8 = null;
    var current_text: std.ArrayListUnmanaged(u8) = .empty;
    defer current_text.deinit(allocator);

    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r");
        const stripped = stripComment(line);
        const trimmed = std.mem.trim(u8, stripped, " \t");
        if (trimmed.len == 0) continue;

        if (!in_data_section) {
            if (startsWithDirective(trimmed, ".DATA")) in_data_section = true;
            continue;
        }

        if (startsWithDirective(trimmed, ".CODE")) break;

        const parsed = try parseDataLine(allocator, trimmed);
        switch (parsed) {
            .none => {
                if (current_name != null) {
                    try flushCurrentText(allocator, &texts, &current_name, &current_text);
                }
            },
            .text_start => |entry| {
                if (current_name != null) {
                    try flushCurrentText(allocator, &texts, &current_name, &current_text);
                }
                current_name = try allocator.dupe(u8, entry.name);
                try appendDirectiveValues(allocator, &current_text, entry.values);
            },
            .text_continue => |values| {
                if (current_name == null) continue;
                try appendDirectiveValues(allocator, &current_text, values);
            },
            .scalar => |entry| {
                if (current_name != null) {
                    try flushCurrentText(allocator, &texts, &current_name, &current_text);
                }
                try scalars.append(allocator, .{
                    .name = try allocator.dupe(u8, entry.name),
                    .value = entry.value,
                });
            },
        }
    }

    if (current_name != null) {
        try flushCurrentText(allocator, &texts, &current_name, &current_text);
    }

    return .{
        .allocator = allocator,
        .texts = try texts.toOwnedSlice(allocator),
        .scalars = try scalars.toOwnedSlice(allocator),
    };
}

const ParsedLine = union(enum) {
    none,
    text_start: struct {
        name: []const u8,
        values: []const u8,
    },
    text_continue: []const u8,
    scalar: struct {
        name: []const u8,
        value: i64,
    },
};

fn parseDataLine(allocator: std.mem.Allocator, trimmed: []const u8) !ParsedLine {
    _ = allocator;
    if (startsWithDataDirective(trimmed)) {
        return .{ .text_continue = skipDirective(trimmed) };
    }

    const split_idx = std.mem.indexOfAny(u8, trimmed, " \t") orelse return .none;
    const label = trimmed[0..split_idx];
    const rest = std.mem.trim(u8, trimmed[split_idx..], " \t");
    const directive = parseDirective(rest) orelse return .none;
    const values = std.mem.trim(u8, rest[directive.len..], " \t");
    if (values.len == 0) return .none;

    if (declarationLooksTextual(values)) {
        return .{
            .text_start = .{
                .name = label,
                .values = values,
            },
        };
    }

    if (parseLeadingScalar(values)) |value| {
        return .{
            .scalar = .{
                .name = label,
                .value = value,
            },
        };
    }
    return .none;
}

fn flushCurrentText(
    allocator: std.mem.Allocator,
    texts: *std.ArrayListUnmanaged(TextAsset),
    current_name: *?[]u8,
    current_text: *std.ArrayListUnmanaged(u8),
) !void {
    const name = current_name.*.?;
    current_name.* = null;

    const raw_text = try current_text.toOwnedSlice(allocator);
    current_text.* = .empty;
    defer allocator.free(raw_text);

    const trimmed = trimTrailingWhitespace(raw_text);
    if (trimmed.len == 0) {
        allocator.free(name);
        return;
    }

    try texts.append(allocator, .{
        .name = name,
        .text = try allocator.dupe(u8, trimmed),
    });
}

fn appendDirectiveValues(
    allocator: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(u8),
    values: []const u8,
) !void {
    var i: usize = 0;
    while (i < values.len) {
        while (i < values.len and (values[i] == ' ' or values[i] == '\t' or values[i] == ',')) : (i += 1) {}
        if (i >= values.len) break;

        if (values[i] == '"' or values[i] == '\'') {
            const quote = values[i];
            i += 1;
            const start = i;
            while (i < values.len and values[i] != quote) : (i += 1) {}
            const quoted = values[start..i];
            if (!(quoted.len == 1 and quoted[0] == '$')) {
                try out.appendSlice(allocator, quoted);
            }
            if (i < values.len) i += 1;
            continue;
        }

        const token_start = i;
        while (i < values.len and values[i] != ',') : (i += 1) {}
        const token = std.mem.trim(u8, values[token_start..i], " \t");
        if (token.len == 0) continue;
        if (std.ascii.indexOfIgnoreCase(token, "dup") != null) continue;
        if (token[0] == '?') continue;

        if (parseIntegerToken(token)) |value| {
            if (value == 0 or value == '$' or value == 0x0D) {
                continue;
            }
            if (value == 0x0A) {
                try out.append(allocator, '\n');
            } else if (value >= 0 and value <= 255) {
                try out.append(allocator, @intCast(value));
            }
        }
    }
}

fn declarationLooksTextual(values: []const u8) bool {
    if (std.ascii.indexOfIgnoreCase(values, "dup") != null and !containsControlByte(values, 0x0A) and !containsControlByte(values, 0x0D)) {
        return false;
    }
    if (std.mem.indexOfAny(u8, values, "\"'") != null) return true;
    if (containsControlByte(values, 0x0A) or containsControlByte(values, 0x0D) or containsControlByte(values, '$')) {
        return true;
    }
    return false;
}

fn containsControlByte(values: []const u8, needle: i64) bool {
    var i: usize = 0;
    while (i < values.len) {
        while (i < values.len and (values[i] == ' ' or values[i] == '\t' or values[i] == ',')) : (i += 1) {}
        if (i >= values.len) break;

        if (values[i] == '"' or values[i] == '\'') {
            const quote = values[i];
            i += 1;
            while (i < values.len and values[i] != quote) : (i += 1) {}
            if (i < values.len) i += 1;
            continue;
        }

        const start = i;
        while (i < values.len and values[i] != ',') : (i += 1) {}
        const token = std.mem.trim(u8, values[start..i], " \t");
        if (token.len == 0) continue;

        if (parseIntegerToken(token)) |value| {
            if (value == needle) return true;
        }
    }
    return false;
}

fn parseLeadingScalar(values: []const u8) ?i64 {
    const first_end = std.mem.indexOfScalar(u8, values, ',') orelse values.len;
    const token = std.mem.trim(u8, values[0..first_end], " \t");
    if (token.len == 0) return null;
    if (token[0] == '?' or token[0] == '"' or token[0] == '\'') return null;
    if (std.ascii.indexOfIgnoreCase(token, "dup") != null) return null;
    return parseIntegerToken(token);
}

fn parseIntegerToken(token: []const u8) ?i64 {
    if (token.len == 0) return null;
    const normalized = std.mem.trim(u8, token, " \t");
    if (normalized.len == 0) return null;

    if (normalized.len == 3 and normalized[0] == '\'' and normalized[2] == '\'') {
        return normalized[1];
    }
    if (normalized.len == 3 and normalized[0] == '"' and normalized[2] == '"') {
        return normalized[1];
    }

    if (normalized[normalized.len - 1] == 'h' or normalized[normalized.len - 1] == 'H') {
        return std.fmt.parseInt(i64, normalized[0 .. normalized.len - 1], 16) catch null;
    }
    if (normalized[normalized.len - 1] == 'b' or normalized[normalized.len - 1] == 'B') {
        return std.fmt.parseInt(i64, normalized[0 .. normalized.len - 1], 2) catch null;
    }
    return std.fmt.parseInt(i64, normalized, 10) catch null;
}

fn trimTrailingWhitespace(text: []const u8) []const u8 {
    var end = text.len;
    while (end > 0 and (text[end - 1] == '\n' or text[end - 1] == '\r' or text[end - 1] == ' ' or text[end - 1] == '\t')) : (end -= 1) {}
    return text[0..end];
}

fn parseDirective(rest: []const u8) ?[]const u8 {
    const directives = [_][]const u8{ "BYTE", "WORD", "DWORD", "db", "dw", "dd" };
    for (directives) |directive| {
        if (startsWithDirective(rest, directive)) return directive;
    }
    return null;
}

fn startsWithDataDirective(line: []const u8) bool {
    return startsWithDirective(line, "BYTE") or
        startsWithDirective(line, "WORD") or
        startsWithDirective(line, "DWORD") or
        startsWithDirective(line, "db") or
        startsWithDirective(line, "dw") or
        startsWithDirective(line, "dd");
}

fn skipDirective(line: []const u8) []const u8 {
    const directive = parseDirective(line) orelse return line;
    return std.mem.trim(u8, line[directive.len..], " \t");
}

fn startsWithDirective(line: []const u8, directive: []const u8) bool {
    return line.len >= directive.len and std.ascii.eqlIgnoreCase(line[0..directive.len], directive);
}

pub fn stripComment(line: []const u8) []const u8 {
    var in_quote = false;
    var quote_char: u8 = 0;
    for (line, 0..) |ch, idx| {
        if ((ch == '"' or ch == '\'') and (!in_quote or ch == quote_char)) {
            if (in_quote and ch == quote_char) {
                in_quote = false;
                quote_char = 0;
            } else if (!in_quote) {
                in_quote = true;
                quote_char = ch;
            }
        } else if (ch == ';' and !in_quote) {
            return line[0..idx];
        }
    }
    return line;
}

test "parse dos data section separates text and scalars" {
    const sample =
        \\.DATA
        \\StartScreen db 'Hello',0ah,0dh,'$'
        \\Lives db 6
        \\Name db 15, ?, 15 dup('$')
        \\.CODE
    ;

    var bundle = try parseDosAsmSource(std.testing.allocator, sample);
    defer bundle.deinit();

    try std.testing.expectEqual(@as(usize, 1), bundle.texts.len);
    try std.testing.expectEqualStrings("StartScreen", bundle.texts[0].name);
    try std.testing.expectEqualStrings("Hello", bundle.texts[0].text);
    try std.testing.expectEqual(@as(usize, 2), bundle.scalars.len);
    try std.testing.expectEqual(@as(i64, 6), bundle.findScalar("Lives").?);
    try std.testing.expectEqual(@as(i64, 15), bundle.findScalar("Name").?);
}
