const std = @import("std");

pub const TextAsset = struct {
    name: []u8,
    text: []u8,
};

pub const ScalarAsset = struct {
    name: []u8,
    value: i64,
};

pub const ArrayAsset = struct {
    name: []u8,
    values: []i64,
};

pub const AssetBundle = struct {
    allocator: std.mem.Allocator,
    texts: []TextAsset,
    scalars: []ScalarAsset,
    arrays: []ArrayAsset,

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
        for (self.arrays) |entry| {
            self.allocator.free(entry.name);
            self.allocator.free(entry.values);
        }
        self.allocator.free(self.arrays);
    }

    pub fn findText(self: AssetBundle, name: []const u8) ?[]const u8 {
        for (self.texts) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.name, name)) return entry.text;
        }
        return null;
    }

    pub fn findFirstTextWithPrefix(self: AssetBundle, prefix: []const u8) ?[]const u8 {
        for (self.texts) |entry| {
            if (startsWithIgnoreCase(entry.name, prefix)) return entry.text;
        }
        return null;
    }

    pub fn joinTextsWithPrefix(self: AssetBundle, allocator: std.mem.Allocator, prefix: []const u8) !?[]u8 {
        var out: std.ArrayListUnmanaged(u8) = .empty;
        defer out.deinit(allocator);
        var found = false;
        for (self.texts) |entry| {
            if (!startsWithIgnoreCase(entry.name, prefix)) continue;
            found = true;
            try out.appendSlice(allocator, entry.text);
            if (entry.text.len > 0 and entry.text[entry.text.len - 1] != '\n') {
                try out.append(allocator, '\n');
            }
        }
        if (!found) return null;
        return try out.toOwnedSlice(allocator);
    }

    pub fn findScalar(self: AssetBundle, name: []const u8) ?i64 {
        for (self.scalars) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.name, name)) return entry.value;
        }
        return null;
    }

    pub fn findArray(self: AssetBundle, name: []const u8) ?[]const i64 {
        for (self.arrays) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.name, name)) return entry.values;
        }
        return null;
    }
};

pub fn parseSource(allocator: std.mem.Allocator, source: []const u8) !AssetBundle {
    var texts: std.ArrayListUnmanaged(TextAsset) = .empty;
    var scalars: std.ArrayListUnmanaged(ScalarAsset) = .empty;
    var arrays: std.ArrayListUnmanaged(ArrayAsset) = .empty;
    errdefer {
        for (texts.items) |entry| {
            allocator.free(entry.name);
            allocator.free(entry.text);
        }
        texts.deinit(allocator);
        for (scalars.items) |entry| allocator.free(entry.name);
        scalars.deinit(allocator);
        for (arrays.items) |entry| {
            allocator.free(entry.name);
            allocator.free(entry.values);
        }
        arrays.deinit(allocator);
    }

    var current_name: ?[]u8 = null;
    var current_text: std.ArrayListUnmanaged(u8) = .empty;
    defer current_text.deinit(allocator);

    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r");
        if (try parseTextLine(allocator, &texts, &current_name, &current_text, line)) {
            continue;
        }

        if (try parseArrayLine(allocator, &arrays, line)) {
            if (current_name != null) {
                try flushCurrentText(allocator, &texts, &current_name, &current_text);
            }
            continue;
        }

        if (try parseScalarLine(allocator, &scalars, line)) {
            if (current_name != null) {
                try flushCurrentText(allocator, &texts, &current_name, &current_text);
            }
            continue;
        }

        if (current_name != null) {
            try flushCurrentText(allocator, &texts, &current_name, &current_text);
        }
    }

    if (current_name != null) {
        try flushCurrentText(allocator, &texts, &current_name, &current_text);
    }

    return .{
        .allocator = allocator,
        .texts = try texts.toOwnedSlice(allocator),
        .scalars = try scalars.toOwnedSlice(allocator),
        .arrays = try arrays.toOwnedSlice(allocator),
    };
}

