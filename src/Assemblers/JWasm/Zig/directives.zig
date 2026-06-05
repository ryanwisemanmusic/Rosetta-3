const std = @import("std");
const jwasm = @import("jwasm_core.zig");

pub const DirectiveType = enum(u8) {
    cpu = 0,
    listing = 1,
    listmac = 2,
    segorder = 3,
    simseg = 4,
    hllstart = 5,
    hllexit = 6,
    hllend = 7,
    startexit = 8,
    model = 9,
    radix = 10,
    safeseh = 11,
    errdir = 12,
    conddir = 13,
    loopdir = 14,
    macro = 15,
    macint = 16,
    purge = 17,
    include = 18,
    catstr = 19,
    substr = 20,
    instr_dir = 21,
    sizestr = 22,
    datadir = 23,
    excframe = 24,
    structure = 25,
    typedef = 26,
    record = 27,
    comm = 28,
    extern_dir = 29,
    externdef = 30,
    public_dir = 31,
    proto = 32,
    proc = 33,
    endp = 34,
    local = 35,
    label = 36,
    invoke = 37,
    org = 38,
    align_dir = 39,
    segment = 40,
    ends = 41,
    group = 42,
    assume = 43,
    alias = 44,
    echo = 45,
    end = 46,
    equ = 47,
    incbin = 48,
    includelib = 49,
    name = 50,
    option = 51,
    context = 52,
};

pub const Directive = enum(u16) {
    // Segment directives
    segment = 0,
    ends = 1,
    group = 2,
    assume = 3,
    comment = 4,

    // Model directives
    model = 5,
    code = 6,
    data = 7,
    fardata = 8,
    fardata_q = 9,
    @"const" = 10,
    stack = 11,
    startup = 12,
    exit_dir = 13,

    // PROC directives
    proc = 14,
    endp = 15,
    proto = 16,
    local = 17,
    invoke = 18,

    // Symbol directives
    public = 19,
    @"extern" = 20,
    externdef = 21,
    comm = 22,
    @"export" = 23,

    // Data allocation
    db = 24,
    dw = 25,
    dd = 26,
    dq = 27,
    dt = 28,
    df = 29,
    record = 30,
    @"struct" = 31,
    ends_struct = 32,
    @"union" = 33,
    typedef = 34,

    // Label directives
    @"align" = 35,
    even = 36,
    org = 37,
    label = 38,

    // Macro directives
    macro = 39,
    endm = 40,
    exitm = 41,
    local_macro = 42,
    purge = 43,
    catstr = 44,
    instr_dir = 45,
    substr = 46,
    sizestr = 47,
    textequ = 48,
    equ = 49,
    goto = 50,

    // Conditional assembly
    @"if" = 51,
    ifdef = 52,
    ifndef = 53,
    ifb = 54,
    ifnb = 55,
    ifidn = 56,
    ifidni = 57,
    ifdif = 58,
    ifdifi = 59,
    ife = 60,
    if1 = 61,
    if2 = 62,
    elseif = 63,
    elseifdef = 64,
    elseifndef = 65,
    elseifb = 66,
    elseifnb = 67,
    elseifidn = 68,
    elseifidni = 69,
    elseifdif = 70,
    elseifdifi = 71,
    elseife = 72,
    elseif1 = 73,
    elseif2 = 74,
    @"else" = 75,
    endif = 76,

    // Loop directives
    repeat = 77,
    @"while" = 78,
    @"for" = 79,
    forc = 80,
    irp = 81,
    irpc = 82,
    rept = 83,

    // Listing directives
    list = 84,
    xlist = 85,
    lall = 86,
    sall = 87,
    xall = 88,
    crefl = 89,
    xcref = 90,
    page = 91,
    subtitle = 92,
    title = 93,
    echo = 94,
    listall = 95,
    listif = 96,
    nolistif = 97,
    listmacro_dir = 98,
    listmacroall = 99,
    nolistmacro = 100,
    lfcond = 101,
    sfcond = 102,
    tfcond = 103,
    nocref = 104,

    // Processor directives
    @"8086" = 105,
    @"186" = 106,
    @"286" = 107,
    @"286P" = 108,
    @"386" = 109,
    @"386P" = 110,
    @"486" = 111,
    @"486P" = 112,
    @"586" = 113,
    @"586P" = 114,
    @"686" = 115,
    @"686P" = 116,
    @"8087" = 117,
    @"287" = 118,
    @"387" = 119,
    no87 = 120,
    mmx = 121,
    k3d = 122,
    xmm = 123,
    x64 = 124,
    x64P = 125,

    // Include directives
    include = 126,
    includelib = 127,
    incbin = 128,

    // HLL directives
    dot_if = 129,
    dot_repeat = 130,
    dot_while = 131,
    dot_break = 132,
    dot_continue = 133,
    dot_else = 134,
    dot_elseif = 135,
    dot_endif = 136,
    dot_endw = 137,
    dot_until = 138,
    dot_untilcxz = 139,

    // Segment order
    dosseg = 140,
    dot_seq = 141,
    dot_alpha = 142,
    dot_dosseg = 143,

    // Other
    option = 144,
    alias = 145,
    end = 146,
    assert = 147,
    @"error" = 148,
    name_dir = 149,
    subttl = 150,
    page_plus = 151,
    radix = 152,
    safeseh = 153,
    pushcontext = 154,
    popcontext = 155,
    allocstack = 156,
    endprolog = 157,
    pushframe = 158,
    pushreg = 159,
    savereg = 160,
    savexmm128 = 161,
    setframe = 162,
    _,
};

