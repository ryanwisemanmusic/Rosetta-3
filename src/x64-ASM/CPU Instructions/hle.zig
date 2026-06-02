pub const feature_flag = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 0;
    pub const reg: usize = 1;
    pub const bit: u5 = 4;
};

pub const Prefix = enum(u16) {
    xacquire = 0xF2,
    xrelease = 0xF3,
};

pub const LockedOpcode = enum(u16) {
    add,
    adc,
    @"and",
    @"or",
    sub,
    xor,
    xchg,
    inc,
    dec,
    neg,
    @"not",
    cmpxchg,
    cmpxchg8b,
    cmpxchg16b,
    bt,
    btr,
    bts,
    btc,
};

const Enc = struct {
    mnemonic: []const u8,
    supports_xacquire: bool,
    supports_xrelease: bool,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "add",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "adc",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "and",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "or",       .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "sub",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "xor",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "xchg",     .supports_xacquire = false, .supports_xrelease = true },
    .{ .mnemonic = "inc",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "dec",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "neg",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "not",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "cmpxchg",  .supports_xacquire = true,  .supports_xrelease = false },
    .{ .mnemonic = "cmpxchg8b", .supports_xacquire = true, .supports_xrelease = false },
    .{ .mnemonic = "bt",       .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "btr",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "bts",      .supports_xacquire = true,  .supports_xrelease = true },
    .{ .mnemonic = "btc",      .supports_xacquire = true,  .supports_xrelease = true },
};
