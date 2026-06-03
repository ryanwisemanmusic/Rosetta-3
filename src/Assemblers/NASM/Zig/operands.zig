const std = @import("std");
const nasm = @import("nasm_core.zig");

pub const OperandType = enum(u32) {
    register = 1,
    immediate = 2,
    memory = 4,
    regmem = 8,
};

pub const SizeFlags = enum(u64) {
    bits8 = 1 << 32,
    bits16 = 1 << 33,
    bits32 = 1 << 34,
    bits64 = 1 << 35,
    bits80 = 1 << 36,
    bits128 = 1 << 37,
    bits256 = 1 << 38,
    bits512 = 1 << 39,
    far = 1 << 40,
    near = 1 << 41,
    short = 1 << 42,
    abs = 1 << 43,
};

pub const Modifier = enum(u32) {
    to = 1 << 4,
    colon = 1 << 5,
    strict = 1 << 6,
};

pub const RegisterClass = enum(u64) {
    cdt = 1 << 7,
    gpr = 1 << 8,
    sreg = 1 << 9,
    fpureg = 1 << 10,
    mmx = 1 << 11,
    xmm = 1 << 12,
    ymm = 1 << 13,
    zmm = 1 << 14,
    opmask = 1 << 15,
    bnd = 1 << 16,
    tmm = 1 << 17,
};

pub const Expr = struct {
    type_val: i32,
    value: i64,
};

pub const ExprVect = []Expr;

pub const EvalHints = struct {
    base: i64 = 0,
    hint_type: u32 = 0,
};

pub const Operand = struct {
    type_flags: u64 = 0,
    xsize: u64 = 0,
    basereg: i32 = -1,
    indexreg: i32 = -1,
    scale: i32 = 0,
    hintbase: i32 = 0,
    hinttype: nasm.eval_hint = .nohint,
    segment: i32 = nasm.NO_SEG,
    offset: i64 = 0,
    wrt: i32 = nasm.NO_SEG,
    eaflags: u32 = 0,
    opflags: u32 = 0,
    decoflags: u16 = 0,
    bcast: bool = false,
    disp_size: u8 = 0,
    opidx: u8 = 0,
};

pub const ExtopType = enum(u32) {
    nothing = 0,
    extop,
    db_string,
    db_float,
    db_string_free,
    db_number,
    db_reserve,
};

pub const Extop = struct {
    next: ?*Extop = null,
    data: ?[]const u8 = null,
    offset: i64 = 0,
    segment: i32 = nasm.NO_SEG,
    wrt: i32 = nasm.NO_SEG,
    relative: bool = false,
    subexpr: ?*Extop = null,
    dup: usize = 0,
    type_val: ExtopType = .nothing,
    elem: i32 = 0,
};

pub fn parseNumber(s: []const u8) ?u64 {
    if (s.len == 0) return null;
    var radix: u8 = 10;
    var start: usize = 0;
    var has_suffix = false;

    if (s.len >= 2) {
        const last = s[s.len - 1];
        const is_hex = last == 'h' or last == 'H';
        const is_oct = last == 'o' or last == 'O';
        const is_bin = last == 'b' or last == 'B';
        const is_dec = last == 'd' or last == 'D';
        const has_0x = s[0] == '0' and (s[1] == 'x' or s[1] == 'X');
        const has_0b = s[0] == '0' and (s[1] == 'b' or s[1] == 'B');
        const has_0o = s[0] == '0' and (s[1] == 'o' or s[1] == 'O');
        const has_0y = s[0] == '0' and (s[1] == 'y' or s[1] == 'Y');
        const has_0t = s[0] == '0' and (s[1] == 't' or s[1] == 'T');

        if (is_hex or has_0x) {
            radix = 16;
            start = if (has_0x) 2 else 0;
        } else if (is_oct or has_0o or has_0t) {
            radix = 8;
            start = if (has_0o or has_0t) 2 else 0;
        } else if (is_bin or has_0b or has_0y) {
            radix = 2;
            start = if (has_0b or has_0y) 2 else 0;
        } else if (is_dec) {
            radix = 10;
            start = 0;
        }
        has_suffix = is_hex or is_oct or is_bin or is_dec;
    }

    var end = s.len;
    if (has_suffix) end -= 1;

    var result: u64 = 0;
    for (s[start..end]) |ch| {
        const digit = switch (ch) {
            '0'...'9' => ch - '0',
            'a'...'f' => ch - 'a' + 10,
            'A'...'F' => ch - 'A' + 10,
            else => return null,
        };
        if (digit >= radix) return null;
        result = result * radix + digit;
    }
    return result;
}

pub fn resolveSize(type_flags: u64) ?u8 {
    const sfb = SizeFlags.bits8;
    if (type_flags & @intFromEnum(sfb) != 0) return 1;
    if (type_flags & @intFromEnum(SizeFlags.bits16) != 0) return 2;
    if (type_flags & @intFromEnum(SizeFlags.bits32) != 0) return 4;
    if (type_flags & @intFromEnum(SizeFlags.bits64) != 0) return 8;
    if (type_flags & @intFromEnum(SizeFlags.bits80) != 0) return 10;
    if (type_flags & @intFromEnum(SizeFlags.bits128) != 0) return 16;
    if (type_flags & @intFromEnum(SizeFlags.bits256) != 0) return 32;
    if (type_flags & @intFromEnum(SizeFlags.bits512) != 0) return 64;
    return null;
}

test "NASM style number parsing" {
    try std.testing.expectEqual(@as(u64, 255), parseNumber("0xFF").?);
    try std.testing.expectEqual(@as(u64, 255), parseNumber("0FFh").?);
    try std.testing.expectEqual(@as(u64, 10), parseNumber("0b1010").?);
    try std.testing.expectEqual(@as(u64, 10), parseNumber("1010b").?);
    try std.testing.expectEqual(@as(u64, 10), parseNumber("10").?);
    try std.testing.expectEqual(@as(u64, 10), parseNumber("10d").?);
}

test "size resolution" {
    try std.testing.expectEqual(@as(u8, 1), resolveSize(@intFromEnum(SizeFlags.bits8)).?);
    try std.testing.expectEqual(@as(u8, 4), resolveSize(@intFromEnum(SizeFlags.bits32)).?);
    try std.testing.expectEqual(@as(u8, 8), resolveSize(@intFromEnum(SizeFlags.bits64)).?);
    try std.testing.expect(resolveSize(0) == null);
}
