const std = @import("std");
const nasm = @import("nasm_core.zig");

pub const MAX_OPERANDS = 5;

pub const opcode = enum(u16) {
    invalid = 0,
    db = 1,
    dw = 2,
    dd = 3,
    dq = 4,
    dt = 5,
    do = 6,
    dy = 7,
    dz = 8,
    resb = 9,
    resw = 10,
    resd = 11,
    resq = 12,
    rest = 13,
    reso = 14,
    resy = 15,
    resz = 16,
    incbin = 17,
    _first = 18,
};

pub const IF_ = enum(u16) {
    sm0 = 0,
    sm1 = 1,
    sm2 = 2,
    sm3 = 3,
    sm4 = 4,
    ar0 = 5,
    ar1 = 6,
    ar2 = 7,
    ar3 = 8,
    ar4 = 9,
    sb = 10,
    sw = 11,
    sd = 12,
    sq = 13,
    st = 14,
    so = 15,
    sy = 16,
    sz = 17,
    nwsize = 18,
    osize = 19,
    asize = 20,
    anysize = 21,
    sx = 22,
    sdword = 23,
    pseudo = 24,
    jmp_relax = 25,
    jcc_hint = 26,
    opt = 27,
    latevex = 28,
    norex = 29,
    noapx = 30,
    nf = 31,
    nf_r = 32,
    nf_n = 33,
    nf_e = 34,
    zu = 35,
    zu_r = 36,
    zu_e = 37,
    lig = 38,
    wig = 39,
    ww = 40,
    sib = 41,
    lock = 42,
    lock1 = 43,
    nolong = 44,
    long = 45,
    nohle = 46,
    mib = 47,
    bnd = 48,
    rex2 = 49,
    hle = 50,
    fl = 51,
    mopvec = 52,
    scc = 53,
    bestdis = 54,
    dfv = 55,
    vex = 64,
    evex = 65,
    priv = 66,
    smm = 67,
    prot = 68,
    undoc = 69,
    fpu = 70,
    mmx = 71,
    @"3dnow" = 72,
    sse = 73,
    sse2 = 74,
    sse3 = 75,
    vmx = 76,
    ssse3 = 77,
    sse4a = 78,
    sse41 = 79,
    sse42 = 80,
    sse5 = 81,
    avx = 82,
};

pub const Itemplate_flags = packed struct(u64) {
    sm0: bool = false,
    sm1: bool = false,
    sm2: bool = false,
    sm3: bool = false,
    sm4: bool = false,
    ar0: bool = false,
    ar1: bool = false,
    ar2: bool = false,
    ar3: bool = false,
    ar4: bool = false,
    sb: bool = false,
    sw: bool = false,
    sd: bool = false,
    sq: bool = false,
    st: bool = false,
    so: bool = false,
    sy: bool = false,
    sz: bool = false,
    nwsize: bool = false,
    osize: bool = false,
    asize: bool = false,
    anysize: bool = false,
    sx: bool = false,
    sdword: bool = false,
    pseudo: bool = false,
    jmp_relax: bool = false,
    jcc_hint: bool = false,
    opt: bool = false,
    latevex: bool = false,
    norex: bool = false,
    noapx: bool = false,
    nf: bool = false,
    nf_r: bool = false,
    nf_n: bool = false,
    nf_e: bool = false,
    zu: bool = false,
    zu_r: bool = false,
    zu_e: bool = false,
    lig: bool = false,
    wig: bool = false,
    ww: bool = false,
    sib: bool = false,
    lock: bool = false,
    lock1: bool = false,
    nolong: bool = false,
    long_flag: bool = false,
    nohle: bool = false,
    mib: bool = false,
    bnd: bool = false,
    rex2: bool = false,
    hle: bool = false,
    fl: bool = false,
    mopvec: bool = false,
    scc: bool = false,
    bestdis: bool = false,
    dfv: bool = false,
    _pad1: u8 = 0,
    vex: bool = false,
    evex: bool = false,
    priv: bool = false,
    smm: bool = false,
    prot: bool = false,
    undoc: bool = false,
    fpu: bool = false,
    mmx: bool = false,
    @"3dnow": bool = false,
    sse: bool = false,
    sse2: bool = false,
    sse3: bool = false,
    vmx: bool = false,
    ssse3: bool = false,
    sse4a: bool = false,
    sse41: bool = false,
    sse42: bool = false,
    sse5: bool = false,
    avx: bool = false,
};

pub const Itemplate = struct {
    opcode_idx: opcode,
    operands: [MAX_OPERANDS]u64,
    opd_count: u32,
    flags: Itemplate_flags,
    iflag_idx: u32,
};

pub const ItemplateList = struct {
    template: *const Itemplate,
    sorted_ofs: u32,
};

pub const RexPrefix = packed struct(u32) {
    b: bool = false,
    x: bool = false,
    r: bool = false,
    w_val: bool = false,
    _pad: u3 = 0,
    l: bool = false,
    p: bool = false,
    h: bool = false,
    v: bool = false,
    nh: bool = false,
    ev: bool = false,
    rex2: bool = false,
    b1: bool = false,
    x1: bool = false,
    r1: bool = false,
    nw: bool = false,
    bv: bool = false,
    xv: bool = false,
    rv: bool = false,
    _pad2: u13 = 0,
};

pub const ModRM = packed struct(u8) {
    rm: u3 = 0,
    reg_val: u3 = 0,
    mod_val: u2 = 0,
};

pub const SIB = packed struct(u8) {
    base: u3 = 0,
    index_val: u3 = 0,
    scale: u2 = 0,
};

pub const prefix_pos = enum(u32) {
    wait = 0,
    seg = 1,
    asize = 2,
    lock = 3,
    osize = 4,
    rep = 5,
    rex = 6,
    nf = 7,
    zu = 8,
    maxprefix = 9,
};

pub const vex_class = enum(u32) {
    vex = 0,
    xop = 1,
    evex = 2,
};

pub const ea_flags = enum(u32) {
    byteoffs = 1,
    wordoffs = 2,
    timestwo = 4,
    rel = 8,
    abs = 16,
    mib = 32,
    sib_ea = 64,
    notfsgs = 128,
    fs = 256,
    gs = 512,
};

pub const encoder = struct {
    pub fn encodeModRM(mod_val: u2, reg_val: u3, rm: u3) u8 {
        return @as(u8, @intCast(mod_val)) << 6 | @as(u8, @intCast(reg_val)) << 3 | @as(u8, @intCast(rm));
    }

    pub fn encodeSIB(scale: u2, index_val: u3, base: u3) u8 {
        return @as(u8, @intCast(scale)) << 6 | @as(u8, @intCast(index_val)) << 3 | @as(u8, @intCast(base));
    }
};

test "ModRM encoding" {
    try std.testing.expectEqual(@as(u8, 0xC0), encoder.encodeModRM(3, 0, 0));
    try std.testing.expectEqual(@as(u8, 0x05), encoder.encodeModRM(0, 0, 5));
    try std.testing.expectEqual(@as(u8, 0x4C), encoder.encodeModRM(1, 1, 4));
}

test "SIB encoding" {
    try std.testing.expectEqual(@as(u8, 0x24), encoder.encodeSIB(0, 4, 4));
    try std.testing.expectEqual(@as(u8, 0x40), encoder.encodeSIB(1, 0, 0));
}

test "prefix positions" {
    try std.testing.expect(@intFromEnum(prefix_pos.wait) < @intFromEnum(prefix_pos.rex));
}