pub const Option = enum(u16) {
    casemap = 0,
    dotname = 1,
    emulator = 2,
    epilogue = 3,
    expr16 = 4,
    expr32 = 5,
    language = 6,
    ljmp = 7,
    m510 = 8,
    noemulator = 9,
    noljmp = 10,
    nom510 = 11,
    nonekey = 12,
    nooldmacros = 13,
    nooldstructs = 14,
    noreadonly = 15,
    noscoped = 16,
    nosignextend = 17,
    offset = 18,
    oldmacros = 19,
    oldstructs = 20,
    prologue = 21,
    readonly = 22,
    scoped = 23,
    segment = 24,
    setif = 25,
    fieldalign = 26,
    procalign = 27,
    renamekeyword = 28,
    dllimport = 29,
    codeview = 30,
    stackbase = 31,
    _,
};

pub const DirectiveInfo = struct {
    name: []const u8,
    directive: Directive,
    has_operands: bool,
    has_body: bool,
    requires_pass: u8,
};

pub const DIRECTIVE_TABLE: []const DirectiveInfo = &.{
    // Segment directives
    .{ .name = "SEGMENT", .directive = .segment, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ENDS", .directive = .ends, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "GROUP", .directive = .group, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "ASSUME", .directive = .assume, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "COMMENT", .directive = .comment, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Model directives
    .{ .name = ".MODEL", .directive = .model, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".CODE", .directive = .code, .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = ".DATA", .directive = .data, .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = ".FARDATA", .directive = .fardata, .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = ".FARDATA?", .directive = .fardata_q, .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = ".STACK", .directive = .stack, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = ".CONST", .directive = .@"const", .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = ".STARTUP", .directive = .startup, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".EXIT", .directive = .exit_dir, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // PROC directives
    .{ .name = "PROC", .directive = .proc, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ENDP", .directive = .endp, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "PROTO", .directive = .proto, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "LOCAL", .directive = .local, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "INVOKE", .directive = .invoke, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Symbol directives
    .{ .name = "PUBLIC", .directive = .public, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "EXTERN", .directive = .@"extern", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "EXTRN", .directive = .@"extern", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "EXTERNDEF", .directive = .externdef, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "COMM", .directive = .comm, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Data allocation
    .{ .name = "DB", .directive = .db, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "DW", .directive = .dw, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "DD", .directive = .dd, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "DQ", .directive = .dq, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "DT", .directive = .dt, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "DF", .directive = .df, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Type directives
    .{ .name = "RECORD", .directive = .record, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "STRUCT", .directive = .@"struct", .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "STRUC", .directive = .@"struct", .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "UNION", .directive = .@"union", .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "TYPEDEF", .directive = .typedef, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "ALIAS", .directive = .alias, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "TEXTEQU", .directive = .textequ, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "EQU", .directive = .equ, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "=", .directive = .equ, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "CATSTR", .directive = .catstr, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "SUBSTR", .directive = .substr, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "INSTR", .directive = .instr_dir, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "SIZESTR", .directive = .sizestr, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Label directives
    .{ .name = "ALIGN", .directive = .@"align", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "EVEN", .directive = .even, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = "ORG", .directive = .org, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "LABEL", .directive = .label, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Macro directives
    .{ .name = "MACRO", .directive = .macro, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ENDM", .directive = .endm, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = "EXITM", .directive = .exitm, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "PURGE", .directive = .purge, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "GOTO", .directive = .goto, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Conditional assembly
    .{ .name = "IF", .directive = .@"if", .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFDEF", .directive = .ifdef, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFNDEF", .directive = .ifndef, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFB", .directive = .ifb, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFNB", .directive = .ifnb, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFIDN", .directive = .ifidn, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFIDNI", .directive = .ifidni, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFDIF", .directive = .ifdif, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFDIFI", .directive = .ifdifi, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IFE", .directive = .ife, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IF1", .directive = .if1, .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = "IF2", .directive = .if2, .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIF", .directive = .elseif, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFE", .directive = .elseife, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFDEF", .directive = .elseifdef, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFNDEF", .directive = .elseifndef, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFB", .directive = .elseifb, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFNB", .directive = .elseifnb, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFIDN", .directive = .elseifidn, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFIDNI", .directive = .elseifidni, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFDIF", .directive = .elseifdif, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSEIFDIFI", .directive = .elseifdifi, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "ELSE", .directive = .@"else", .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = "ENDIF", .directive = .endif, .has_operands = false, .has_body = false, .requires_pass = 0 },

    // Loop directives
    .{ .name = "REPEAT", .directive = .repeat, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "REPT", .directive = .rept, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "WHILE", .directive = .@"while", .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "FOR", .directive = .@"for", .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "FORC", .directive = .forc, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IRP", .directive = .irp, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = "IRPC", .directive = .irpc, .has_operands = true, .has_body = true, .requires_pass = 0 },

    // Listing directives
    .{ .name = ".LIST", .directive = .list, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".XLIST", .directive = .xlist, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".LALL", .directive = .lall, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".SALL", .directive = .sall, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".XALL", .directive = .xall, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".CREF", .directive = .crefl, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".XCREF", .directive = .xcref, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".LISTALL", .directive = .listall, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".LISTIF", .directive = .listif, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".LFCOND", .directive = .lfcond, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".SFCOND", .directive = .sfcond, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".TFCOND", .directive = .tfcond, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".NOCREF", .directive = .nocref, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".NOLISTIF", .directive = .nolistif, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".LISTMACRO", .directive = .listmacro_dir, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".LISTMACROALL", .directive = .listmacroall, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".NOLISTMACRO", .directive = .nolistmacro, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = "PAGE", .directive = .page, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "SUBTITLE", .directive = .subtitle, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "SUBTTL", .directive = .subttl, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "TITLE", .directive = .title, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "%OUT", .directive = .echo, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "ECHO", .directive = .echo, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Processor directives
    .{ .name = ".8086", .directive = .@"8086", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".186", .directive = .@"186", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".286", .directive = .@"286", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".286P", .directive = .@"286P", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".386", .directive = .@"386", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".386P", .directive = .@"386P", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".486", .directive = .@"486", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".486P", .directive = .@"486P", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".586", .directive = .@"586", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".586P", .directive = .@"586P", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".686", .directive = .@"686", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".686P", .directive = .@"686P", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".8087", .directive = .@"8087", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".287", .directive = .@"287", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".387", .directive = .@"387", .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".NO87", .directive = .no87, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".MMX", .directive = .mmx, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".K3D", .directive = .k3d, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".XMM", .directive = .xmm, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".X64", .directive = .x64, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".X64P", .directive = .x64P, .has_operands = false, .has_body = false, .requires_pass = 0 },

    // Include directives
    .{ .name = "INCLUDE", .directive = .include, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "INCLUDELIB", .directive = .includelib, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "INCBIN", .directive = .incbin, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // HLL directives
    .{ .name = ".IF", .directive = .dot_if, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = ".REPEAT", .directive = .dot_repeat, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = ".WHILE", .directive = .dot_while, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = ".BREAK", .directive = .dot_break, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".CONTINUE", .directive = .dot_continue, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ELSE", .directive = .dot_else, .has_operands = false, .has_body = true, .requires_pass = 0 },
    .{ .name = ".ELSEIF", .directive = .dot_elseif, .has_operands = true, .has_body = true, .requires_pass = 0 },
    .{ .name = ".ENDIF", .directive = .dot_endif, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ENDW", .directive = .dot_endw, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".UNTIL", .directive = .dot_until, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".UNTILCXZ", .directive = .dot_untilcxz, .has_operands = true, .has_body = false, .requires_pass = 0 },

    // Segment order directives
    .{ .name = ".SEQ", .directive = .dot_seq, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ALPHA", .directive = .dot_alpha, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".DOSSEG", .directive = .dot_dosseg, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = "DOSSEG", .directive = .dosseg, .has_operands = false, .has_body = false, .requires_pass = 0 },

    // Other
    .{ .name = "OPTION", .directive = .option, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "END", .directive = .end, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERR", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERR1", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 1 },
    .{ .name = ".ERR2", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 2 },
    .{ .name = ".ERRE", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRNZ", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRDIF", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRDIFI", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRIDN", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRIDNI", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRB", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRNB", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRDEF", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ERRNDEF", .directive = .@"error", .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "NAME", .directive = .name_dir, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".RADIX", .directive = .radix, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "PUSHCONTEXT", .directive = .pushcontext, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = "POPCONTEXT", .directive = .popcontext, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".SAFESEH", .directive = .safeseh, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ALLOCSTACK", .directive = .allocstack, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".ENDPROLOG", .directive = .endprolog, .has_operands = false, .has_body = false, .requires_pass = 0 },
    .{ .name = ".PUSHFRAME", .directive = .pushframe, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".PUSHREG", .directive = .pushreg, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".SAVEREG", .directive = .savereg, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".SAVEXMM128", .directive = .savexmm128, .has_operands = true, .has_body = false, .requires_pass = 0 },
    .{ .name = ".SETFRAME", .directive = .setframe, .has_operands = true, .has_body = false, .requires_pass = 0 },
};

pub fn lookupDirective(name: []const u8) ?DirectiveInfo {
    for (DIRECTIVE_TABLE) |info| {
        if (std.ascii.eqlIgnoreCase(name, info.name)) return info;
    }
    return null;
}

pub fn isSegmentDirective(d: Directive) bool {
    return switch (d) {
        .segment, .ends, .group, .assume => true,
        else => false,
    };
}

pub fn isModelDirective(d: Directive) bool {
    return switch (d) {
        .model, .code, .data, .fardata, .fardata_q, .@"const", .stack, .startup, .exit_dir => true,
        else => false,
    };
}

pub fn isConditionalDirective(d: Directive) bool {
    return switch (d) {
        .@"if", .ifdef, .ifndef, .ifb, .ifnb, .ifidn, .ifidni, .ifdif, .ifdifi, .ife, .if1, .if2, .elseif, .elseife, .elseifdef, .elseifndef, .elseifb, .elseifnb, .elseifidn, .elseifidni, .elseifdif, .elseifdifi, .elseif1, .elseif2, .@"else", .endif => true,
        else => false,
    };
}

pub fn isLoopDirective(d: Directive) bool {
    return switch (d) {
        .repeat, .rept, .@"while", .@"for", .forc, .irp, .irpc => true,
        else => false,
    };
}

pub fn isHllDirective(d: Directive) bool {
    return switch (d) {
        .dot_if, .dot_repeat, .dot_while, .dot_break, .dot_continue, .dot_else, .dot_elseif, .dot_endif, .dot_endw, .dot_until, .dot_untilcxz => true,
        else => false,
    };
}

pub fn isProcDirective(d: Directive) bool {
    return switch (d) {
        .proc, .endp, .proto, .local, .invoke => true,
        else => false,
    };
}

pub fn isProcessorDirective(d: Directive) bool {
    return switch (d) {
        .@"8086", .@"186", .@"286", .@"286P", .@"386", .@"386P", .@"486", .@"486P", .@"586", .@"586P", .@"686", .@"686P", .@"8087", .@"287", .@"387", .no87, .mmx, .k3d, .xmm, .x64, .x64P => true,
        else => false,
    };
}

pub fn isExcframeDirective(d: Directive) bool {
    return switch (d) {
        .allocstack, .endprolog, .pushframe, .pushreg, .savereg, .savexmm128, .setframe => true,
        else => false,
    };
}

test "directive lookup" {
    const info = lookupDirective("SEGMENT");
    try std.testing.expect(info != null);
    try std.testing.expectEqual(@as(Directive, .segment), info.?.directive);
}

test "directive lookup JWasm specific" {
    try std.testing.expect(lookupDirective(".X64") != null);
    try std.testing.expect(lookupDirective("INCBIN") != null);
    try std.testing.expect(lookupDirective(".ALLOCSTACK") != null);
    try std.testing.expect(lookupDirective("GOTO") != null);
}

test "conditional assembly detection" {
    try std.testing.expect(isConditionalDirective(.@"if"));
    try std.testing.expect(isConditionalDirective(.elseif));
    try std.testing.expect(!isConditionalDirective(.macro));
}

test "model directive detection" {
    try std.testing.expect(isModelDirective(.model));
    try std.testing.expect(isModelDirective(.code));
}

test "HLL directive detection" {
    try std.testing.expect(isHllDirective(.dot_if));
    try std.testing.expect(!isHllDirective(.segment));
}

test "processor directive detection" {
    try std.testing.expect(isProcessorDirective(.@"386"));
    try std.testing.expect(isProcessorDirective(.x64));
}

test "exception frame directive detection" {
    try std.testing.expect(isExcframeDirective(.allocstack));
    try std.testing.expect(isExcframeDirective(.pushreg));
}
