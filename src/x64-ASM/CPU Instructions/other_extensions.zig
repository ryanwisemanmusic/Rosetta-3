pub const Movdir64bOpcode = enum(u16) {
    movdir64b,
};

pub const movdir64b_encodings = &[_]struct { mnemonic: []const u8, opcode: u8 }{
    .{ .mnemonic = "movdir64b", .opcode = 0x0F },
};

pub const UmOnitorOpcode = enum(u16) {
    umonitor,
    umwait,
    tpause,
};

pub const umonitor_encodings = &[_]struct { mnemonic: []const u8, opcode: u8 }{
    .{ .mnemonic = "umonitor", .opcode = 0x0F },
    .{ .mnemonic = "umwait",   .opcode = 0x0F },
    .{ .mnemonic = "tpause",   .opcode = 0x0F },
};

pub const XcryptOpcode = enum(u16) {
    xstore,
    xcryptecb,
    xcryptcbc,
    xcryptctr,
    xcryptcfb,
    xcryptofb,
    montmul,
    xsha1,
    xsha256,
};

pub const xcrypt_encodings = &[_]struct { mnemonic: []const u8, opcode: u8, rep_prefix: bool }{
    .{ .mnemonic = "xstore",      .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "xcryptecb",   .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "xcryptcbc",   .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "xcryptctr",   .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "xcryptcfb",   .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "xcryptofb",   .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "montmul",     .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "xsha1",       .opcode = 0x0F, .rep_prefix = true },
    .{ .mnemonic = "xsha256",     .opcode = 0x0F, .rep_prefix = true },
};

pub const VaesPclmulOpcode = enum(u16) {
    aesenc,
    aesenclast,
    aesdec,
    aesdeclast,
    vaesenc,
    vaesenclast,
    vaesdec,
    vaesdeclast,
    vpclmullqlqdq,
    vpclmulhqlqdq,
    vpclmullqhqdq,
    vpclmulhqhqdq,
    vpclmulqdq,
};

const VaesEnc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
    vex_only: bool,
    evex_only: bool,
};

pub const vaes_encodings = &[_]VaesEnc{
    .{ .mnemonic = "aesenc",       .opcode = 0x0F38DC, .has_modrm = true, .vex_only = false, .evex_only = false },
    .{ .mnemonic = "aesenclast",   .opcode = 0x0F38DD, .has_modrm = true, .vex_only = false, .evex_only = false },
    .{ .mnemonic = "aesdec",       .opcode = 0x0F38DE, .has_modrm = true, .vex_only = false, .evex_only = false },
    .{ .mnemonic = "aesdeclast",   .opcode = 0x0F38DF, .has_modrm = true, .vex_only = false, .evex_only = false },
    .{ .mnemonic = "vaesenc",      .opcode = 0x0F38DC, .has_modrm = true, .vex_only = false, .evex_only = true },
    .{ .mnemonic = "vaesenclast",  .opcode = 0x0F38DD, .has_modrm = true, .vex_only = false, .evex_only = true },
    .{ .mnemonic = "vaesdec",      .opcode = 0x0F38DE, .has_modrm = true, .vex_only = false, .evex_only = true },
    .{ .mnemonic = "vaesdeclast",  .opcode = 0x0F38DF, .has_modrm = true, .vex_only = false, .evex_only = true },
    .{ .mnemonic = "vpclmulqdq",   .opcode = 0x0F3A44, .has_modrm = true, .vex_only = false, .evex_only = true },
    .{ .mnemonic = "vpclmullqlqdq", .opcode = 0x0F3A44, .has_modrm = true, .vex_only = false, .evex_only = false },
    .{ .mnemonic = "vpclmulhqlqdq", .opcode = 0x0F3A44, .has_modrm = true, .vex_only = false, .evex_only = false },
    .{ .mnemonic = "vpclmullqhqdq", .opcode = 0x0F3A44, .has_modrm = true, .vex_only = false, .evex_only = false },
    .{ .mnemonic = "vpclmulhqhqdq", .opcode = 0x0F3A44, .has_modrm = true, .vex_only = false, .evex_only = false },
};

pub const GatherOpcode = enum(u16) {
    vgatherdpd,
    vgatherdps,
    vgatherqpd,
    vgatherqps,
    vpgatherdd,
    vpgatherdq,
    vpgatherqd,
    vpgatherqq,
};

const GatherEnc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const gather_encodings = &[_]GatherEnc{
    .{ .mnemonic = "vgatherdpd",  .opcode = 0x0F3892, .has_modrm = true },
    .{ .mnemonic = "vgatherdps",  .opcode = 0x0F3892, .has_modrm = true },
    .{ .mnemonic = "vgatherqpd",  .opcode = 0x0F3893, .has_modrm = true },
    .{ .mnemonic = "vgatherqps",  .opcode = 0x0F3893, .has_modrm = true },
    .{ .mnemonic = "vpgatherdd",  .opcode = 0x0F3890, .has_modrm = true },
    .{ .mnemonic = "vpgatherdq",  .opcode = 0x0F3890, .has_modrm = true },
    .{ .mnemonic = "vpgatherqd",  .opcode = 0x0F3891, .has_modrm = true },
    .{ .mnemonic = "vpgatherqq",  .opcode = 0x0F3891, .has_modrm = true },
};

pub const VpcmpOpcode = enum(u16) {
    vpcmpeqb,
    vpcmpeqw,
    vpcmpeqd,
    vpcmpeqq,
    vpcmpgtb,
    vpcmpgtw,
    vpcmpgtd,
    vpcmpgtq,
    vpcmpb,
    vpcmpw,
    vpcmpd,
    vpcmpq,
    vpcmpub,
    vpcmpuw,
    vpcmpud,
    vpcmpuq,
};

const VpcmpEnc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
    imm: bool,
};

pub const vpcmp_encodings = &[_]VpcmpEnc{
    .{ .mnemonic = "vpcmpeqb",  .opcode = 0x0F3874, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpeqw",  .opcode = 0x0F3875, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpeqd",  .opcode = 0x0F3876, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpeqq",  .opcode = 0x0F3829, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpgtb",  .opcode = 0x0F3864, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpgtw",  .opcode = 0x0F3865, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpgtd",  .opcode = 0x0F3866, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpgtq",  .opcode = 0x0F3837, .has_modrm = true, .imm = false },
    .{ .mnemonic = "vpcmpb",    .opcode = 0x0F3A3F, .has_modrm = true, .imm = true },
    .{ .mnemonic = "vpcmpw",    .opcode = 0x0F3A3F, .has_modrm = true, .imm = true },
    .{ .mnemonic = "vpcmpd",    .opcode = 0x0F3A1F, .has_modrm = true, .imm = true },
    .{ .mnemonic = "vpcmpq",    .opcode = 0x0F3A1F, .has_modrm = true, .imm = true },
    .{ .mnemonic = "vpcmpub",   .opcode = 0x0F3A3E, .has_modrm = true, .imm = true },
    .{ .mnemonic = "vpcmpuw",   .opcode = 0x0F3A3E, .has_modrm = true, .imm = true },
    .{ .mnemonic = "vpcmpud",   .opcode = 0x0F3A1E, .has_modrm = true, .imm = true },
    .{ .mnemonic = "vpcmpuq",   .opcode = 0x0F3A1E, .has_modrm = true, .imm = true },
};
