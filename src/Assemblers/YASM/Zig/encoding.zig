const std = @import("std");
const operands = @import("operands.zig");

pub const InstructionClass = enum {
    data_move,
    arithmetic,
    bitwise,
    branch,
    call,
    stack,
    system,
    simd,
    other,
};

pub const InstructionSummary = struct {
    mnemonic: []const u8,
    class: InstructionClass,
    operand_count: usize,
};

pub fn summarize(line: []const u8, allocator: std.mem.Allocator) !InstructionSummary {
    const trimmed = std.mem.trim(u8, line, " \t\r\n");
    if (trimmed.len == 0) return .{ .mnemonic = "", .class = .other, .operand_count = 0 };

    const mnemonic = firstToken(trimmed);
    const operand_text = std.mem.trim(u8, trimmed[mnemonic.len..], " \t");
    var ops: std.ArrayList([]const u8) = .empty;
    defer ops.deinit(allocator);
    try operands.splitOperands(operand_text, &ops, allocator);

    return .{
        .mnemonic = mnemonic,
        .class = classifyMnemonic(mnemonic),
        .operand_count = ops.items.len,
    };
}

pub fn classifyMnemonic(mnemonic: []const u8) InstructionClass {
    const data_move = [_][]const u8{ "mov", "movzx", "movsx", "lea", "xchg", "cmovz", "cmovnz", "cmova", "cmovae", "cmovb", "cmovbe" };
    const arithmetic = [_][]const u8{ "add", "sub", "mul", "imul", "div", "idiv", "inc", "dec", "neg", "cmp" };
    const bitwise = [_][]const u8{ "and", "or", "xor", "not", "shl", "shr", "sar", "sal", "rol", "ror", "test" };
    const branch = [_][]const u8{ "jmp", "je", "jne", "jz", "jnz", "ja", "jae", "jb", "jbe", "jg", "jge", "jl", "jle", "loop" };
    const call = [_][]const u8{ "call", "ret", "retf" };
    const stack = [_][]const u8{ "push", "pop", "pushfq", "popfq", "enter", "leave" };
    const system = [_][]const u8{ "syscall", "sysret", "int", "iret", "cpuid", "rdtsc" };
    if (inSet(mnemonic, &data_move)) return .data_move;
    if (inSet(mnemonic, &arithmetic)) return .arithmetic;
    if (inSet(mnemonic, &bitwise)) return .bitwise;
    if (inSet(mnemonic, &branch)) return .branch;
    if (inSet(mnemonic, &call)) return .call;
    if (inSet(mnemonic, &stack)) return .stack;
    if (inSet(mnemonic, &system)) return .system;
    if (std.ascii.startsWithIgnoreCase(mnemonic, "v") or std.mem.indexOf(u8, mnemonic, "ps") != null or std.mem.indexOf(u8, mnemonic, "pd") != null) return .simd;
    return .other;
}

pub fn placeholderLength(summary: InstructionSummary) u8 {
    return switch (summary.class) {
        .system => 2,
        .branch, .call => 5,
        .simd => 4,
        else => if (summary.operand_count > 1) 3 else 1,
    };
}

fn firstToken(line: []const u8) []const u8 {
    var end: usize = 0;
    while (end < line.len) : (end += 1) {
        if (line[end] == ' ' or line[end] == '\t') break;
    }
    return line[0..end];
}

fn inSet(value: []const u8, set: []const []const u8) bool {
    for (set) |candidate| {
        if (std.ascii.eqlIgnoreCase(value, candidate)) return true;
    }
    return false;
}

test "summarize syscall" {
    const summary = try summarize("syscall", std.testing.allocator);
    try std.testing.expectEqual(InstructionClass.system, summary.class);
    try std.testing.expectEqual(@as(u8, 2), placeholderLength(summary));
}

test "summarize mov operands" {
    const summary = try summarize("mov rax, qword [rdi]", std.testing.allocator);
    try std.testing.expectEqual(InstructionClass.data_move, summary.class);
    try std.testing.expectEqual(@as(usize, 2), summary.operand_count);
}
