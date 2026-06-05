const std = @import("std");

pub const VERSION_MAJOR: u8 = 2;
pub const VERSION_MINOR: u8 = 21;
pub const VERSION_PATCH: u8 = 0;
pub const VERSION_STRING: []const u8 = "2.21";

pub const MAX_LINE_LEN: u32 = 600;
pub const MAX_TOKEN: u32 = MAX_LINE_LEN / 4;
pub const MAX_STRING_LEN: u32 = MAX_LINE_LEN - 32;
pub const MAX_ID_LEN: u32 = 247;
pub const MAX_STRUCT_ALIGN: u32 = 32;
pub const MAX_IF_NESTING: u32 = 20;
pub const MAX_SEG_NESTING: u32 = 20;
pub const MAX_MACRO_NESTING: u32 = 40;
pub const MAX_STRUCT_NESTING: u32 = 32;
pub const MAX_LNAME: u32 = 255;
pub const LNAME_NULL: u32 = 0;
pub const MAX_SEGALIGNMENT: u32 = 0xFF;

pub const BIN_SUPPORT: bool = true;
pub const MZ_SUPPORT: bool = true;
pub const PE_SUPPORT: bool = true;
pub const COFF_SUPPORT: bool = true;
pub const DJGPP_SUPPORT: bool = true;
pub const ELF_SUPPORT: bool = true;
pub const DWARF_SUPP: bool = true;
pub const AMD64_SUPPORT: bool = true;
pub const K3DSUPP: bool = true;
pub const SSE3SUPP: bool = true;
pub const VMXSUPP: bool = true;
pub const SVMSUPP: bool = false;
pub const SSSE3SUPP: bool = true;
pub const SSE4SUPP: bool = true;
pub const AVXSUPP: bool = true;
pub const COMDATSUPP: bool = true;
pub const COMDATOMFSUPP: bool = false;
pub const IMAGERELSUPP: bool = true;
pub const SECTIONRELSUPP: bool = true;
pub const FIELDALIGN: bool = true;
pub const PROCALIGN: bool = true;
pub const LOHI32: bool = true;
pub const XMMWORD: bool = true;
pub const RENAMEKEY: bool = true;
pub const MACROLABEL: bool = true;
pub const BACKQUOTES: bool = true;
pub const FPIMMEDIATE: bool = true;
pub const INCBINSUPP: bool = true;
pub const INTELMOVQ: bool = false;
pub const OWFC_SUPPORT: bool = true;
pub const DLLIMPORT: bool = true;
pub const CVOSUPP: bool = true;
pub const MASM_SSE_MEMX: bool = true;
pub const PERCENT_OUT: bool = true;
pub const STACKBASESUPP: bool = true;
pub const VARARGML: bool = true;
pub const FASTPASS: bool = true;
pub const FASTMEM: bool = true;

pub const AssemblerError = error{
    OutOfMemory,
    StackOverflow,
    SourceFileNotFound,
    AssemblyNotComplete,
    InternalError,
    WriteFailed,
    FileNotFound,
    ErrorReadingFile,
    InvalidFileFormat,
    InvalidCommandLine,
    InvalidArgument,
    MissingArgument,
    TooManyArguments,
    ExpressionSyntax,
    ExpressionOutOfRange,
    OperandExpected,
    OperandNotAllowed,
    OperandSizeConflict,
    OperandMustBeRegister,
    OperandMustBeSegment,
    OperandMustBeMemory,
    MustBeRecordFieldName,
    MustBeRecord,
    MustBeRecordOrField,
    MustBeStructure,
    MustBeStructureField,
    MustBeVariable,
    MustBeLabel,
    MustBeType,
    MustBeProc,
    MustBeConstant,
    SymbolNotDefined,
    SymbolAlreadyDefined,
    SymbolTypeConflict,
    SymbolNotPublic,
    SymbolNotExternal,
    SymbolTooManyPublic,
    SymbolTooManyExternal,
    InvalidUseOfExternal,
    SegmentNotDefined,
    SegmentAlignmentConflict,
    SegmentCombineConflict,
    SegmentAlreadyDefined,
    SegmentOffsetOverflow,
    GroupNotDefined,
    GroupAlreadyDefined,
    GroupConflict,
    PhaseErrorBetweenPasses,
    InstructionNotAllowed,
    InvalidInstructionPrefix,
    InvalidModelDirective,
    InvalidModelMemoryModel,
    InvalidModelLanguage,
    InvalidModelOS,
    ProcessorDirectiveConflict,
    CoprocessorDirectiveConflict,
    EndDirectiveMissing,
    EndIfDirectiveMissing,
    EndmDirectiveMissing,
    MacroNotDefined,
    MacroAlreadyDefined,
    MacroPurgingBuiltIn,
    LocalSymbolConflict,
    TooManyLocalSymbols,
    ExpressionTooComplex,
    ValueOutOfRange,
    DivisionByZero,
    IllegalForwardReference,
    ForwardReferenceNeedsOverride,
    RelocationNotSupported,
    ListingNotActive,
    AssertionFailed,
    InvokedError,
};