fn parseTextLine(
    allocator: std.mem.Allocator,
    texts: *std.ArrayListUnmanaged(TextAsset),
    current_name: *?[]u8,
    current_text: *std.ArrayListUnmanaged(u8),
    line: []const u8,
) !bool {
    const stripped = stripComment(line);
    const trimmed = std.mem.trim(u8, stripped, " \t");
    if (trimmed.len == 0 or trimmed[0] == ';') return false;

    if (current_name.* != null and startsDirective(trimmed, "BYTE")) {
        try appendByteDirective(allocator, current_text, trimmed[4..]);
        return true;
    }
    if (current_name.* != null and startsDirective(trimmed, "db")) {
        try appendByteDirective(allocator, current_text, trimmed[2..]);
        return true;
    }

    const split_idx = std.mem.indexOfAny(u8, trimmed, " \t") orelse return false;
    const label = trimmed[0..split_idx];
    const rest = std.mem.trim(u8, trimmed[split_idx..], " \t");

    if (!(startsDirective(rest, "BYTE") or startsDirective(rest, "db"))) return false;

    if (current_name.* != null) {
        try flushCurrentText(allocator, texts, current_name, current_text);
    }

    current_name.* = try allocator.dupe(u8, label);
    if (startsDirective(rest, "BYTE")) {
        try appendByteDirective(allocator, current_text, rest[4..]);
    } else {
        try appendByteDirective(allocator, current_text, rest[2..]);
    }
    return true;
}

fn parseScalarLine(
    allocator: std.mem.Allocator,
    scalars: *std.ArrayListUnmanaged(ScalarAsset),
    line: []const u8,
) !bool {
    const stripped = stripComment(line);
    const trimmed = std.mem.trim(u8, stripped, " \t");
    if (trimmed.len == 0 or trimmed[0] == ';') return false;

    const split_idx = std.mem.indexOfAny(u8, trimmed, " \t") orelse return false;
    const label = trimmed[0..split_idx];
    const rest = std.mem.trim(u8, trimmed[split_idx..], " \t");

    const directive_len: usize = if (startsDirective(rest, "BYTE")) 4 else if (startsDirective(rest, "WORD")) 4 else if (startsDirective(rest, "DWORD")) 5 else if (startsDirective(rest, "db")) 2 else if (startsDirective(rest, "dw")) 2 else if (startsDirective(rest, "dd")) 2 else return false;
    const value_text = std.mem.trim(u8, rest[directive_len..], " \t");
    const token_end = std.mem.indexOfScalar(u8, value_text, ',') orelse value_text.len;
    const token = std.mem.trim(u8, value_text[0..token_end], " \t");
    if (token.len == 0) return false;
    if (std.ascii.indexOfIgnoreCase(token, "dup") != null or token[0] == '"' or token[0] == '\'') return false;

    const value = parseIntegerToken(token) orelse return false;
    try scalars.append(allocator, .{
        .name = try allocator.dupe(u8, label),
        .value = value,
    });
    return true;
}

fn parseArrayLine(
    allocator: std.mem.Allocator,
    arrays: *std.ArrayListUnmanaged(ArrayAsset),
    line: []const u8,
) !bool {
    const stripped = stripComment(line);
    const trimmed = std.mem.trim(u8, stripped, " \t");
    if (trimmed.len == 0 or trimmed[0] == ';') return false;

    const split_idx = std.mem.indexOfAny(u8, trimmed, " \t") orelse return false;
    const label = trimmed[0..split_idx];
    const rest = std.mem.trim(u8, trimmed[split_idx..], " \t");

    const directive_len: usize = if (startsDirective(rest, "BYTE")) 4 else if (startsDirective(rest, "WORD")) 4 else if (startsDirective(rest, "DWORD")) 5 else if (startsDirective(rest, "db")) 2 else if (startsDirective(rest, "dw")) 2 else if (startsDirective(rest, "dd")) 2 else return false;
    const value_text = std.mem.trim(u8, rest[directive_len..], " \t");
    if (value_text.len == 0) return false;
    if (std.mem.indexOfScalar(u8, value_text, ',') == null) return false;
    if (std.ascii.indexOfIgnoreCase(value_text, "dup") != null) return false;
    if (std.mem.indexOfAny(u8, value_text, "\"'") != null) return false;

    var parsed: std.ArrayListUnmanaged(i64) = .empty;
    defer parsed.deinit(allocator);

    var tokens = std.mem.splitScalar(u8, value_text, ',');
    while (tokens.next()) |raw_token| {
        const token = std.mem.trim(u8, raw_token, " \t");
        if (token.len == 0) continue;
        const value = parseIntegerToken(token) orelse return false;
        try parsed.append(allocator, value);
    }
    if (parsed.items.len <= 1) return false;

    try arrays.append(allocator, .{
        .name = try allocator.dupe(u8, label),
        .values = try parsed.toOwnedSlice(allocator),
    });
    return true;
}

