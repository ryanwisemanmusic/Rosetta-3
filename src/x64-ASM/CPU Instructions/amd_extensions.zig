pub const LwpFeature = struct {
    pub const leaf: u32 = 0x80000001;
    pub const reg: usize = 2;
    pub const bit: u5 = 15;
};

pub const ClzeroFeature = struct {
    pub const leaf: u32 = 0x80000008;
    pub const reg: usize = 1;
    pub const bit: u5 = 0;
};

pub const InvlpgaFeature = struct {
    pub const leaf: u32 = 0x80000001;
    pub const reg: usize = 2;
    pub const bit: u5 = 6;
};

pub const LwpOpcode = enum(u16) {
    llwpcb,
    slwpcb,
    lwpval,
    lwpins,
};

pub const ClzeroOpcode = enum(u16) {
    clzero,
};

pub const InvlpgaOpcode = enum(u16) {
    invlpga,
};

const LwpEnc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const lwp_encodings = &[_]LwpEnc{
    .{ .mnemonic = "llwpcb", .opcode = 0x0F01, .has_modrm = true },
    .{ .mnemonic = "slwpcb", .opcode = 0x0F01, .has_modrm = true },
    .{ .mnemonic = "lwpval", .opcode = 0x0F01, .has_modrm = true },
    .{ .mnemonic = "lwpins", .opcode = 0x0F01, .has_modrm = true },
};

pub const clzero_encodings = &[_]struct { mnemonic: []const u8, opcode: u8 }{
    .{ .mnemonic = "clzero", .opcode = 0x0F },
};

pub const invlpga_encodings = &[_]struct { mnemonic: []const u8, opcode: u8 }{
    .{ .mnemonic = "invlpga", .opcode = 0x0F },
};

pub const RdpIdFeature = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 0;
    pub const reg: usize = 2;
    pub const bit: u5 = 22;
};

pub const RdPidOpcode = enum(u16) {
    rdpid,
};

pub const rdpid_encodings = &[_]struct { mnemonic: []const u8, opcode: u8 }{
    .{ .mnemonic = "rdpid", .opcode = 0x0F },
};

pub const FsGsBaseFeature = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 0;
    pub const reg: usize = 1;
    pub const bit: u5 = 0;
};

pub const FsGsBaseOpcode = enum(u16) {
    rdfsbase,
    rdgsbase,
    wrfsbase,
    wrgsbase,
    rdrand,
    rdseed,
};

const FsGsBaseEnc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const fsgsbase_encodings = &[_]FsGsBaseEnc{
    .{ .mnemonic = "rdfsbase", .opcode = 0x0F01, .has_modrm = true },
    .{ .mnemonic = "rdgsbase", .opcode = 0x0F01, .has_modrm = true },
    .{ .mnemonic = "wrfsbase", .opcode = 0x0F01, .has_modrm = true },
    .{ .mnemonic = "wrgsbase", .opcode = 0x0F01, .has_modrm = true },
    .{ .mnemonic = "rdrand",   .opcode = 0x0FC7, .has_modrm = true },
    .{ .mnemonic = "rdseed",   .opcode = 0x0FC7, .has_modrm = true },
};