pub const ret_code = enum(i8) {
    empty = -2,
    @"error" = -1,
    not_error = 0,
    string_expanded = 1,
};

pub const oformat = enum(u8) {
    bin = 0,
    omf = 1,
    coff = 2,
    elf = 3,
};

pub const sformat = enum(u8) {
    none = 0,
    mz = 1,
    pe = 2,
    djgpp = 3,
    @"64bit" = 4,
};

pub const fpo = enum(u8) {
    no_emulation = 0,
    emulation = 1,
};

pub const lang_type = enum(u8) {
    none = 0,
    c = 1,
    syscall = 2,
    stdcall = 3,
    pascal = 4,
    fortran = 5,
    basic = 6,
    fastcall = 7,
};

pub const model_type = enum(u8) {
    none = 0,
    tiny = 1,
    small = 2,
    compact = 3,
    medium = 4,
    large = 5,
    huge = 6,
    flat = 7,
};

pub const seg_order = enum(u8) {
    seq = 0,
    dosseg = 1,
    alpha = 2,
};

pub const listmacro = enum(u8) {
    nolistmacro = 0,
    listmacro = 1,
    listmacroall = 2,
};

pub const assume_segreg = enum(i8) {
    nothing = -2,
    es = 0,
    cs = 1,
    ss = 2,
    ds = 3,
    fs = 4,
    gs = 5,
};

pub const cpu_info = packed struct(u16) {
    no87: bool = false,
    _87: bool = false,
    _287: bool = false,
    _387: bool = false,
    pm: bool = false,
    _86: bool = false,
    _186: bool = false,
    _286: bool = false,
    _386: bool = false,
    _486: bool = false,
    _586: bool = false,
    _686: bool = false,
    mmx: bool = false,
    k3d: bool = false,
    sse1: bool = false,
    sse2: bool = false,

    pub fn encode(self: cpu_info) u16 {
        return @as(u16, @bitCast(self));
    }

    pub fn cpuLevel(self: cpu_info) u8 {
        const val = self.encode();
        return @as(u8, @intCast((val >> 4) & 0x0F));
    }

    pub fn fpuLevel(self: cpu_info) u8 {
        const val = self.encode();
        return @as(u8, @intCast(val & 0x07));
    }
};

pub const P_NO87: u16 = 0x0001;
pub const P_87: u16 = 0x0002;
pub const P_287: u16 = 0x0003;
pub const P_387: u16 = 0x0004;
pub const P_PM: u16 = 0x0008;
pub const P_86: u16 = 0x0000;
pub const P_186: u16 = 0x0010;
pub const P_286: u16 = 0x0020;
pub const P_386: u16 = 0x0030;
pub const P_486: u16 = 0x0040;
pub const P_586: u16 = 0x0050;
pub const P_686: u16 = 0x0060;
pub const P_64: u16 = 0x0070;
pub const P_286p: u16 = P_286 | P_PM;
pub const P_386p: u16 = P_386 | P_PM;
pub const P_486p: u16 = P_486 | P_PM;
pub const P_586p: u16 = P_586 | P_PM;
pub const P_686p: u16 = P_686 | P_PM;
pub const P_64p: u16 = P_64 | P_PM;
pub const P_MMX: u16 = 0x0100;
pub const P_K3D: u16 = 0x0200;
pub const P_SSE1: u16 = 0x0400;
pub const P_SSE2: u16 = 0x0800;
pub const P_SSE3: u16 = 0x1000;
pub const P_SSSE3: u16 = 0x2000;
pub const P_SSE4: u16 = 0x4000;
pub const P_AVX: u16 = 0x8000;

