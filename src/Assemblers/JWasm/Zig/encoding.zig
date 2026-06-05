const std = @import("std");
const jwasm = @import("jwasm_core.zig");

pub const CpuMode = enum(u8) {
    @"8086" = 0,
    @"186" = 1,
    @"286" = 2,
    @"386" = 3,
    @"486" = 4,
    @"586" = 5,
    @"686" = 6,
    x64 = 7,
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
    a = 26,
    rgt8 = 27,
    rgt16 = 28,
    i8 = 29,
    i16 = 30,
    i32 = 31,
    i48 = 32,
    i64 = 33,
    i8_u = 34,
    i_3 = 35,
    r8 = 36,
    r16 = 37,
    r32 = 38,
    r64 = 39,
    r16_r32 = 40,
    r16_m16 = 41,
    m08 = 42,
    m16_m32 = 43,
    m32_m64 = 44,
    m48 = 45,
    m64_general = 46,
    m_any = 47,
    mfptr = 48,
    r_ms = 49,
    ms = 50,
    mgt8 = 51,
    r_rms = 52,
    rspec = 53,
    dx_only = 54,
    cl_only = 55,
    st = 56,
    sti = 57,
    xmm = 58,
    xmm_m64 = 59,
};

pub const InstructionMode = enum(u8) {
    real = 0,
    protected = 1,
    both = 2,
};

pub const InstrFlags = packed struct(u16) {
    f_16: bool = false,
    f_32: bool = false,
    f_0f: bool = false,
    f_16a: bool = false,
    f_32a: bool = false,
    f_0fno66: bool = false,
    f_f20f: bool = false,
    _pad: u9 = 0,
};

pub const InstructionInfo = struct {
    mnemonic: []const u8,
    opcode: u16,
    form: u8,
    cpu: u16,
    mode: InstructionMode,
    operands: [3]OperandEncoding,
    has_modrm: bool,
    imm_size: u8,
    is_float: bool,
    is_vex: bool,
    is_branch: bool,
    prefix: u8,
};

const inst_table: []const InstructionInfo = &.{
    .{ .mnemonic = "AAA", .opcode = 0x0037, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "AAD", .opcode = 0xD50A, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "AAM", .opcode = 0xD40A, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "AAS", .opcode = 0x003F, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "ADC", .opcode = 0x1000, .form = 1, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "ADD", .opcode = 0x0000, .form = 1, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "AND", .opcode = 0x2000, .form = 1, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "CALL", .opcode = 0xE8, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .i16, .none, .none }, .has_modrm = false, .imm_size = 2, .is_float = false, .is_vex = false, .is_branch = true, .prefix = 0 },
    .{ .mnemonic = "CBW", .opcode = 0x98, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "CLC", .opcode = 0xF8, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "CLD", .opcode = 0xFC, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "CMP", .opcode = 0x3800, .form = 1, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "CMPSB", .opcode = 0xA6, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "CPUID", .opcode = 0xA20F, .form = 0, .cpu = jwasm.P_586, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "CWD", .opcode = 0x99, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "DAA", .opcode = 0x27, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "DEC", .opcode = 0x48, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "DIV", .opcode = 0xF6F0, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "HLT", .opcode = 0xF4, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "IDIV", .opcode = 0xF6F8, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "IMUL", .opcode = 0xF6E8, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "INC", .opcode = 0x40, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "INT", .opcode = 0xCD, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .ib, .none, .none }, .has_modrm = false, .imm_size = 1, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "INTO", .opcode = 0xCE, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "IRET", .opcode = 0xCF, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "JMP", .opcode = 0xE9, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .i16, .none, .none }, .has_modrm = false, .imm_size = 2, .is_float = false, .is_vex = false, .is_branch = true, .prefix = 0 },
    .{ .mnemonic = "LAHF", .opcode = 0x9F, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "LEA", .opcode = 0x8D, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .g, .m, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "LEAVE", .opcode = 0xC9, .form = 0, .cpu = jwasm.P_186, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "LODSB", .opcode = 0xAC, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "LOOP", .opcode = 0xE2, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 1, .is_float = false, .is_vex = false, .is_branch = true, .prefix = 0 },
    .{ .mnemonic = "MOV", .opcode = 0x8800, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "MOVSB", .opcode = 0xA4, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "MUL", .opcode = 0xF6E0, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "NEG", .opcode = 0xF6D8, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "NOP", .opcode = 0x90, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "NOT", .opcode = 0xF6D0, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .none, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "OR", .opcode = 0x0800, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "OUT", .opcode = 0xE6, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 1, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "POP", .opcode = 0x58, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "POPA", .opcode = 0x61, .form = 0, .cpu = jwasm.P_186, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "PUSH", .opcode = 0x50, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "PUSHA", .opcode = 0x60, .form = 0, .cpu = jwasm.P_186, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "RET", .opcode = 0xC3, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = true, .prefix = 0 },
    .{ .mnemonic = "RETN", .opcode = 0xC3, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = true, .prefix = 0 },
    .{ .mnemonic = "RETF", .opcode = 0xCB, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = true, .prefix = 0 },
    .{ .mnemonic = "SAHF", .opcode = 0x9E, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "SBB", .opcode = 0x1800, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "SCASB", .opcode = 0xAE, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "STC", .opcode = 0xF9, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "STD", .opcode = 0xFD, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "STOSB", .opcode = 0xAA, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "SUB", .opcode = 0x2800, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "TEST", .opcode = 0x8400, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "XCHG", .opcode = 0x8600, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "XLAT", .opcode = 0xD7, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .none, .none, .none }, .has_modrm = false, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
    .{ .mnemonic = "XOR", .opcode = 0x3000, .form = 0, .cpu = jwasm.P_86, .mode = .both, .operands = .{ .e, .g, .none }, .has_modrm = true, .imm_size = 0, .is_float = false, .is_vex = false, .is_branch = false, .prefix = 0 },
};

