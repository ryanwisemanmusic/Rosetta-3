const std = @import("std");
const nasm = @import("nasm_core.zig");

pub const Directive = enum(u16) {
    unknown = 0,
    absolute,
    bits,
    common,
    cpu,
    debug,
    default,
    extern_global,
    @"extern",
    @"float",
    global,
    static,
    import_export,
    lib,
    section_pragma,
    @"section",
    segment_pragma,
    @"segment",
    @"warning",
    @"align",
    alloc,
    endprolog,
    endef,
    @";;",
    fpo,
    pushcontext,
    popcontext,

    pub fn fromString(name: []const u8) ?Directive {
        inline for (std.meta.fields(Directive)) |field| {
            if (field.value == 0) continue;
            if (std.ascii.eqlIgnoreCase(name, field.name)) {
                return @field(Directive, field.name);
            }
        }
        return null;
    }
};

pub const PreprocDirective = enum(u32) {
    @"align",
    assign,
    clear,
    define,
    undef,
    elif,
    elifctx,
    elifdef,
    elifempty,
    elifid,
    elifidni,
    elifmacro,
    elifnctx,
    elifndef,
    elifnempty,
    elifnid,
    elifnidni,
    elifnmacro,
    elifnnum,
    elifnstr,
    elifnum,
    elifstr,
    else_dir,
    endm,
    endrep,
    endscope,
    error_dir,
    exitrep,
    fatal_dir,
    iassign,
    idefine,
    iundef,
    include,
    irep,
    irepdef,
    jcc,
    label,
    line,
    macro_dir,
    pathsearch,
    pop,
    praga,
    push,
    rep,
    repdef,
    rmatch,
    rot,
    scope,
    stack,
    strcat,
    strlen,
    strstr,
    stv,
    subst,
    undef_all,

    pub fn fromString(s: []const u8) ?PreprocDirective {
        if (std.ascii.eqlIgnoreCase(s, "macro")) return .macro_dir;
        if (std.ascii.eqlIgnoreCase(s, "imacro")) return .macro_dir;
        if (std.ascii.eqlIgnoreCase(s, "endmacro")) return .endm;
        if (std.ascii.eqlIgnoreCase(s, "error")) return .error_dir;
        if (std.ascii.eqlIgnoreCase(s, "fatal")) return .fatal_dir;
        if (std.ascii.eqlIgnoreCase(s, "else")) return .else_dir;
        inline for (std.meta.fields(PreprocDirective)) |field| {
            if (std.ascii.eqlIgnoreCase(s, field.name)) {
                return @field(PreprocDirective, field.name);
            }
        }
        return null;
    }
};

pub const WarningDirective = enum(u32) {
    all,
    unknown,
    bad_pragma,
    float_overflow,
    float_denorm,
    float_underflow,
    float_toolong,
    user,
    lock,
    macro_defaults,
    macro_selfref,
    negative_rep,
    number_overflow,
    phase,
    env,
    label_orphan,
    label_redef,
    label_redef_late,
    label_mismatch,
    prat_unmatched,
    prat_bad,
    prat_unknown,
    obsolete,
    options_other,
    options_nitpicky,
    bad_char,
    reg_size,
    @"error",
};

pub const CpuLevel = enum(u32) {
    default_cpu = 0,
    p8086,
    p186,
    p286,
    p386,
    p486,
    p586,
    p686,
    pmmx,
    pmme,
    p3dnow,
    ppentiumpro,
    p2,
    p3,
    p4,
    prescott,
    pprescott,
    pprescott_old,
    pk8,
    pk8_sse3,
    pamdfam10,
    pcorei7,
    patom,
    pcoreavx,
    pcoreavx2,
    pcoreavx512,
    pcoreavx512_v5,
    pznver1,
    pznver2,
    pznver3,
    pznver4,
    pznver5,
};

test "directive lookup" {
    try std.testing.expect(Directive.fromString("SECTION") != null);
    try std.testing.expect(Directive.fromString("section") != null);
    try std.testing.expect(Directive.fromString("BITS") != null);
    try std.testing.expect(Directive.fromString("UNKNOWN") == null);
}

test "preproc directive lookup" {
    try std.testing.expect(PreprocDirective.fromString("define") != null);
    try std.testing.expect(PreprocDirective.fromString("macro") != null);
    try std.testing.expect(PreprocDirective.fromString("UNKNOWN") == null);
}

test "CPU level enum" {
    try std.testing.expectEqual(@as(u32, 0), @intFromEnum(CpuLevel.default_cpu));
    try std.testing.expect(@intFromEnum(CpuLevel.p386) > @intFromEnum(CpuLevel.p286));
}
