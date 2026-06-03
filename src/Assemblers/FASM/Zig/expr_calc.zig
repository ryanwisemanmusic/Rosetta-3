const std = @import("std");
const fasm = @import("fasm_core.zig");
const expr = @import("expr_parser.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;
const Token = expr.Token;
const TokenType = expr.TokenType;

pub const Value = struct {
    kind: ValueKind = .number,
    number: u64 = 0,
    symbol: []const u8 = "",

    const ValueKind = enum(u8) {
        number = 0,
        symbol = 1,
        expression = 2,
    };
};

const EvalError = errors.AssemblerError || error{OutOfMemory};

pub const ExpressionEvaluator = struct {
    parser: expr.ExpressionParser,
    allocator: Allocator,

    pub fn init(source: []const u8, allocator: Allocator) ExpressionEvaluator {
        return ExpressionEvaluator{
            .parser = expr.ExpressionParser.init(source),
            .allocator = allocator,
        };
    }

    pub fn evaluate(self: *ExpressionEvaluator) EvalError!Value {
        const result = try self.parseAddSub();
        return result;
    }

    fn parseAddSub(self: *ExpressionEvaluator) EvalError!Value {
        var left = try self.parseMulDiv();
        while (true) {
            const tok = self.parser.peek();
            if (tok.type == .plus) {
                _ = self.parser.next();
                const right = try self.parseMulDiv();
                left = try self.applyArith(.add, left, right);
            } else if (tok.type == .minus) {
                _ = self.parser.next();
                const right = try self.parseMulDiv();
                left = try self.applyArith(.sub, left, right);
            } else {
                break;
            }
        }
        return left;
    }

    fn parseMulDiv(self: *ExpressionEvaluator) EvalError!Value {
        var left = try self.parseUnary();
        while (true) {
            const tok = self.parser.peek();
            if (tok.type == .asterisk) {
                _ = self.parser.next();
                const right = try self.parseUnary();
                left = try self.applyArith(.mul, left, right);
            } else if (tok.type == .slash) {
                _ = self.parser.next();
                const right = try self.parseUnary();
                left = try self.applyArith(.div, left, right);
            } else if (tok.type == .percent) {
                _ = self.parser.next();
                const right = try self.parseUnary();
                left = try self.applyArith(.mod, left, right);
            } else {
                break;
            }
        }
        return left;
    }

    fn parseUnary(self: *ExpressionEvaluator) EvalError!Value {
        const tok = self.parser.peek();
        if (tok.type == .minus) {
            _ = self.parser.next();
            const val = try self.parsePrimary();
            return self.applyUnary(.negate, val);
        } else if (tok.type == .tilde) {
            _ = self.parser.next();
            const val = try self.parsePrimary();
            return self.applyUnary(.bitwise_not, val);
        } else if (tok.type == .not) {
            _ = self.parser.next();
            const val = try self.parsePrimary();
            return self.applyUnary(.logical_not, val);
        } else if (tok.type == .plus) {
            _ = self.parser.next();
            return self.parsePrimary();
        }
        return self.parsePrimary();
    }

    fn parsePrimary(self: *ExpressionEvaluator) EvalError!Value {
        const tok = self.parser.next();
        switch (tok.type) {
            .number => return Value{ .kind = .number, .number = tok.int_value },
            .symbol => return Value{ .kind = .symbol, .symbol = tok.string_value },
            .dollar => return Value{ .kind = .symbol, .symbol = "$" },
            .string => return Value{ .kind = .number, .number = self.stringToNumber(tok.string_value) },
            .lparen => {
                const val = try self.parseAddSub();
                const r = self.parser.next();
                if (r.type != .rparen) return errors.AssemblerError.InvalidExpression;
                return val;
            },
            else => return errors.AssemblerError.InvalidExpression,
        }
    }

    fn stringToNumber(_: *ExpressionEvaluator, str: []const u8) u64 {
        var result: u64 = 0;
        for (str) |ch| {
            result = (result << 8) | ch;
        }
        return result;
    }

    const ArithOp = enum { add, sub, mul, div, mod };
    const UnaryOp = enum { negate, bitwise_not, logical_not };

    fn applyArith(self: *ExpressionEvaluator, op: ArithOp, a: Value, b: Value) EvalError!Value {
        const a_num = try self.resolveValue(a);
        const b_num = try self.resolveValue(b);
        const result = switch (op) {
            .add => a_num + b_num,
            .sub => a_num - b_num,
            .mul => a_num * b_num,
            .div => if (b_num == 0) return errors.AssemblerError.InvalidValue else a_num / b_num,
            .mod => if (b_num == 0) return errors.AssemblerError.InvalidValue else a_num % b_num,
        };
        return Value{ .kind = .number, .number = result };
    }

    fn applyUnary(self: *ExpressionEvaluator, op: UnaryOp, a: Value) EvalError!Value {
        const a_num = try self.resolveValue(a);
        const result = switch (op) {
            .negate => ~a_num +% 1,
            .bitwise_not => ~a_num,
            .logical_not => if (a_num == 0) @as(u64, 1) else @as(u64, 0),
        };
        return Value{ .kind = .number, .number = result };
    }

    fn resolveValue(_: *ExpressionEvaluator, val: Value) EvalError!u64 {
        return switch (val.kind) {
            .number => val.number,
            .symbol => return errors.AssemblerError.UndefinedSymbol,
            .expression => return errors.AssemblerError.InvalidExpression,
        };
    }
};

pub fn evaluateExpression(source: []const u8, allocator: Allocator) !Value {
    var evaluator = ExpressionEvaluator.init(source, allocator);
    return evaluator.evaluate();
}

pub fn evaluateToU64(source: []const u8, allocator: Allocator) !u64 {
    const val = try evaluateExpression(source, allocator);
    return switch (val.kind) {
        .number => val.number,
        else => errors.AssemblerError.InvalidExpression,
    };
}

test "simple arithmetic" {
    const result = try evaluateToU64("2 + 3", std.testing.allocator);
    try std.testing.expectEqual(@as(u64, 5), result);
}

test "multiplication precedence" {
    const result = try evaluateToU64("2 + 3 * 4", std.testing.allocator);
    try std.testing.expectEqual(@as(u64, 14), result);
}

test "parentheses" {
    const result = try evaluateToU64("(2 + 3) * 4", std.testing.allocator);
    try std.testing.expectEqual(@as(u64, 20), result);
}

test "unary minus" {
    const result = try evaluateToU64("-5", std.testing.allocator);
    try std.testing.expectEqual(@as(u64, ~@as(u64, 5) +% 1), result);
}

test "modulo" {
    const result = try evaluateToU64("10 % 3", std.testing.allocator);
    try std.testing.expectEqual(@as(u64, 1), result);
}