pub const masm_cpu = packed struct(u16) {
    @"8086": bool = false,
    @"186": bool = false,
    @"286": bool = false,
    @"386": bool = false,
    @"486": bool = false,
    @"586": bool = false,
    @"686": bool = false,
    prot: bool = false,
    @"8087": bool = false,
    _reserved: u1 = 0,
    @"287": bool = false,
    @"387": bool = false,
    _pad: u4 = 0,

    pub fn encode(self: masm_cpu) u16 {
        return @as(u16, @bitCast(self));
    }
};

pub const segofssize = enum(u8) {
    use_empty = 0xFE,
    use16 = 0,
    use32 = 1,
    use64 = 2,
};

pub const fastcall_type = enum(u8) {
    msc = 0,
    watcomc = 1,
    win64 = 2,
};

pub const stdcall_decoration = enum(u8) {
    full = 0,
    none = 1,
    half = 2,
};

pub const prologue_epilogue_mode = enum(u8) {
    default = 0,
    macro = 1,
    none = 2,
};

pub const dist_type = enum(u8) {
    near = 0,
    far = 1,
};

pub const os_type = enum(u8) {
    dos = 0,
    os2 = 1,
};

pub const offset_type = enum(u8) {
    group = 0,
    flat = 1,
    segment = 2,
};

pub const win64_flag_values = struct {
    pub const saveregparams: u8 = 0x01;
    pub const autostacksp: u8 = 0x02;
    pub const stackalign16: u8 = 0x04;
    pub const all: u8 = 0x07;
};

pub const cvex_values = enum(u8) {
    min = 0,
    reduced = 1,
    normal = 2,
    max = 3,
};

pub const seg_type = enum(u8) {
    undef = 0,
    code = 1,
    data = 2,
    bss = 3,
    stack = 4,
    abs = 5,
    hdr = 6,
    code16 = 7,
    cdata = 8,
    reloc = 9,
    rsrc = 10,
    @"error" = 11,
};

pub const SymbolType = enum(u8) {
    undefined = 0,
    internal = 1,
    external = 2,
    segment = 3,
    group = 4,
    stack = 5,
    struct_field = 6,
    type = 7,
    alias = 8,
    macro = 9,
    tmacro = 10,
    class_lname = 11,
};

pub const memtype = enum(u8) {
    byte = 0,
    sbyte = 1,
    word = 2,
    sword = 3,
    dword = 4,
    sdword = 5,
    real4 = 6,
    fword = 7,
    qword = 8,
    sqword = 9,
    real8 = 10,
    tbyte = 11,
    real10 = 12,
    oword = 13,
    ymmword = 14,
    proc = 0x80,
    near = 0x81,
    far = 0x82,
    empty = 0xC0,
    bits = 0xC1,
    ptr = 0xC3,
    type_val = 0xC4,
};

pub const OutputFormat = enum(u8) {
    bin = 0,
    omf = 1,
    coff = 2,
    elf = 3,
};

pub const MemoryModel = model_type;

pub const ModelLanguage = lang_type;

pub const SegmentCombine = enum(u8) {
    private = 0,
    public = 1,
    stack = 2,
    common = 3,
    memory = 4,
    at = 5,
};

pub const SegmentAlign = enum(u8) {
    byte = 0,
    word = 1,
    dword = 2,
    para = 3,
    page = 4,
};

pub const ScopeType = enum(u8) {
    global = 0,
    local = 1,
    proc_private = 2,
};

