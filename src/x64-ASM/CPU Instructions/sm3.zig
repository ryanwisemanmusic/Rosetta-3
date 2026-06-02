const std = @import("std");

pub const feature_flag = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 1;
    pub const reg: usize = 1;
    pub const bit: u5 = 0;
};

pub const Opcode = enum(u16) {
    vsm3rnds2,
    vsm3msg1,
    vsm3msg2,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "vsm3rnds2", .opcode = 0xDA, .has_modrm = true },
    .{ .mnemonic = "vsm3msg1",  .opcode = 0xDA, .has_modrm = true },
    .{ .mnemonic = "vsm3msg2",  .opcode = 0xDA, .has_modrm = true },
};
