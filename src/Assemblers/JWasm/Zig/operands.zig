const std = @import("std");
const jwasm = @import("jwasm_core.zig");

pub const TypeAttr = packed struct(u16) {
    code: bool = false,
    data: bool = false,
    constant: bool = false,
    _pad0: u1 = 0,
    direct_mem: bool = false,
    register: bool = false,
    implicit_far: bool = false,
    _pad1: u1 = 0,
    external: bool = false,
    _pad2: u2 = 0,
    far_label: bool = false,
    near_label: bool = false,
    _pad3: u1 = 0,
    undefined: bool = false,
    _pad4: u1 = 0,
};

pub fn computeTypeAttr(sym_state: jwasm.SymbolType, is_extern: bool, is_far: bool) TypeAttr {
    return TypeAttr{
        .code = sym_state == .undefined or sym_state == .internal,
        .data = sym_state == .internal or sym_state == .struct_field,
        .constant = sym_state == .internal,
        .direct_mem = sym_state == .internal or sym_state == .type,
        .register = sym_state == .type,
        .external = is_extern,
        .far_label = is_far,
        .near_label = !is_far and sym_state == .internal,
    };
}

pub const OperandKind = enum(u8) {
    none = 0,
    register = 1,
    immediate = 2,
    direct_memory = 3,
    indirect_memory = 4,
    memory_expr = 5,
    relative = 6,
};

pub const Operand = struct {
    kind: OperandKind = .none,
    reg: u8 = 0,
    immediate: u64 = 0,
    displacement: i64 = 0,
    direct_mem: bool = false,
    segment_override: u8 = 0,
    size: u8 = 0,
    symbol_name: []const u8 = "",
    type_attr: TypeAttr = .{},
};

pub const MemType = enum(u8) {
    m08 = 0,
    m16 = 1,
    m32 = 2,
    m64 = 3,
    m128 = 4,
    m256 = 5,
    m16_m32 = 6,
    m32_m64 = 7,
    m48 = 8,
    m80 = 9,
    m112 = 10,
    m_any = 11,
    mfptr = 12,
    m16_32_64 = 13,
    ms = 14,
    mgt8 = 15,
    mt = 16,
    none = 0xFF,
};

pub const ExpressionTerm = union(enum) {
    constant: u64,
    symbol: struct { name: []const u8, offset: i64 },
    plus,
    minus,
    multiply,
    divide,
    mod,
    shift_left,
    shift_right,
    @"and",
    @"or",
    xor,
    not,
    negate,
    segment_colon,
    dot_type: u8,
};

pub const Expression = struct {
    value: u64 = 0,
    is_constant: bool = true,
    is_relocatable: bool = false,
    segment_base: u32 = 0,
    offset: i64 = 0,
    symbols: std.ArrayListUnmanaged(ExpressionTerm) = .{ .items = &.{}, .capacity = 0 },
    text: []const u8 = "",

    pub fn deinit(self: *Expression, allocator: std.mem.Allocator) void {
        self.symbols.deinit(allocator);
    }
};

pub const ExpressionParser = struct {
    source: []const u8,
    pos: usize = 0,

    pub fn init(source: []const u8) ExpressionParser {
        return ExpressionParser{ .source = source };
    }

    pub fn parse(self: *ExpressionParser) !Expression {
        _ = self;
        return Expression{};
    }

    pub fn parseConstant(self: *ExpressionParser) !u64 {
        const expr = try self.parse();
        if (!expr.is_constant) return jwasm.AssemblerError.ExpressionSyntax;
        return expr.value;
    }
};

pub fn resolveTypeSize(masm_type: []const u8) u8 {
    if (masm_type.len > 0) {
        if (std.ascii.eqlIgnoreCase(masm_type, "BYTE")) return 1;
        if (std.ascii.eqlIgnoreCase(masm_type, "SBYTE")) return 1;
        if (std.ascii.eqlIgnoreCase(masm_type, "WORD")) return 2;
        if (std.ascii.eqlIgnoreCase(masm_type, "SWORD")) return 2;
        if (std.ascii.eqlIgnoreCase(masm_type, "DWORD")) return 4;
        if (std.ascii.eqlIgnoreCase(masm_type, "SDWORD")) return 4;
        if (std.ascii.eqlIgnoreCase(masm_type, "FWORD")) return 6;
        if (std.ascii.eqlIgnoreCase(masm_type, "QWORD")) return 8;
        if (std.ascii.eqlIgnoreCase(masm_type, "SQWORD")) return 8;
        if (std.ascii.eqlIgnoreCase(masm_type, "TBYTE")) return 10;
        if (std.ascii.eqlIgnoreCase(masm_type, "REAL4")) return 4;
        if (std.ascii.eqlIgnoreCase(masm_type, "REAL8")) return 8;
        if (std.ascii.eqlIgnoreCase(masm_type, "REAL10")) return 10;
        if (std.ascii.eqlIgnoreCase(masm_type, "OWORD")) return 16;
        if (std.ascii.eqlIgnoreCase(masm_type, "YMMWORD")) return 32;
        if (std.ascii.eqlIgnoreCase(masm_type, "MMWORD")) return 8;
        if (std.ascii.eqlIgnoreCase(masm_type, "XMMWORD")) return 16;
        if (std.ascii.eqlIgnoreCase(masm_type, "POINTER")) return 4;
        if (std.ascii.eqlIgnoreCase(masm_type, "NEAR")) return 2;
        if (std.ascii.eqlIgnoreCase(masm_type, "FAR")) return 4;
        if (std.ascii.eqlIgnoreCase(masm_type, "PROC")) return 4;
    }
    return 0;
}

pub fn parseNumberLiteral(s: []const u8) ?u64 {
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

test "MASM style number parsing" {
    try std.testing.expectEqual(@as(u64, 255), parseNumberLiteral("0xFF").?);
    try std.testing.expectEqual(@as(u64, 255), parseNumberLiteral("0FFh").?);
    try std.testing.expectEqual(@as(u64, 10), parseNumberLiteral("0b1010").?);
    try std.testing.expectEqual(@as(u64, 10), parseNumberLiteral("1010b").?);
    try std.testing.expectEqual(@as(u64, 10), parseNumberLiteral("10").?);
}

test "type size resolution" {
    try std.testing.expectEqual(@as(u8, 1), resolveTypeSize("BYTE"));
    try std.testing.expectEqual(@as(u8, 4), resolveTypeSize("DWORD"));
    try std.testing.expectEqual(@as(u8, 8), resolveTypeSize("QWORD"));
    try std.testing.expectEqual(@as(u8, 16), resolveTypeSize("OWORD"));
    try std.testing.expectEqual(@as(u8, 32), resolveTypeSize("YMMWORD"));
}

test "TYPE attribute computation" {
    const attr = computeTypeAttr(.internal, false, false);
    try std.testing.expect(attr.code);
    try std.testing.expect(!attr.external);
}
