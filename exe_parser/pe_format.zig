pub const dos = struct {
    pub const signature = 0x5A4D;
};

pub const coff = struct {
    pub const signature = 0x00004550;
    pub const machine_i386: u16 = 0x014c;
    pub const machine_amd64: u16 = 0x8664;
    pub const optional_magic_pe32: u16 = 0x010b;
    pub const optional_magic_pe32_plus: u16 = 0x020b;
};
