const std = @import("std");
const fasm = @import("fasm_core.zig");

pub const AssemblerError = error{
    OutOfMemory,
    StackOverflow,
    SourceFileNotFound,
    CodeCannotBeGenerated,
    FormatLimitationsExceeded,
    InvalidDefinition,
    WriteFailed,
    FileNotFound,
    ErrorReadingFile,
    InvalidFileFormat,
    InvalidMacroArguments,
    IncompleteMacro,
    UnexpectedCharacters,
    InvalidArgument,
    IllegalInstruction,
    InvalidOperand,
    OperandSizeNotSpecified,
    OperandSizesDoNotMatch,
    InvalidAddressValue,
    AddressSizesDoNotAgree,
    DisallowedCombinationOfRegisters,
    LongImmediateNotEncodable,
    RelativeJumpOutOfRange,
    InvalidExpression,
    InvalidAddress,
    InvalidValue,
    ValueOutOfRange,
    UndefinedSymbol,
    SymbolOutOfScope,
    InvalidUseOfSymbol,
    NameTooLong,
    InvalidName,
    ReservedWordUsedAsSymbol,
    SymbolAlreadyDefined,
    MissingEndQuote,
    MissingEndDirective,
    UnexpectedInstruction,
    ExtraCharactersOnLine,
    SectionNotAlignedEnough,
    SettingAlreadySpecified,
    DataAlreadyDefined,
    TooManyRepeats,
    AssertionFailed,
    InvokedError,
};

pub const AssemblerErrorInfo = struct {
    code: AssemblerError,
    line_number: u32 = 0,
    pass: u32 = 0,
    token_offset: u32 = 0,

    pub fn message(self: *const AssemblerErrorInfo) []const u8 {
        return switch (self.code) {
            AssemblerError.OutOfMemory => fasm.error_messages.out_of_memory,
            AssemblerError.StackOverflow => fasm.error_messages.stack_overflow,
            AssemblerError.SourceFileNotFound => fasm.error_messages.main_file_not_found,
            AssemblerError.CodeCannotBeGenerated => fasm.error_messages.code_cannot_be_generated,
            AssemblerError.FormatLimitationsExceeded => fasm.error_messages.format_limitations_exceeded,
            AssemblerError.InvalidDefinition => fasm.error_messages.invalid_definition,
            AssemblerError.WriteFailed => fasm.error_messages.write_failed,
            AssemblerError.FileNotFound => fasm.error_messages.file_not_found,
            AssemblerError.ErrorReadingFile => fasm.error_messages.error_reading_file,
            AssemblerError.InvalidFileFormat => fasm.error_messages.invalid_file_format,
            AssemblerError.InvalidMacroArguments => fasm.error_messages.invalid_macro_arguments,
            AssemblerError.IncompleteMacro => fasm.error_messages.incomplete_macro,
            AssemblerError.UnexpectedCharacters => fasm.error_messages.unexpected_characters,
            AssemblerError.InvalidArgument => fasm.error_messages.invalid_argument,
            AssemblerError.IllegalInstruction => fasm.error_messages.illegal_instruction,
            AssemblerError.InvalidOperand => fasm.error_messages.invalid_operand,
            AssemblerError.OperandSizeNotSpecified => fasm.error_messages.operand_size_not_specified,
            AssemblerError.OperandSizesDoNotMatch => fasm.error_messages.operand_sizes_do_not_match,
            AssemblerError.InvalidAddressValue => fasm.error_messages.invalid_address_size,
            AssemblerError.AddressSizesDoNotAgree => fasm.error_messages.address_sizes_do_not_agree,
            AssemblerError.DisallowedCombinationOfRegisters => fasm.error_messages.disallowed_combination_of_registers,
            AssemblerError.LongImmediateNotEncodable => fasm.error_messages.long_immediate_not_encodable,
            AssemblerError.RelativeJumpOutOfRange => fasm.error_messages.relative_jump_out_of_range,
            AssemblerError.InvalidExpression => fasm.error_messages.invalid_expression,
            AssemblerError.InvalidAddress => fasm.error_messages.invalid_address,
            AssemblerError.InvalidValue => fasm.error_messages.invalid_value,
            AssemblerError.ValueOutOfRange => fasm.error_messages.value_out_of_range,
            AssemblerError.UndefinedSymbol => fasm.error_messages.undefined_symbol,
            AssemblerError.SymbolOutOfScope => fasm.error_messages.symbol_out_of_scope,
            AssemblerError.InvalidUseOfSymbol => fasm.error_messages.invalid_use_of_symbol,
            AssemblerError.NameTooLong => fasm.error_messages.name_too_long,
            AssemblerError.InvalidName => fasm.error_messages.invalid_name,
            AssemblerError.ReservedWordUsedAsSymbol => fasm.error_messages.reserved_word_used_as_symbol,
            AssemblerError.SymbolAlreadyDefined => fasm.error_messages.symbol_already_defined,
            AssemblerError.MissingEndQuote => fasm.error_messages.missing_end_quote,
            AssemblerError.MissingEndDirective => fasm.error_messages.missing_end_directive,
            AssemblerError.UnexpectedInstruction => fasm.error_messages.unexpected_instruction,
            AssemblerError.ExtraCharactersOnLine => fasm.error_messages.extra_characters_on_line,
            AssemblerError.SectionNotAlignedEnough => fasm.error_messages.section_not_aligned_enough,
            AssemblerError.SettingAlreadySpecified => fasm.error_messages.setting_already_specified,
            AssemblerError.DataAlreadyDefined => fasm.error_messages.data_already_defined,
            AssemblerError.TooManyRepeats => fasm.error_messages.too_many_repeats,
            AssemblerError.AssertionFailed => fasm.error_messages.assertion_failed,
            AssemblerError.InvokedError => fasm.error_messages.invoked_error,
        };
    }
};

pub fn formatError(err: AssemblerError) AssemblerErrorInfo {
    return AssemblerErrorInfo{ .code = err };
}

test "error message mapping" {
    const info = formatError(AssemblerError.OutOfMemory);
    try std.testing.expectEqualStrings("out of memory", info.message());
}

test "all error codes have messages" {
    const codes = [_]AssemblerError{
        AssemblerError.OutOfMemory,
        AssemblerError.StackOverflow,
        AssemblerError.SourceFileNotFound,
        AssemblerError.CodeCannotBeGenerated,
        AssemblerError.InvalidExpression,
        AssemblerError.UndefinedSymbol,
    };
    for (codes) |code| {
        const info = formatError(code);
        try std.testing.expect(info.message().len > 0);
    }
}
