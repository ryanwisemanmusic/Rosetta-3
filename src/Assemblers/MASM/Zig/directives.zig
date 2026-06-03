const std = @import("std");
const masm = @import("masm_core.zig");

pub const Directive = enum(u16) {
    // Segment directives
    segment = 0,
    ends = 1,
    @"group" = 2,
    assume = 3,
    comment = 4,

    // Model directives
    model = 5,
    @"code" = 6,
    @"data" = 7,
    fardata = 8,
    fardata_ = 9,
    const_ = 10,
    stack = 11,
    startup = 12,
    exit = 13,

    // PROC directives
    proc = 14,
    endp = 15,
    proto = 16,
    local_proc = 17,
    invoke = 18,

    // Symbol directives
    @"public" = 19,
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
    @"record" = 30,
    @"struct" = 31,
    ends_struct = 32,
    @"union" = 33,
    @"typedef" = 34,

    // Label directives
    @"align" = 35,
    even = 36,
    @"org" = 37,
    label = 38,

    // Macro directives
    macro = 39,
    endm = 40,
    exitm = 41,
    @"local" = 42,
    purge = 43,
    catstr = 44,
    instr = 45,
    substr = 46,
    sizestr = 47,

    // Conditional assembly
    @"if" = 48,
    ifdef = 49,
    ifndef = 50,
    ifb = 51,
    ifnb = 52,
    ifidn = 53,
    ifidni = 54,
    ifdif = 55,
    ifdifi = 56,
    ife = 57,
    if1 = 58,
    if2 = 59,
    elseif = 60,
    @"else" = 61,
    endif = 62,

    // Loop directives
    @"repeat" = 63,
    @"while" = 64,
    @"for" = 65,
    for_ = 66,
    irp = 67,
    irpc = 68,
    endm_repeat = 69,

    // Listing directives
    list = 70,
    xlist = 71,
    lall = 72,
    sall = 73,
    crefl = 74,
    xcref = 75,
    page = 76,
    subtitle = 77,
    title = 78,
    @"echo" = 79,

    // Processor directives
    @"8086" = 80,
    @"286" = 81,
    @"286P" = 82,
    @"386" = 83,
    @"386P" = 84,
    @"486" = 85,
    @"486P" = 86,
    @"586" = 87,
    @"586P" = 88,
    @"686" = 89,
    @"686P" = 90,

    // Include directives
    include = 91,
    includelib = 92,

    // Other
    option = 93,
    alias = 94,
    end = 95,
    @"assert" = 96,
    @"error" = 97,
    name = 98,
    subttl = 99,
    page_plus = 100,
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
    _,
};

pub const DirectiveInfo = struct {
    name: []const u8,
    directive: Directive,
    has_operands: bool,
    has_body: bool,
};

