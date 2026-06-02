const std = @import("std");

pub const feature_flag = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 1;
    pub const reg: usize = 1;
    pub const bit: u5 = 1;
};

pub const Opcode = enum(u16) {
    vsm4rnds4,
    vsm4key4,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "vsm4rnds4", .opcode = 0xDA, .has_modrm = true },
    .{ .mnemonic = "vsm4key4",  .opcode = 0xDA, .has_modrm = true },
};