fn flushCurrentText(
    allocator: std.mem.Allocator,
    texts: *std.ArrayListUnmanaged(TextAsset),
    current_name: *?[]u8,
    current_text: *std.ArrayListUnmanaged(u8),
) !void {
    const name = current_name.*.?;
    current_name.* = null;
    const text = try current_text.toOwnedSlice(allocator);
    current_text.* = .empty;
    try texts.append(allocator, .{
        .name = name,
        .text = text,
    });
}

fn appendByteDirective(
    allocator: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(u8),
    source: []const u8,
) !void {
    var i: usize = 0;
    while (i < source.len) {
        while (i < source.len and (source[i] == ' ' or source[i] == '\t' or source[i] == ',')) : (i += 1) {}
        if (i >= source.len) break;

        if (source[i] == '"' or source[i] == '\'') {
            const quote = source[i];
            i += 1;
            const start = i;
            while (i < source.len and source[i] != quote) : (i += 1) {}
            try out.appendSlice(allocator, source[start..i]);
            if (i < source.len) i += 1;
            continue;
        }

        const start = i;
        while (i < source.len and source[i] != ',') : (i += 1) {}
        const token = std.mem.trim(u8, source[start..i], " \t");
        if (token.len == 0) continue;
        if (std.ascii.indexOfIgnoreCase(token, "dup") != null) continue;

        if (parseIntegerToken(token)) |value| {
            if (value == 0x0A) {
                try out.append(allocator, '\n');
            } else if (value == 0 or value == 0x0D) {
                // Null terminators and carriage returns do not need explicit output.
            } else if (value >= 0 and value <= 255) {
                try out.append(allocator, @intCast(value));
            }
        }
    }
}

fn parseIntegerToken(token: []const u8) ?i64 {
    if (token.len == 0) return null;
    if (token[0] == '"' or token[0] == '\'') return null;

    const normalized = std.mem.trim(u8, token, " \t");
    if (normalized.len == 0) return null;

    if (normalized[normalized.len - 1] == 'h' or normalized[normalized.len - 1] == 'H') {
        return std.fmt.parseInt(i64, normalized[0 .. normalized.len - 1], 16) catch null;
    }
    if (normalized[normalized.len - 1] == 'b' or normalized[normalized.len - 1] == 'B') {
        return std.fmt.parseInt(i64, normalized[0 .. normalized.len - 1], 2) catch null;
    }
    return std.fmt.parseInt(i64, normalized, 10) catch null;
}

fn startsDirective(line: []const u8, directive: []const u8) bool {
    return line.len >= directive.len and std.ascii.eqlIgnoreCase(line[0..directive.len], directive);
}

fn stripComment(line: []const u8) []const u8 {
    var in_quote = false;
    var quote_char: u8 = 0;
    for (line, 0..) |ch, idx| {
        if ((ch == '"' or ch == '\'') and (!in_quote or ch == quote_char)) {
            if (in_quote) {
                in_quote = false;
                quote_char = 0;
            } else {
                in_quote = true;
                quote_char = ch;
            }
        } else if (ch == ';' and !in_quote) {
            return line[0..idx];
        }
    }
    return line;
}

fn startsWithIgnoreCase(haystack: []const u8, prefix: []const u8) bool {
    return haystack.len >= prefix.len and std.ascii.eqlIgnoreCase(haystack[0..prefix.len], prefix);
}

test "parse multiline byte assets and scalars" {
    const source =
        \\intro1 BYTE "Hello", 0ah
        \\       BYTE "World", 0
        \\initialXPos BYTE 44
        \\Level1Row1 BYTE "####", 0ah
        \\           BYTE "#..#", 0
    ;

    var bundle = try parseSource(std.testing.allocator, source);
    defer bundle.deinit();

    try std.testing.expectEqualStrings("Hello\nWorld", bundle.findText("intro1").?);
    try std.testing.expectEqual(@as(i64, 44), bundle.findScalar("initialXPos").?);
    try std.testing.expectEqualStrings("####\n#..#", bundle.findText("Level1Row1").?);
}

test "parse numeric arrays" {
    const source =
        \\levelCoins Word 260, 376, 185
        \\maxLevel BYTE 2
    ;

    var bundle = try parseSource(std.testing.allocator, source);
    defer bundle.deinit();

    const level_coins = bundle.findArray("levelCoins").?;
    try std.testing.expectEqual(@as(usize, 3), level_coins.len);
    try std.testing.expectEqual(@as(i64, 260), level_coins[0]);
    try std.testing.expectEqual(@as(i64, 376), level_coins[1]);
    try std.testing.expectEqual(@as(i64, 185), level_coins[2]);
    try std.testing.expectEqual(@as(i64, 2), bundle.findScalar("maxLevel").?);
}