pub fn lookupInstruction(mnemonic: []const u8) ?InstructionInfo {
    for (inst_table) |info| {
        if (std.ascii.eqlIgnoreCase(mnemonic, info.mnemonic)) return info;
    }
    return null;
}

pub fn isInstructionAllowed(info: InstructionInfo, current_cpu: u16) bool {
    return (info.cpu & 0x00F0) <= (current_cpu & 0x00F0);
}

pub fn isInstructionExtAllowed(info: InstructionInfo, current_cpu: u16) bool {
    const ext_bits = info.cpu & 0xFF00;
    if (ext_bits == 0) return true;
    return (current_cpu & ext_bits) == ext_bits;
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
    cpu: u16 = jwasm.P_386,
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

pub fn cpuFromJwasmFlags(flags: u16) CpuMode {
    const cpu_part = flags & 0x00F0;
    if (cpu_part <= 0x00F0) {
        return switch (cpu_part) {
            0x0000 => .@"8086",
            0x0010 => .@"186",
            0x0020 => .@"286",
            0x0030 => .@"386",
            0x0040 => .@"486",
            0x0050 => .@"586",
            0x0060 => .@"686",
            0x0070 => .x64,
            else => .@"386",
        };
    }
    return .@"386";
}

test "instruction lookup" {
    const info = lookupInstruction("MOV");
    try std.testing.expect(info != null);
    try std.testing.expectEqualStrings("MOV", info.?.mnemonic);
}

test "instruction CPU compatibility" {
    const info = lookupInstruction("POPA").?;
    try std.testing.expect(!isInstructionAllowed(info, jwasm.P_86));
    try std.testing.expect(isInstructionAllowed(info, jwasm.P_186));
}

test "ModRM encoding" {
    const modrm = ModRM{ .mod = 3, .reg = 0, .rm = 0 };
    try std.testing.expectEqual(@as(u8, 0xC0), modrm.encode());
}

test "REX prefix encoding" {
    const rex = RexPrefix{ .w = true, .r = false, .x = false, .b = false };
    try std.testing.expectEqual(@as(u8, 0x48), rex.encode());
}

test "cpu flag translation" {
    try std.testing.expectEqual(@as(CpuMode, .@"386"), cpuFromJwasmFlags(jwasm.P_386));
    try std.testing.expectEqual(@as(CpuMode, .@"586"), cpuFromJwasmFlags(jwasm.P_586));
}

test "instruction extension check" {
    const info = lookupInstruction("CPUID").?;
    try std.testing.expect(isInstructionAllowed(info, jwasm.P_586));
}