pub const DIRECTIVE_TABLE: []const DirectiveInfo = &.{
    .{ .name = "SEGMENT", .directive = .segment, .has_operands = true, .has_body = true },
    .{ .name = "ENDS", .directive = .ends, .has_operands = true, .has_body = false },
    .{ .name = "GROUP", .directive = .@"group", .has_operands = true, .has_body = false },
    .{ .name = "ASSUME", .directive = .assume, .has_operands = true, .has_body = false },
    .{ .name = "COMMENT", .directive = .comment, .has_operands = true, .has_body = false },
    .{ .name = ".MODEL", .directive = .model, .has_operands = true, .has_body = false },
    .{ .name = ".CODE", .directive = .@"code", .has_operands = false, .has_body = true },
    .{ .name = ".DATA", .directive = .@"data", .has_operands = false, .has_body = true },
    .{ .name = ".FARDATA", .directive = .fardata, .has_operands = false, .has_body = true },
    .{ .name = ".STACK", .directive = .stack, .has_operands = true, .has_body = true },
    .{ .name = ".STARTUP", .directive = .startup, .has_operands = false, .has_body = false },
    .{ .name = ".EXIT", .directive = .exit, .has_operands = true, .has_body = false },
    .{ .name = "PROC", .directive = .proc, .has_operands = true, .has_body = true },
    .{ .name = "ENDP", .directive = .endp, .has_operands = true, .has_body = false },
    .{ .name = "PROTO", .directive = .proto, .has_operands = true, .has_body = false },
    .{ .name = "LOCAL", .directive = .local, .has_operands = true, .has_body = false },
    .{ .name = "INVOKE", .directive = .invoke, .has_operands = true, .has_body = false },
    .{ .name = "PUBLIC", .directive = .@"public", .has_operands = true, .has_body = false },
    .{ .name = "EXTERN", .directive = .@"extern", .has_operands = true, .has_body = false },
    .{ .name = "EXTERNDEF", .directive = .externdef, .has_operands = true, .has_body = false },
    .{ .name = "COMM", .directive = .comm, .has_operands = true, .has_body = false },
    .{ .name = "EXPORT", .directive = .@"export", .has_operands = true, .has_body = false },
    .{ .name = "DB", .directive = .db, .has_operands = true, .has_body = false },
    .{ .name = "DW", .directive = .dw, .has_operands = true, .has_body = false },
    .{ .name = "DD", .directive = .dd, .has_operands = true, .has_body = false },
    .{ .name = "DQ", .directive = .dq, .has_operands = true, .has_body = false },
    .{ .name = "DT", .directive = .dt, .has_operands = true, .has_body = false },
    .{ .name = "DF", .directive = .df, .has_operands = true, .has_body = false },
    .{ .name = "RECORD", .directive = .@"record", .has_operands = true, .has_body = true },
    .{ .name = "STRUCT", .directive = .@"struct", .has_operands = true, .has_body = true },
    .{ .name = "UNION", .directive = .@"union", .has_operands = true, .has_body = true },
    .{ .name = "TYPEDEF", .directive = .@"typedef", .has_operands = true, .has_body = false },
    .{ .name = "ALIGN", .directive = .@"align", .has_operands = true, .has_body = false },
    .{ .name = "EVEN", .directive = .even, .has_operands = false, .has_body = false },
    .{ .name = "ORG", .directive = .@"org", .has_operands = true, .has_body = false },
    .{ .name = "LABEL", .directive = .label, .has_operands = true, .has_body = false },
    .{ .name = "MACRO", .directive = .macro, .has_operands = true, .has_body = true },
    .{ .name = "ENDM", .directive = .endm, .has_operands = false, .has_body = false },
    .{ .name = "EXITM", .directive = .exitm, .has_operands = true, .has_body = false },
    .{ .name = "PURGE", .directive = .purge, .has_operands = true, .has_body = false },
    .{ .name = "CATSTR", .directive = .catstr, .has_operands = true, .has_body = false },
    .{ .name = "INSTR", .directive = .instr, .has_operands = true, .has_body = false },
    .{ .name = "SUBSTR", .directive = .substr, .has_operands = true, .has_body = false },
    .{ .name = "SIZESTR", .directive = .sizestr, .has_operands = true, .has_body = false },
    .{ .name = " IF", .directive = .@"if", .has_operands = true, .has_body = true },
    .{ .name = "IFDEF", .directive = .ifdef, .has_operands = true, .has_body = true },
    .{ .name = "IFNDEF", .directive = .ifndef, .has_operands = true, .has_body = true },
    .{ .name = "IFB", .directive = .ifb, .has_operands = true, .has_body = true },
    .{ .name = "IFNB", .directive = .ifnb, .has_operands = true, .has_body = true },
    .{ .name = "IFIDN", .directive = .ifidn, .has_operands = true, .has_body = true },
    .{ .name = "IFIDNI", .directive = .ifidni, .has_operands = true, .has_body = true },
    .{ .name = "IFDIF", .directive = .ifdif, .has_operands = true, .has_body = true },
    .{ .name = "IFDIFI", .directive = .ifdifi, .has_operands = true, .has_body = true },
    .{ .name = "IFE", .directive = .ife, .has_operands = true, .has_body = true },
    .{ .name = "IF1", .directive = .if1, .has_operands = false, .has_body = true },
    .{ .name = "IF2", .directive = .if2, .has_operands = false, .has_body = true },
    .{ .name = "ELSEIF", .directive = .elseif, .has_operands = true, .has_body = true },
    .{ .name = "ELSE", .directive = .@"else", .has_operands = false, .has_body = true },
    .{ .name = "ENDIF", .directive = .endif, .has_operands = false, .has_body = false },
    .{ .name = "REPEAT", .directive = .@"repeat", .has_operands = true, .has_body = true },
    .{ .name = "WHILE", .directive = .@"while", .has_operands = true, .has_body = true },
    .{ .name = "FOR", .directive = .@"for", .has_operands = true, .has_body = true },
    .{ .name = "IRP", .directive = .irp, .has_operands = true, .has_body = true },
    .{ .name = "IRPC", .directive = .irpc, .has_operands = true, .has_body = true },
    .{ .name = ".LIST", .directive = .list, .has_operands = false, .has_body = false },
    .{ .name = ".XLIST", .directive = .xlist, .has_operands = false, .has_body = false },
    .{ .name = ".LALL", .directive = .lall, .has_operands = false, .has_body = false },
    .{ .name = ".SALL", .directive = .sall, .has_operands = false, .has_body = false },
    .{ .name = ".CREF", .directive = .crefl, .has_operands = false, .has_body = false },
    .{ .name = ".XCREF", .directive = .xcref, .has_operands = false, .has_body = false },
    .{ .name = "PAGE", .directive = .page, .has_operands = true, .has_body = false },
    .{ .name = "SUBTITLE", .directive = .subtitle, .has_operands = true, .has_body = false },
    .{ .name = "SUBTTL", .directive = .subttl, .has_operands = true, .has_body = false },
    .{ .name = "TITLE", .directive = .title, .has_operands = true, .has_body = false },
    .{ .name = "ECHO", .directive = .@"echo", .has_operands = true, .has_body = false },
    .{ .name = ".8086", .directive = .@"8086", .has_operands = false, .has_body = false },
    .{ .name = ".286", .directive = .@"286", .has_operands = false, .has_body = false },
    .{ .name = ".286P", .directive = .@"286P", .has_operands = false, .has_body = false },
    .{ .name = ".386", .directive = .@"386", .has_operands = false, .has_body = false },
    .{ .name = ".386P", .directive = .@"386P", .has_operands = false, .has_body = false },
    .{ .name = ".486", .directive = .@"486", .has_operands = false, .has_body = false },
    .{ .name = ".486P", .directive = .@"486P", .has_operands = false, .has_body = false },
    .{ .name = ".586", .directive = .@"586", .has_operands = false, .has_body = false },
    .{ .name = ".586P", .directive = .@"586P", .has_operands = false, .has_body = false },
    .{ .name = ".686", .directive = .@"686", .has_operands = false, .has_body = false },
    .{ .name = ".686P", .directive = .@"686P", .has_operands = false, .has_body = false },
    .{ .name = "INCLUDE", .directive = .include, .has_operands = true, .has_body = false },
    .{ .name = "INCLUDELIB", .directive = .includelib, .has_operands = true, .has_body = false },
    .{ .name = "OPTION", .directive = .option, .has_operands = true, .has_body = false },
    .{ .name = "ALIAS", .directive = .alias, .has_operands = true, .has_body = false },
    .{ .name = "END", .directive = .end, .has_operands = true, .has_body = false },
    .{ .name = ".ASSERT", .directive = .@"assert", .has_operands = true, .has_body = false },
    .{ .name = ".ERR", .directive = .@"error", .has_operands = true, .has_body = false },
    .{ .name = "NAME", .directive = .name, .has_operands = true, .has_body = false },
};

