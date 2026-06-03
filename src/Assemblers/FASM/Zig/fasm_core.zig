const std = @import("std");
const builtin = @import("builtin");

pub const VERSION_STRING: []const u8 = "1.73.35";
pub const VERSION_MAJOR: u32 = 1;
pub const VERSION_MINOR: u32 = 73;
pub const VERSION_PATCH: u32 = 35;

pub const MAX_PASSES: u32 = 65536;
pub const DEFAULT_CODE_TYPE: u8 = 16;
pub const LABEL_STRUCTURE_SIZE: u32 = 32;
pub const MAX_SYMBOL_NAME: u32 = 256;
pub const MAX_LINE_LENGTH: u32 = 4096;
pub const STACK_CHECK_THRESHOLD: u32 = 0x100;
pub const DUMP_HEADER_SIZE: u32 = 0x40;

pub const OutputFormat = enum(u8) {
    flat_binary = 0,
    mz_executable = 1,
    pe_executable = 2,
    coff_object = 3,
    elf_object = 4,
    elf_executable = 5,
    _,
};

pub const CodeType = enum(u8) {
    unknown = 0,
    code_16 = 16,
    code_32 = 32,
    code_64 = 64,
};

pub const SymbolFlags = packed struct(u32) {
    defined: bool = false,
    forward_ref: bool = false,
    relocatable: bool = false,
    _pad0: u1 = 0,
    label_only: bool = false,
    defined_this_pass: bool = false,
    _pad1: u1 = 0,
    used: bool = false,
    predefined: bool = false,
    import: bool = false,
    _pad2: u1 = 0,
    forward_used: bool = false,
    forward_defined: bool = false,
    _pad3: u19 = 0,

    comptime {
        std.debug.assert(@sizeOf(@This()) == 4);
    }
};

pub const Symbol = struct {
    value_low: u32 = 0,
    value_high: u32 = 0,
    flags: SymbolFlags = .{},
    _reserved: u8 = 0,
    pass_defined: u16 = 0,
    pass_used: u16 = 0,
    base_symbol: u32 = 0,
    name_offset: u32 = 0,
    line_number: u32 = 0,

    comptime {
        std.debug.assert(@sizeOf(@This()) == LABEL_STRUCTURE_SIZE);
    }
};

pub const PreprocessedLine = struct {
    file_ref: u32 = 0,
    line_number: u32 = 0,
    data_offset: u32 = 0,
    _flags: u32 = 0,
};

pub const ValueType = enum(u8) {
    undefined = 0,
    constant = 1,
    expression = 2,
    _,
};

pub const FormatFlags = packed struct(u32) {
    pe_gui: bool = false,
    pe_dll: bool = false,
    pe_relocs_stripped: bool = false,
    elf_executable: bool = false,
    _pad: u28 = 0,
};

pub const ResolverFlags = packed struct(u32) {
    compressed_displacement: bool = false,
    _pad: u31 = 0,
};

pub const OperandFlags = packed struct(u8) {
    size_override: bool = false,
    address_override: bool = false,
    lock_prefix: bool = false,
    rep_prefix: bool = false,
    repne_prefix: bool = false,
    _pad: u3 = 0,
};

pub const error_messages = struct {
    pub const out_of_memory = "out of memory";
    pub const stack_overflow = "out of stack space";
    pub const main_file_not_found = "source file not found";
    pub const code_cannot_be_generated = "code cannot be generated";
    pub const format_limitations_exceeded = "format limitations exceeded";
    pub const invalid_definition = "invalid definition provided";
    pub const write_failed = "write failed";
    pub const file_not_found = "file not found";
    pub const error_reading_file = "error reading file";
    pub const invalid_file_format = "invalid file format";
    pub const invalid_macro_arguments = "invalid macro arguments";
    pub const incomplete_macro = "incomplete macro";
    pub const unexpected_characters = "unexpected characters";
    pub const invalid_argument = "invalid argument";
    pub const illegal_instruction = "illegal instruction";
    pub const invalid_operand = "invalid operand";
    pub const operand_size_not_specified = "operand size not specified";
    pub const operand_sizes_do_not_match = "operand sizes do not match";
    pub const invalid_address_size = "invalid size of address value";
    pub const address_sizes_do_not_agree = "address sizes do not agree";
    pub const disallowed_combination_of_registers = "disallowed combination of registers";
    pub const long_immediate_not_encodable = "not encodable with long immediate";
    pub const relative_jump_out_of_range = "relative jump out of range";
    pub const invalid_expression = "invalid expression";
    pub const invalid_address = "invalid address";
    pub const invalid_value = "invalid value";
    pub const value_out_of_range = "value out of range";
    pub const undefined_symbol = "undefined symbol";
    pub const symbol_out_of_scope = "symbol out of scope";
    pub const invalid_use_of_symbol = "invalid use of symbol";
    pub const name_too_long = "name too long";
    pub const invalid_name = "invalid name";
    pub const reserved_word_used_as_symbol = "reserved word used as symbol";
    pub const symbol_already_defined = "symbol already defined";
    pub const missing_end_quote = "missing end quote";
    pub const missing_end_directive = "missing end directive";
    pub const unexpected_instruction = "unexpected instruction";
    pub const extra_characters_on_line = "extra characters on line";
    pub const section_not_aligned_enough = "section is not aligned enough";
    pub const setting_already_specified = "setting already specified";
    pub const data_already_defined = "data already defined";
    pub const too_many_repeats = "too many repeats";
    pub const assertion_failed = "assertion failed";
    pub const invoked_error = "error directive encountered in source file";
};

pub fn archName() []const u8 {
    return switch (builtin.target.cpu.arch) {
        .aarch64 => "ARM64",
        .x86_64 => "x86_64",
        else => "unknown",
    };
}

test "FASM version constants" {
    try std.testing.expectEqualStrings("1.73.35", VERSION_STRING);
    try std.testing.expectEqual(@as(u32, 1), VERSION_MAJOR);
}

test "Symbol struct size" {
    try std.testing.expectEqual(@as(usize, LABEL_STRUCTURE_SIZE), @sizeOf(Symbol));
}

test "archName returns current arch" {
    const name = archName();
    try std.testing.expect(name.len > 0);
}
