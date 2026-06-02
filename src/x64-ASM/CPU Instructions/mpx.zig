pub const feature_flag = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 0;
    pub const reg: usize = 3;
    pub const bit: u5 = 14;
};

pub const Opcode = enum(u16) {
    bndmk,
    bndmov,
    bndcl,
    bndcu,
    bndcn,
    bndstx,
    bndldx,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "bndmk",  .opcode = 0x0F1B, .has_modrm = true },
    .{ .mnemonic = "bndmov", .opcode = 0x0F1A, .has_modrm = true },
    .{ .mnemonic = "bndcl",  .opcode = 0x0F1A, .has_modrm = true },
    .{ .mnemonic = "bndcu",  .opcode = 0x0F1B, .has_modrm = true },
    .{ .mnemonic = "bndcn",  .opcode = 0x0F1B, .has_modrm = true },
    .{ .mnemonic = "bndstx", .opcode = 0x0F1B, .has_modrm = true },
    .{ .mnemonic = "bndldx", .opcode = 0x0F1A, .has_modrm = true },
};
