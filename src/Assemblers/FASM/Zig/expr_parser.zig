const std = @import("std");
const fasm = @import("fasm_core.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;

pub const TokenType = enum(u8) {
    number = 0,
    symbol = 1,
    string = 2,
    plus = '+',
    minus = '-',
    asterisk = '*',
    slash = '/',
    percent = '%',
    eq = '=',
    lt = '<',
    gt = '>',
    not = '!',
    tilde = '~',
    ampersand = '&',
    pipe = '|',
    caret = '^',
    lparen = '(',
    rparen = ')',
    lbracket = '[',
    rbracket = ']',
    comma = ',',
    colon = ':',
    semicolon = ';',
    dot = '.',
    hash = '#',
    question = '?',
    at = '@',
    backslash = '\\',
    dollar = '$',
    eof = 0xFF,
};

pub const Token = struct {
    type: TokenType = .eof,
    int_value: u64 = 0,
    string_value: []const u8 = "",
    char_value: u8 = 0,
    line_offset: u32 = 0,

    pub fn isOperator(self: *const Token) bool {
        return switch (self.type) {
            .plus, .minus, .asterisk, .slash, .percent,
            .eq, .lt, .gt, .not, .tilde, .ampersand, .pipe, .caret => true,
            else => false,
        };
    }

    pub fn precedence(self: *const Token) u8 {
        return switch (self.type) {
            .pipe => 1,
            .caret => 2,
            .ampersand => 3,
            .eq, .lt, .gt => 4,
            .plus, .minus => 5,
            .asterisk, .slash, .percent => 6,
            .tilde, .not => 7,
            else => 0,
        };
    }
};

pub const ExpressionParser = struct {
    source: []const u8,
    position: usize = 0,
    line_offset: u32 = 0,
    current_token: Token = .{},

    pub fn init(source: []const u8) ExpressionParser {
        return ExpressionParser{ .source = source };
    }

    pub fn peek(self: *ExpressionParser) Token {
        if (self.current_token.type == .eof) {
            self.current_token = self.nextTokenInternal();
        }
        return self.current_token;
    }

    pub fn next(self: *ExpressionParser) Token {
        const token = self.peek();
        self.current_token = .{};
        return token;
    }

    fn skipWhitespace(self: *ExpressionParser) void {
        while (self.position < self.source.len and
            (self.source[self.position] == ' ' or
             self.source[self.position] == '\t' or
             self.source[self.position] == '\r' or
             self.source[self.position] == '\n'))
        {
            if (self.source[self.position] == '\n') {
                self.line_offset = 0;
            } else {
                self.line_offset += 1;
            }
            self.position += 1;
        }
    }

    fn nextTokenInternal(self: *ExpressionParser) Token {
        self.skipWhitespace();
        if (self.position >= self.source.len) {
            return Token{ .type = .eof, .line_offset = self.line_offset };
        }

        const ch = self.source[self.position];
        const offset = self.line_offset;

        switch (ch) {
            '0'...'9' => return self.readNumber(ch),
            'a'...'z', 'A'...'Z', '_', '@', '.', '?' => return self.readSymbol(ch),
            '\'', '\"' => return self.readString(ch),
            '+' => { self.position += 1; self.line_offset += 1; return Token{ .type = .plus, .line_offset = offset, .char_value = ch }; },
            '-' => { self.position += 1; self.line_offset += 1; return Token{ .type = .minus, .line_offset = offset, .char_value = ch }; },
            '*' => { self.position += 1; self.line_offset += 1; return Token{ .type = .asterisk, .line_offset = offset, .char_value = ch }; },
            '/' => { self.position += 1; self.line_offset += 1; return Token{ .type = .slash, .line_offset = offset, .char_value = ch }; },
            '%' => { self.position += 1; self.line_offset += 1; return Token{ .type = .percent, .line_offset = offset, .char_value = ch }; },
            '=' => { self.position += 1; self.line_offset += 1; return Token{ .type = .eq, .line_offset = offset, .char_value = ch }; },
            '<' => { self.position += 1; self.line_offset += 1; return Token{ .type = .lt, .line_offset = offset, .char_value = ch }; },
            '>' => { self.position += 1; self.line_offset += 1; return Token{ .type = .gt, .line_offset = offset, .char_value = ch }; },
            '!' => { self.position += 1; self.line_offset += 1; return Token{ .type = .not, .line_offset = offset, .char_value = ch }; },
            '~' => { self.position += 1; self.line_offset += 1; return Token{ .type = .tilde, .line_offset = offset, .char_value = ch }; },
            '&' => { self.position += 1; self.line_offset += 1; return Token{ .type = .ampersand, .line_offset = offset, .char_value = ch }; },
            '|' => { self.position += 1; self.line_offset += 1; return Token{ .type = .pipe, .line_offset = offset, .char_value = ch }; },
            '^' => { self.position += 1; self.line_offset += 1; return Token{ .type = .caret, .line_offset = offset, .char_value = ch }; },
            '(' => { self.position += 1; self.line_offset += 1; return Token{ .type = .lparen, .line_offset = offset, .char_value = ch }; },
            ')' => { self.position += 1; self.line_offset += 1; return Token{ .type = .rparen, .line_offset = offset, .char_value = ch }; },
            '[' => { self.position += 1; self.line_offset += 1; return Token{ .type = .lbracket, .line_offset = offset, .char_value = ch }; },
            ']' => { self.position += 1; self.line_offset += 1; return Token{ .type = .rbracket, .line_offset = offset, .char_value = ch }; },
            ',' => { self.position += 1; self.line_offset += 1; return Token{ .type = .comma, .line_offset = offset, .char_value = ch }; },
            ':' => { self.position += 1; self.line_offset += 1; return Token{ .type = .colon, .line_offset = offset, .char_value = ch }; },
            ';' => { self.position += 1; self.line_offset += 1; return Token{ .type = .semicolon, .line_offset = offset, .char_value = ch }; },
            '#' => { self.position += 1; self.line_offset += 1; return Token{ .type = .hash, .line_offset = offset, .char_value = ch }; },
            '\\' => { self.position += 1; self.line_offset += 1; return Token{ .type = .backslash, .line_offset = offset, .char_value = ch }; },
            '$' => { self.position += 1; self.line_offset += 1; return Token{ .type = .dollar, .line_offset = offset, .char_value = ch }; },
            else => {
                self.position += 1;
                self.line_offset += 1;
                return Token{ .type = .eof, .line_offset = offset, .char_value = ch };
            },
        }
    }

    fn readNumber(self: *ExpressionParser, first: u8) Token {
        var value: u64 = first - '0';
        var base: u8 = 10;
        var offset = self.line_offset;

        if (first == '0' and self.position + 1 < self.source.len) {
            const next_ch = self.source[self.position + 1];
            switch (next_ch) {
                'x', 'X' => { base = 16; self.position += 2; offset += 2; },
                'b', 'B' => { base = 2; self.position += 2; offset += 2; },
                'o', 'O' => { base = 8; self.position += 2; offset += 2; },
                else => { self.position += 1; offset += 1; },
            }
        } else {
            self.position += 1;
            offset += 1;
        }

        while (self.position < self.source.len) {
            const ch = self.source[self.position];
            const digit = switch (base) {
                2 => switch (ch) { '0' => @as(u8, 0), '1' => 1, else => break },
                8 => switch (ch) { '0'...'7' => @as(u8, @intCast(ch - '0')), else => break },
                10 => switch (ch) { '0'...'9' => @as(u8, @intCast(ch - '0')), else => break },
                16 => switch (ch) { '0'...'9' => @as(u8, @intCast(ch - '0')), 'a'...'f' => @as(u8, @intCast(ch - 'a' + 10)), 'A'...'F' => @as(u8, @intCast(ch - 'A' + 10)), else => break },
                else => break,
            };
            value = value * base + digit;
            self.position += 1;
            offset += 1;
        }

        return Token{
            .type = .number,
            .int_value = value,
            .line_offset = self.line_offset,
        };
    }

    fn readSymbol(self: *ExpressionParser, _: u8) Token {
        const start = self.position;
        var offset = self.line_offset;
        self.position += 1;
        offset += 1;

        while (self.position < self.source.len) {
            const ch = self.source[self.position];
            switch (ch) {
                'a'...'z', 'A'...'Z', '0'...'9', '_', '.', '@', '?', '!' => {
                    self.position += 1;
                    offset += 1;
                },
                else => break,
            }
        }

        return Token{
            .type = .symbol,
            .string_value = self.source[start..self.position],
            .line_offset = self.line_offset,
        };
    }

    fn readString(self: *ExpressionParser, delimiter: u8) Token {
        const start = self.position;
        var offset = self.line_offset;
        self.position += 1;
        offset += 1;

        while (self.position < self.source.len and self.source[self.position] != delimiter) {
            if (self.source[self.position] == '\n') {
                break;
            }
            self.position += 1;
            offset += 1;
        }

        if (self.position < self.source.len) {
            self.position += 1;
            offset += 1;
        }

        return Token{
            .type = .string,
            .string_value = self.source[start + 1 .. self.position - 1],
            .line_offset = self.line_offset,
        };
    }
};

test "tokenizer numbers" {
    var parser = ExpressionParser.init("1234");
    const tok = parser.next();
    try std.testing.expectEqual(@as(TokenType, .number), tok.type);
    try std.testing.expectEqual(@as(u64, 1234), tok.int_value);
}

test "tokenizer hex" {
    var parser = ExpressionParser.init("0xFF");
    const tok = parser.next();
    try std.testing.expectEqual(@as(TokenType, .number), tok.type);
    try std.testing.expectEqual(@as(u64, 255), tok.int_value);
}

test "tokenizer binary" {
    var parser = ExpressionParser.init("0b1010");
    const tok = parser.next();
    try std.testing.expectEqual(@as(TokenType, .number), tok.type);
    try std.testing.expectEqual(@as(u64, 10), tok.int_value);
}

test "tokenizer symbols and operators" {
    var parser = ExpressionParser.init("eax + ebx");
    try std.testing.expectEqual(@as(TokenType, .symbol), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .plus), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .symbol), parser.next().type);
}

test "tokenizer parentheses" {
    var parser = ExpressionParser.init("(1+2)*3");
    try std.testing.expectEqual(@as(TokenType, .lparen), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .number), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .plus), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .number), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .rparen), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .asterisk), parser.next().type);
    try std.testing.expectEqual(@as(TokenType, .number), parser.next().type);
}