pub const error_messages = struct {
    pub const phase_error = "phase error between passes";
    pub const symbol_not_defined = "symbol not defined";
    pub const symbol_already_defined = "symbol already defined";
    pub const symbol_type_conflict = "symbol type conflict";
    pub const symbol_not_public = "symbol is not public";
    pub const symbol_not_external = "symbol is external";
    pub const expression_syntax = "expression syntax error";
    pub const expression_out_of_range = "expression value out of range";
    pub const operand_expected = "operand expected";
    pub const operand_not_allowed = "operand not allowed";
    pub const operand_size_conflict = "operand size conflict";
    pub const operand_must_be_register = "operand must be a register";
    pub const operand_must_be_segment = "operand must be a segment register";
    pub const operand_must_be_memory = "operand must be a memory reference";
    pub const segment_not_defined = "segment not defined";
    pub const segment_alignment_conflict = "segment alignment conflict";
    pub const segment_combine_conflict = "segment combine type conflict";
    pub const group_not_defined = "group not defined";
    pub const macro_not_defined = "macro not defined";
    pub const macro_already_defined = "macro already defined";
    pub const processor_directive_conflict = "processor directive conflict";
    pub const value_out_of_range = "value out of range";
    pub const division_by_zero = "division by zero";
    pub const illegal_forward_reference = "illegal forward reference";
    pub const relocation_not_supported = "relocation not supported in this format";
    pub const file_not_found = "file not found";
    pub const invalid_model = "invalid model directive";
    pub const end_directive_missing = "END directive missing";
    pub const macro_nesting_too_deep = "macro nesting too deep";
    pub const assertion_failed = "assertion failed";
    pub const invoked_error = "error directive encountered in source";
    pub const internal_error = "internal assembler error";
};

