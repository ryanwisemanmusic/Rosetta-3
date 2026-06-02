pub const feature_flag = struct {
    pub const leaf: u32 = 1;
    pub const reg: usize = 2;
    pub const bit: u5 = 5;
};

pub const Opcode = enum(u16) {
    vmcall,
    vmlaunch,
    vmresume,
    vmoff,
    vmxoff,
    vmxon,
    vmptrld,
    vmptrst,
    vmclear,
    vmread,
    vmwrite,
    vmlaunch_vmx,
    invept,
    invvpid,
    vmfunc,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "vmcall",     .opcode = 0x0F01C1, .has_modrm = false },
    .{ .mnemonic = "vmlaunch",   .opcode = 0x0F01C2, .has_modrm = false },
    .{ .mnemonic = "vmresume",   .opcode = 0x0F01C3, .has_modrm = false },
    .{ .mnemonic = "vmxoff",     .opcode = 0x0F01C4, .has_modrm = false },
    .{ .mnemonic = "vmxon",      .opcode = 0x0F01C5, .has_modrm = false },
    .{ .mnemonic = "vmclear",    .opcode = 0x0F01C6, .has_modrm = false },
    .{ .mnemonic = "vmptrld",    .opcode = 0x0F01C7, .has_modrm = false },
    .{ .mnemonic = "vmptrst",    .opcode = 0x0F01C8, .has_modrm = false },
    .{ .mnemonic = "vmread",     .opcode = 0x0F78,   .has_modrm = true },
    .{ .mnemonic = "vmwrite",    .opcode = 0x0F79,   .has_modrm = true },
    .{ .mnemonic = "invept",     .opcode = 0x0F01C9, .has_modrm = false },
    .{ .mnemonic = "invvpid",    .opcode = 0x0F01CA, .has_modrm = false },
    .{ .mnemonic = "vmfunc",     .opcode = 0x0F01CB, .has_modrm = false },
};
