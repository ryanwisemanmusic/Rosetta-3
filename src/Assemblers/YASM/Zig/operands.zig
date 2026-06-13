const std = @import("std");

pub const OperandKind = enum {
    register,
    immediate,
    memory,
    symbol,
    empty,
};

pub const RegisterClass = enum {
    gpr,
    simd,
    segment,
    control,
    debug,
    unknown,
};

pub const Operand = struct {
    text: []const u8,
    kind: OperandKind,
    register_class: RegisterClass = .unknown,
    bit_width: u16 = 0,
};

pub fn classify(text: []const u8) Operand {
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    if (trimmed.len == 0) return .{ .text = trimmed, .kind = .empty };
    if (isMemory(trimmed)) return .{ .text = trimmed, .kind = .memory };
    if (isImmediate(trimmed)) return .{ .text = trimmed, .kind = .immediate };
    if (registerInfo(trimmed)) |info| {
        return .{
            .text = trimmed,
            .kind = .register,
            .register_class = info.class,
            .bit_width = info.bits,
        };
    }
    return .{ .text = trimmed, .kind = .symbol };
}

pub fn splitOperands(line: []const u8, out: *std.ArrayList([]const u8), allocator: std.mem.Allocator) !void {
    var depth: u32 = 0;
    var start: usize = 0;
    for (line, 0..) |ch, i| {
        switch (ch) {
            '[' => depth += 1,
            ']' => {
                if (depth > 0) depth -= 1;
            },
            ',' => {
                if (depth == 0) {
                    const piece = std.mem.trim(u8, line[start..i], " \t");
                    if (piece.len > 0) try out.append(allocator, piece);
                    start = i + 1;
                }
            },
            else => {},
        }
    }
    const last = std.mem.trim(u8, line[start..], " \t");
    if (last.len > 0) try out.append(allocator, last);
}

fn isMemory(text: []const u8) bool {
    return std.mem.indexOfScalar(u8, text, '[') != null and std.mem.indexOfScalar(u8, text, ']') != null;
}

fn isImmediate(text: []const u8) bool {
    if (text.len == 0) return false;
    if (text[0] == '-' or text[0] == '+') return text.len > 1 and isImmediate(text[1..]);
    if (std.ascii.isDigit(text[0])) return true;
    return std.mem.startsWith(u8, text, "0x") or std.mem.startsWith(u8, text, "0X");
}

const RegisterInfo = struct {
    class: RegisterClass,
    bits: u16,
};

fn registerInfo(name_raw: []const u8) ?RegisterInfo {
    const name = std.mem.trim(u8, name_raw, " \t");
    const gpr8 = [_][]const u8{ "al", "ah", "bl", "bh", "cl", "ch", "dl", "dh", "sil", "dil", "spl", "bpl" };
    const gpr16 = [_][]const u8{ "ax", "bx", "cx", "dx", "si", "di", "sp", "bp" };
    const gpr32 = [_][]const u8{ "eax", "ebx", "ecx", "edx", "esi", "edi", "esp", "ebp", "r8d", "r9d", "r10d", "r11d", "r12d", "r13d", "r14d", "r15d" };
    const gpr64 = [_][]const u8{ "rax", "rbx", "rcx", "rdx", "rsi", "rdi", "rsp", "rbp", "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15" };
    if (inSet(name, &gpr8) or isExtendedByteRegister(name)) return .{ .class = .gpr, .bits = 8 };
    if (inSet(name, &gpr16) or isExtendedWordRegister(name)) return .{ .class = .gpr, .bits = 16 };
    if (inSet(name, &gpr32)) return .{ .class = .gpr, .bits = 32 };
    if (inSet(name, &gpr64)) return .{ .class = .gpr, .bits = 64 };
    if (startsWithRegisterPrefix(name, "xmm")) return .{ .class = .simd, .bits = 128 };
    if (startsWithRegisterPrefix(name, "ymm")) return .{ .class = .simd, .bits = 256 };
    if (startsWithRegisterPrefix(name, "zmm")) return .{ .class = .simd, .bits = 512 };
    if (startsWithRegisterPrefix(name, "cr")) return .{ .class = .control, .bits = 64 };
    if (startsWithRegisterPrefix(name, "dr")) return .{ .class = .debug, .bits = 64 };
    return null;
}

fn inSet(name: []const u8, set: []const []const u8) bool {
    for (set) |candidate| {
        if (std.ascii.eqlIgnoreCase(name, candidate)) return true;
    }
    return false;
}

fn startsWithRegisterPrefix(name: []const u8, prefix: []const u8) bool {
    if (!std.ascii.startsWithIgnoreCase(name, prefix)) return false;
    if (name.len == prefix.len) return false;
    for (name[prefix.len..]) |ch| {
        if (!std.ascii.isDigit(ch)) return false;
    }
    return true;
}

fn isExtendedByteRegister(name: []const u8) bool {
    return name.len >= 3 and name.len <= 4 and (name[0] == 'r' or name[0] == 'R') and name[name.len - 1] == 'b' and parseRegisterNumber(name[1 .. name.len - 1]);
}

fn isExtendedWordRegister(name: []const u8) bool {
    return name.len >= 3 and name.len <= 4 and (name[0] == 'r' or name[0] == 'R') and name[name.len - 1] == 'w' and parseRegisterNumber(name[1 .. name.len - 1]);
}

fn parseRegisterNumber(text: []const u8) bool {
    if (text.len == 0) return false;
    var value: u32 = 0;
    for (text) |ch| {
        if (!std.ascii.isDigit(ch)) return false;
        value = value * 10 + ch - '0';
    }
    return value >= 8 and value <= 15;
}

test "classify x86-64 operands" {
    try std.testing.expectEqual(OperandKind.register, classify("rax").kind);
    try std.testing.expectEqual(@as(u16, 64), classify("r15").bit_width);
    try std.testing.expectEqual(OperandKind.memory, classify("qword [r8 + 8]").kind);
    try std.testing.expectEqual(OperandKind.immediate, classify("-42").kind);
}

test "split operands respects memory commas" {
    var list: std.ArrayList([]const u8) = .empty;
    defer list.deinit(std.testing.allocator);
    try splitOperands("rax, [rbx+rcx*8], 4", &list, std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 3), list.items.len);
}
