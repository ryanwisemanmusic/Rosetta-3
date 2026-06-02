pub const Opcode = enum(u16) {
    daa,
    das,
    aaa,
    aas,
    aam,
    aad,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u8,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "daa", .opcode = 0x27 },
    .{ .mnemonic = "das", .opcode = 0x2F },
    .{ .mnemonic = "aaa", .opcode = 0x37 },
    .{ .mnemonic = "aas", .opcode = 0x3F },
    .{ .mnemonic = "aam", .opcode = 0xD4 },
    .{ .mnemonic = "aad", .opcode = 0xD5 },
};
