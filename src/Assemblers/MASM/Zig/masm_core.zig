const std = @import("std");
const builtin = @import("builtin");

pub const VERSION_MAJOR: u8 = 6;
pub const VERSION_MINOR: u8 = 11;
pub const VERSION_PATCH: u8 = 0;
pub const VERSION_STRING: []const u8 = "6.11";

pub const MAX_PASSES: u32 = 16;
pub const MAX_SEGMENTS: u32 = 256;
pub const MAX_GROUPS: u32 = 32;
pub const MAX_NESTING: u32 = 32;
pub const MAX_MACRO_NESTING: u32 = 16;
pub const MAX_REPEAT_NESTING: u32 = 16;
pub const MAX_LINE_LENGTH: u32 = 4096;
pub const MAX_IDENT_LENGTH: u32 = 256;

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

pub const MemoryModel = enum(u8) {
    tiny = 0,
    small = 1,
    medium = 2,
    compact = 3,
    large = 4,
    huge = 5,
    flat = 6,
    _,
};

pub const ModelLanguage = enum(u8) {
    none = 0,
    c = 1,
    syscall = 2,
    stdcall = 3,
    pascal = 4,
    fortran = 5,
    basic = 6,
    _,
};

pub const ModelFlags = packed struct(u16) {
    language: ModelLanguage = .none,
    memory_model: MemoryModel = .small,
    _pad: u4 = 0,
    os_dos: bool = false,
    os_os2: bool = false,
    os_windows: bool = false,
    _pad2: u4 = 0,
};

pub const OutputFormat = enum(u8) {
    omf = 0,
    coff = 1,
    _,
};

pub const ProcessorLevel = packed struct(u8) {
    @"8086": bool = true,
    @"186": bool = false,
    @"286": bool = false,
    @"386": bool = false,
    @"486": bool = false,
    @"586": bool = false,
    @"686": bool = false,
    _pad: u1 = 0,
};

pub const SymbolType = enum(u8) {
    undefined = 0,
    constant = 1,
    variable = 2,
    label = 3,
    proc = 4,
    macro = 5,
    text_macro = 6,
    segment = 7,
    group = 8,
    structure = 9,
    record = 10,
    type = 11,
    equate = 12,
    number = 13,
    _,
};

pub const SegmentCombine = enum(u8) {
    private = 0,
    public = 1,
    stack = 2,
    common = 3,
    memory = 4,
    at = 5,
    _,
};

pub const SegmentAlign = enum(u8) {
    byte = 0,
    word = 1,
    dword = 2,
    para = 3,
    page = 4,
    _,
};

pub const ScopeType = enum(u8) {
    global = 0,
    local = 1,
    proc_private = 2,
    _,
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
    pub const phase_error_between_passes = "phase error between passes - use /Zm for MASM 5.1 compatibility";
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
        AssemblerError.PhaseErrorBetweenPasses => error_messages.phase_error_between_passes,
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

test "version constants" {
    try std.testing.expectEqual(@as(u8, 6), VERSION_MAJOR);
    try std.testing.expectEqualStrings("6.11", VERSION_STRING);
}

test "memory model enum" {
    try std.testing.expectEqual(@as(u8, 6), @intFromEnum(MemoryModel.flat));
}

test "error messages exist" {
    try std.testing.expect(errorMessage(AssemblerError.PhaseErrorBetweenPasses).len > 0);
    try std.testing.expect(errorMessage(AssemblerError.SymbolNotDefined).len > 0);
}