pub fn errorMessage(err: AssemblerError) []const u8 {
    return switch (err) {
        AssemblerError.MustBeRecordFieldName => error_messages.operand_must_be_memory,
        AssemblerError.MustBeRecord => error_messages.operand_must_be_memory,
        AssemblerError.MustBeRecordOrField => error_messages.operand_must_be_memory,
        AssemblerError.MustBeStructure => error_messages.operand_must_be_memory,
        AssemblerError.MustBeStructureField => error_messages.operand_must_be_memory,
        AssemblerError.MustBeVariable => error_messages.operand_must_be_memory,
        AssemblerError.MustBeLabel => error_messages.operand_expected,
        AssemblerError.MustBeType => error_messages.operand_expected,
        AssemblerError.MustBeProc => error_messages.operand_expected,
        AssemblerError.MustBeConstant => error_messages.expression_syntax,
        AssemblerError.SymbolTooManyPublic => "too many PUBLIC symbols",
        AssemblerError.SymbolTooManyExternal => "too many EXTERN symbols",
        AssemblerError.InvalidUseOfExternal => error_messages.symbol_not_defined,
        AssemblerError.OutOfMemory => "out of memory",
        AssemblerError.StackOverflow => "out of stack space",
        AssemblerError.SourceFileNotFound => error_messages.file_not_found,
        AssemblerError.AssemblyNotComplete => "assembly not complete",
        AssemblerError.InternalError => error_messages.internal_error,
        AssemblerError.WriteFailed => "write failed",
        AssemblerError.FileNotFound => error_messages.file_not_found,
        AssemblerError.ErrorReadingFile => "error reading file",
        AssemblerError.InvalidFileFormat => "invalid file format",
        AssemblerError.InvalidCommandLine => "invalid command-line option",
        AssemblerError.InvalidArgument => "invalid argument",
        AssemblerError.MissingArgument => "missing argument",
        AssemblerError.TooManyArguments => "too many arguments",
        AssemblerError.ExpressionSyntax => error_messages.expression_syntax,
        AssemblerError.ExpressionOutOfRange => error_messages.expression_out_of_range,
        AssemblerError.OperandExpected => error_messages.operand_expected,
        AssemblerError.OperandNotAllowed => error_messages.operand_not_allowed,
        AssemblerError.OperandSizeConflict => error_messages.operand_size_conflict,
        AssemblerError.OperandMustBeRegister => error_messages.operand_must_be_register,
        AssemblerError.OperandMustBeSegment => error_messages.operand_must_be_segment,
        AssemblerError.OperandMustBeMemory => error_messages.operand_must_be_memory,
        AssemblerError.SymbolNotDefined => error_messages.symbol_not_defined,
        AssemblerError.SymbolAlreadyDefined => error_messages.symbol_already_defined,
        AssemblerError.SymbolTypeConflict => error_messages.symbol_type_conflict,
        AssemblerError.SymbolNotPublic => error_messages.symbol_not_public,
        AssemblerError.SymbolNotExternal => error_messages.symbol_not_external,
        AssemblerError.SegmentNotDefined => error_messages.segment_not_defined,
        AssemblerError.SegmentAlignmentConflict => error_messages.segment_alignment_conflict,
        AssemblerError.SegmentCombineConflict => error_messages.segment_combine_conflict,
        AssemblerError.SegmentAlreadyDefined => "segment already defined",
        AssemblerError.SegmentOffsetOverflow => "segment offset overflow",
        AssemblerError.GroupNotDefined => error_messages.group_not_defined,
        AssemblerError.GroupAlreadyDefined => "group already defined",
        AssemblerError.GroupConflict => "GROUP directive conflict",
        AssemblerError.PhaseErrorBetweenPasses => error_messages.phase_error,
        AssemblerError.InstructionNotAllowed => "instruction not allowed in current mode",
        AssemblerError.InvalidInstructionPrefix => "invalid instruction prefix",
        AssemblerError.InvalidModelDirective => "invalid model directive",
        AssemblerError.InvalidModelMemoryModel => "invalid memory model",
        AssemblerError.InvalidModelLanguage => "invalid language specifier",
        AssemblerError.InvalidModelOS => "invalid operating system",
        AssemblerError.ProcessorDirectiveConflict => error_messages.processor_directive_conflict,
        AssemblerError.CoprocessorDirectiveConflict => "coprocessor directive conflict",
        AssemblerError.EndDirectiveMissing => error_messages.end_directive_missing,
        AssemblerError.EndIfDirectiveMissing => "ENDIF directive missing",
        AssemblerError.EndmDirectiveMissing => "ENDM directive missing",
        AssemblerError.MacroNotDefined => error_messages.macro_not_defined,
        AssemblerError.MacroAlreadyDefined => error_messages.macro_already_defined,
        AssemblerError.MacroPurgingBuiltIn => "PURGE: cannot purge built-in macro",
        AssemblerError.LocalSymbolConflict => "LOCAL symbol conflict",
        AssemblerError.TooManyLocalSymbols => "too many local symbols",
        AssemblerError.ExpressionTooComplex => "expression too complex",
        AssemblerError.ValueOutOfRange => error_messages.value_out_of_range,
        AssemblerError.DivisionByZero => error_messages.division_by_zero,
        AssemblerError.IllegalForwardReference => error_messages.illegal_forward_reference,
        AssemblerError.ForwardReferenceNeedsOverride => "forward reference needs override",
        AssemblerError.RelocationNotSupported => error_messages.relocation_not_supported,
        AssemblerError.ListingNotActive => "listing not active",
        AssemblerError.AssertionFailed => error_messages.assertion_failed,
        AssemblerError.InvokedError => error_messages.invoked_error,
    };
}

pub fn isCpuEnabled(cpu: u16, feature: u16) bool {
    return (cpu & feature) == feature;
}

pub fn cpuHasFeature(cpu: u16, feature: u16) bool {
    return (cpu & feature) != 0;
}

test "version constants" {
    try std.testing.expectEqual(@as(u8, 2), VERSION_MAJOR);
    try std.testing.expectEqualStrings("2.21", VERSION_STRING);
}

test "cpu_info packing" {
    var ci = cpu_info{ ._86 = true, .pm = true, ._87 = true };
    try std.testing.expectEqual(@as(u8, 3), ci.cpuLevel());
    try std.testing.expectEqual(@as(u8, 2), ci.fpuLevel());
}

test "memory model enum" {
    try std.testing.expectEqual(@as(u8, 7), @intFromEnum(model_type.flat));
}

test "error messages exist" {
    try std.testing.expect(errorMessage(AssemblerError.PhaseErrorBetweenPasses).len > 0);
    try std.testing.expect(errorMessage(AssemblerError.SymbolNotDefined).len > 0);
}

test "error message for JWasm specific errors" {
    try std.testing.expect(errorMessage(AssemblerError.EndIfDirectiveMissing).len > 0);
}