pub fn lookupDirective(name: []const u8) ?DirectiveInfo {
    for (DIRECTIVE_TABLE) |info| {
        if (std.ascii.eqlIgnoreCase(name, info.name)) return info;
    }
    return null;
}

pub fn isSegmentDirective(d: Directive) bool {
    return switch (d) {
        .segment, .ends, .@"group", .assume => true,
        else => false,
    };
}

pub fn isModelDirective(d: Directive) bool {
    return switch (d) {
        .model, .@"code", .@"data", .fardata, .stack, .startup, .exit => true,
        else => false,
    };
}

pub fn isConditionalDirective(d: Directive) bool {
    return switch (d) {
        .@"if", .ifdef, .ifndef, .ifb, .ifnb, .ifidn, .ifidni,
        .ifdif, .ifdifi, .ife, .if1, .if2, .elseif, .@"else", .endif => true,
        else => false,
    };
}

pub fn isLoopDirective(d: Directive) bool {
    return switch (d) {
        .@"repeat", .@"while", .@"for", .irp, .irpc => true,
        else => false,
    };
}

test "directive lookup" {
    const info = lookupDirective("SEGMENT");
    try std.testing.expect(info != null);
    try std.testing.expectEqual(@as(Directive, .segment), info.?.directive);
}

test "conditional assembly detection" {
    try std.testing.expect(isConditionalDirective(.@"if"));
    try std.testing.expect(isConditionalDirective(.elseif));
    try std.testing.expect(!isConditionalDirective(.macro));
}

test "model directive detection" {
    try std.testing.expect(isModelDirective(.model));
    try std.testing.expect(isModelDirective(.@"code"));
}
