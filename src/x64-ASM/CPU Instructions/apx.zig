pub const feature_flag = struct {
    pub const leaf: u32 = 7;
    pub const subleaf: u32 = 1;
    pub const reg: usize = 3;
    pub const bit: u5 = 21;
};

pub const Opcode = enum(u16) {
    ccmpnz,
    ccmpz,
    cfcmov,
    add_apx,
    sub_apx,
    and_apx,
    or_apx,
    xor_apx,
    imul_apx,
    adc_apx,
    sbb_apx,
    shl_apx,
    shr_apx,
    sar_apx,
    rol_apx,
    ror_apx,
    rcl_apx,
    rcr_apx,
    inc_apx,
    dec_apx,
    not_apx,
    neg_apx,
    mul_apx,
    div_apx,
    idiv_apx,
    push_apx,
    pop_apx,
    popcnt_apx,
    tzcnt_apx,
    lzcnt_apx,
    jmpabs,
};

const Enc = struct {
    mnemonic: []const u8,
    opcode: u32,
    has_modrm: bool,
    is_evex: bool,
};

pub const encodings = &[_]Enc{
    .{ .mnemonic = "ccmpnz",  .opcode = 0x0F3AF0, .has_modrm = true, .is_evex = true },
    .{ .mnemonic = "ccmpz",   .opcode = 0x0F3AF1, .has_modrm = true, .is_evex = true },
    .{ .mnemonic = "cfcmov",  .opcode = 0x0F3AF2, .has_modrm = true, .is_evex = true },
    .{ .mnemonic = "jmpabs",  .opcode = 0x0F3AF3, .has_modrm = true, .is_evex = true },
};
