pub const feature_flag = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 0;
    pub const reg: usize = 3;
    pub const bit: u5 = 24;
};

pub const Opcode = enum(u16) {
    ldtilecfg,
    sttilecfg,
    tilezero,
    tileloadd,
    tileloaddt1,
    tilestored,
    tdpbssd,
    tdpbsud,
    tdpbusd,
    tdpbuud,
    tdpbf16ps,
    tdpfp16ps,
    tmmrelrow,
    tmmloadrow,
    tmmstorerow,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "ldtilecfg",  .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "sttilecfg",  .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tilezero",   .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tileloadd",  .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tileloaddt1", .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tilestored", .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tdpbssd",    .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tdpbsud",    .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tdpbusd",    .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tdpbuud",    .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tdpbf16ps",  .opcode = 0x0F38C9, .has_modrm = true },
    .{ .mnemonic = "tdpfp16ps",  .opcode = 0x0F38C9, .has_modrm = true },
};
