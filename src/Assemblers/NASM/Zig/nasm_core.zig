const std = @import("std");

pub const nasm_version = "3.02rc7";
pub const nasm_major = 3;
pub const nasm_minor = 2;
pub const nasm_subminor = 0;

pub const NO_SEG: i32 = -1;
pub const SEG_ABS: i32 = 0x40000000;
pub const IDLEN_MAX: usize = 4096;

pub const NasmalError = error{
    OutOfMemory,
    SymbolNotFound,
    SymbolRedefined,
    InvalidOperand,
    InvalidExpression,
    InvalidDirective,
    InvalidRegister,
    InvalidSegment,
    InvalidSection,
    PhaseError,
    UnknownInstruction,
    OperandMismatch,
    ForwardRefNotAllowed,
    Unimplemented,
};

pub const token_type = enum(i32) {
    invalid = -1,
    block = -2,
    free = -3,
    eos = 0,

    whitespace = ' ',
    bool_not = '!',
    and_op = '&',
    or_op = '|',
    xor_op = '^',
    not_op = '~',
    mult = '*',
    div = '/',
    mod = '%',
    lpar = '(',
    rpar = ')',
    plus = '+',
    minus = '-',
    comma = ',',
    lbrace = '{',
    rbrace = '}',
    lbracket = '[',
    rbracket = ']',
    qmark = '?',
    eq = '=',
    gt = '>',
    lt = '<',
    colon = ':',

    shl = 256,
    shr,
    sar,
    sdiv,
    smod,
    ge,
    le,
    ne,
    leg,
    dbl_and,
    dbl_or,
    dbl_xor,

    num,
    errnum,
    str,
    errstr,
    id,
    @"float",
    here,
    base,

    seg,
    wrt,
    times,
    floatize,
    strfunc,
    ifunc,
    decorator,
    masm_ptr,
    masm_flat,
    opmask,
    size,
    special,
    prefix_reg,
    brcconst,
    reg,
    insn,

    other,
    preproc_id,
    mmacro_param,
    local_symbol,
    local_macro,
    environ,
    internal_str,
    naked_str,
    preproc_q,
    preproc_qq,
    preproc_sq,
    preproc_sqq,
    paste,
    cond_comma,
    indirect,
    xdef_param,
    smac_start_params,
};

pub const token_flags = enum(u32) {
    brc = 1 << 0,
    brc_opt = 1 << 1,
    brc_any = 1 << 2,
    brdcast = 1 << 3,
    warn = 1 << 4,
    dup = 1 << 5,
    orbit = 1 << 6,
};

pub const out_type = enum(u32) {
    rawdata,
    reserve,
    zerodata,
    address,
    reladdr,
    segment,
    rel1adr,
    rel2adr,
    rel4adr,
    rel8adr,
};

pub const out_flags = enum(u32) {
    wrap = 0,
    signed_val = 1,
    unsigned_val = 2,
    nowarn = 4,
};

pub const bits_mode = enum(u8) {
    bits_16 = 16,
    bits_32 = 32,
    bits_64 = 64,

    pub fn defaultForFormat(format: OutputFormat) bits_mode {
        return switch (format) {
            .bin, .aout, .as86, .obj => .bits_16,
            .coff, .elf32, .ieee, .macho32 => .bits_32,
            .elf64, .macho64, .dbg => .bits_64,
        };
    }
};

pub const OutputFormat = enum {
    bin,
    aout,
    as86,
    coff,
    elf32,
    elf64,
    macho32,
    macho64,
    obj,
    ieee,
    dbg,
};

pub const location = struct {
    offset: i64 = 0,
    segment: i32 = NO_SEG,
    known: bool = false,
};

pub const expr_class = enum(u32) {
    zero = 0,
    const_val = 1,
    segabs = 2,
    simple = 3,
    selfrel = 4,
    seg = 8,
    wrt = 16,
    reloc = 31,
    unknown = 32,
    register = 64,
    regexpr = 128,
    complex = 256,
};

pub const eval_hint = enum(u32) {
    nohint = 0,
    makebase = 1,
    notbase = 2,
    summed = 3,
};

pub const directive_result = enum(u32) {
    unknown,
    ok,
    @"error",
    badparam,
};

pub const nasm_limit = enum(u32) {
    passes,
    stalled,
    macro_levels,
    macro_tokens,
    mmacros,
    rep,
    eval_val,
    lines,
    params,
    max,
};

pub const preproc_mode = enum(u32) {
    normal,
    deps,
    preproc,
};

pub const preproc_opt = enum(u32) {
    trivial = 1,
    noline = 2,
    tasm = 4,
};

pub const optimization = enum(u32) {
    no_jcc_relax = 1,
    no_jmp_relax = 2,
    strict_instr = 4,
    strict_oper = 8,
    disable_fwref = 16,
    strict_osize = 32,
    all_enabled = 0,
    disable_jmp_match = 3,
    level_0 = 55,
    level_1 = 31,
    default_opt = 0,
};

test "version constants" {
    try std.testing.expectEqualStrings("3.02rc7", nasm_version);
    try std.testing.expectEqual(@as(i32, -1), NO_SEG);
    try std.testing.expectEqual(@as(i32, 0x40000000), SEG_ABS);
}

test "bits mode defaults" {
    try std.testing.expectEqual(@as(u8, 16), @intFromEnum(bits_mode.defaultForFormat(.bin)));
    try std.testing.expectEqual(@as(u8, 32), @intFromEnum(bits_mode.defaultForFormat(.coff)));
    try std.testing.expectEqual(@as(u8, 64), @intFromEnum(bits_mode.defaultForFormat(.elf64)));
}

test "token type enum values" {
    try std.testing.expectEqual(@as(i32, -1), @intFromEnum(token_type.invalid));
    try std.testing.expectEqual(@as(i32, 0), @intFromEnum(token_type.eos));
    try std.testing.expectEqual(@as(i32, '+'), @intFromEnum(token_type.plus));
    try std.testing.expectEqual(@as(i32, 256), @intFromEnum(token_type.shl));
}
