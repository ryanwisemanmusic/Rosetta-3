const std = @import("std");

pub const feature_flag = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 0;
    pub const reg: usize = 1;
    pub const bit: u5 = 29;
};

pub const Opcode = enum(u16) {
    sha1rnds4,
    sha1nexte,
    sha1msg1,
    sha1msg2,
    sha256rnds2,
    sha256msg1,
    sha256msg2,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
    imm_size: u8,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "sha1rnds4",  .opcode = 0x0F3ACC, .has_modrm = true,  .imm_size = 1 },
    .{ .mnemonic = "sha1nexte",  .opcode = 0x0F3AC8, .has_modrm = true,  .imm_size = 0 },
    .{ .mnemonic = "sha1msg1",   .opcode = 0x0F38C9, .has_modrm = true,  .imm_size = 0 },
    .{ .mnemonic = "sha1msg2",   .opcode = 0x0F38CA, .has_modrm = true,  .imm_size = 0 },
    .{ .mnemonic = "sha256rnds2", .opcode = 0x0F38CB, .has_modrm = true,  .imm_size = 0 },
    .{ .mnemonic = "sha256msg1",  .opcode = 0x0F38CC, .has_modrm = true,  .imm_size = 0 },
    .{ .mnemonic = "sha256msg2",  .opcode = 0x0F38CD, .has_modrm = true,  .imm_size = 0 },
};

pub fn findByMnemonic(mnemonic: []const u8) ?Enc {
    for (encodings) |e| {
        if (std.mem.eql(u8, e.mnemonic, mnemonic)) return e;
    }
    return null;
}
