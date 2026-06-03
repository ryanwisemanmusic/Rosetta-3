const std = @import("std");
const masm = @import("masm_core.zig");

pub const CpuMode = enum(u8) {
    @"8086" = 0,
    @"186" = 1,
    @"286" = 2,
    @"386" = 3,
    @"486" = 4,
    @"586" = 5,
    @"686" = 6,
};

pub const OperandEncoding = enum(u8) {
    none = 0,
    e = 1,
    g = 2,
    eax = 3,
    i = 4,
    ib = 5,
    iw = 6,
    id = 7,
    iq = 8,
    d = 9,
    d64 = 10,
    m = 11,
    m64 = 12,
    o = 13,
    s = 14,
    sw = 15,
    sz = 16,
    vs = 17,
    v = 18,
    w = 19,
    z = 20,
    p = 21,
    q = 22,
    r = 23,
    c = 24,
    f = 25,
};

pub const InstructionMode = enum(u8) {
    real = 0,
    protected = 1,
    both = 2,
};

pub const InstructionInfo = struct {
    mnemonic: []const u8,
    opcode: u16,
    form: u8,
    cpu: CpuMode,
    mode: InstructionMode,
    operands: [3]OperandEncoding,
    has_modrm: bool,
    imm_size: u8,
    is_float: bool,
    is_vex: bool,
    is_branch: bool,
};

const INSTRUCTION_TABLE: []const InstructionInfo = &.{
    .{ .mnemonic = "AAA", .opcode = 0x0037, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "AAD", .opcode = 0xD50A, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "AAM", .opcode = 0xD40A, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "AAS", .opcode = 0x003F, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "ADC", .opcode = 0x1000, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "ADD", .opcode = 0x0000, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "AND", .opcode = 0x2000, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "CALL", .opcode = 0xE8, .form = 2, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 4, .is_float = false, .is_vex = false, .is_branch = true },
    .{ .mnemonic = "CBW", .opcode = 0x98, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "CLC", .opcode = 0xF8, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "CLD", .opcode = 0xFC, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "CMP", .opcode = 0x3800, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "CMPSB", .opcode = 0xA6, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "CWD", .opcode = 0x99, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "DAA", .opcode = 0x27, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "DEC", .opcode = 0x48, .form = 3, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "DIV", .opcode = 0xF6F0, .form = 4, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "HLT", .opcode = 0xF4, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "IDIV", .opcode = 0xF6F8, .form = 4, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "IMUL", .opcode = 0xF6E8, .form = 4, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "INC", .opcode = 0x40, .form = 3, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "INT", .opcode = 0xCC, .form = 5, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 1, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "INTO", .opcode = 0xCE, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "IRET", .opcode = 0xCF, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "JMP", .opcode = 0xE9, .form = 2, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 4, .is_float = false, .is_vex = false, .is_branch = true },
    .{ .mnemonic = "LAHF", .opcode = 0x9F, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "LEA", .opcode = 0x8D, .form = 6, .cpu = .@"8086", .mode = .both, .operands = .{ .g, .m, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "LEAVE", .opcode = 0xC9, .form = 0, .cpu = .@"186", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "LODSB", .opcode = 0xAC, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "LOOP", .opcode = 0xE2, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 1, .is_float = false, .is_vex = false, .is_branch = true },
    .{ .mnemonic = "MOV", .opcode = 0x8800, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "MOVSB", .opcode = 0xA4, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "MUL", .opcode = 0xF6E0, .form = 4, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "NEG", .opcode = 0xF6D8, .form = 4, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "NOP", .opcode = 0x90, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "NOT", .opcode = 0xF6D0, .form = 4, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "OR", .opcode = 0x0800, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "OUT", .opcode = 0xE6, .form = 7, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 1, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "POP", .opcode = 0x8F, .form = 8, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "POPA", .opcode = 0x61, .form = 0, .cpu = .@"186", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "PUSH", .opcode = 0x50, .form = 9, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "PUSHA", .opcode = 0x60, .form = 0, .cpu = .@"186", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "RET", .opcode = 0xC3, .form = 10, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "RETN", .opcode = 0xC3, .form = 10, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "RETF", .opcode = 0xCB, .form = 10, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "SAHF", .opcode = 0x9E, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "SBB", .opcode = 0x1800, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "SCASB", .opcode = 0xAE, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "STC", .opcode = 0xF9, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "STD", .opcode = 0xFD, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "STOSB", .opcode = 0xAA, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "SUB", .opcode = 0x2800, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "TEST", .opcode = 0x8400, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "XCHG", .opcode = 0x8600, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "XLAT", .opcode = 0xD7, .form = 0, .cpu = .@"8086", .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
    .{ .mnemonic = "XOR", .opcode = 0x3000, .form = 1, .cpu = .@"8086", .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false },
};

pub fn lookupInstruction(mnemonic: []const u8) ?InstructionInfo {
    for (INSTRUCTION_TABLE) |info| {
        if (std.ascii.eqlIgnoreCase(mnemonic, info.mnemonic)) return info;
    }
    return null;
}

pub fn isInstructionAllowed(info: InstructionInfo, current_cpu: CpuMode) bool {
    return @intFromEnum(info.cpu) <= @intFromEnum(current_cpu);
}

pub const ModRM = packed struct(u8) {
    rm: u3 = 0,
    reg: u3 = 0,
    mod: u2 = 0,

    pub fn encode(self: ModRM) u8 {
        return @as(u8, @bitCast(self));
    }
};

pub const SIB = packed struct(u8) {
    base: u3 = 0,
    index: u3 = 0,
    scale: u2 = 0,

    pub fn encode(self: SIB) u8 {
        return @as(u8, @bitCast(self));
    }
};

pub const RexPrefix = packed struct(u8) {
    w: bool = false,
    r: bool = false,
    x: bool = false,
    b: bool = false,
    _base: u4 = 0x4,

    pub fn encode(self: RexPrefix) u8 {
        var result: u8 = 0x40;
        if (self.w) result |= 0x08;
        if (self.r) result |= 0x04;
        if (self.x) result |= 0x02;
        if (self.b) result |= 0x01;
        return result;
    }
};

pub const Encoder = struct {
    cpu: CpuMode = .@"386",
    use32: bool = false,
    use64: bool = false,

    pub fn encodeModRM(self: Encoder, mod_val: u2, reg: u3, rm: u3) u8 {
        _ = self;
        const m = ModRM{ .mod = mod_val, .reg = reg, .rm = rm };
        return m.encode();
    }

    pub fn encodeSIB(self: Encoder, scale: u2, index: u3, base: u3) u8 {
        _ = self;
        const sib = SIB{ .scale = scale, .index = index, .base = base };
        return sib.encode();
    }

    pub fn encodeInstruction(_: Encoder, info: InstructionInfo, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        _ = info;
        _ = buffer;
        _ = allocator;
    }
};

test "instruction lookup" {
    const info = lookupInstruction("MOV");
    try std.testing.expect(info != null);
    try std.testing.expectEqualStrings("MOV", info.?.mnemonic);
}

test "instruction CPU compatibility" {
    const info = lookupInstruction("POPA").?;
    try std.testing.expect(!isInstructionAllowed(info, .@"8086"));
    try std.testing.expect(isInstructionAllowed(info, .@"186"));
}

test "ModRM encoding" {
    const modrm = ModRM{ .mod = 3, .reg = 0, .rm = 0 };
    try std.testing.expectEqual(@as(u8, 0xC0), modrm.encode());
}

test "REX prefix encoding" {
    const rex = RexPrefix{ .w = true, .r = false, .x = false, .b = false };
    try std.testing.expectEqual(@as(u8, 0x48), rex.encode());
}
