const std = @import("std");

pub const yasm_version = "1.3.0";
pub const default_arch_name = "x86";
pub const default_parser_name = "nasm";
pub const default_preproc_name = "nasm";

pub const YasmError = error{
    InvalidOption,
    MissingOptionValue,
    MissingInput,
    MultipleInputs,
    UnsupportedArchitecture,
    UnsupportedMachine,
    UnsupportedFormat,
    UnsupportedDebugFormat,
    UnsupportedParser,
    UnsupportedPreprocessor,
};

pub const OutputFormat = enum {
    bin,
    coff,
    dbg,
    elf32,
    elf64,
    elfx32,
    macho32,
    macho64,
    rdf,
    win32,
    win64,
    xdf,

    pub fn fromString(name: []const u8) ?OutputFormat {
        if (std.ascii.eqlIgnoreCase(name, "elf")) return .elf32;
        if (std.ascii.eqlIgnoreCase(name, "macho")) return .macho32;
        inline for (std.meta.fields(OutputFormat)) |field| {
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(OutputFormat, field.name);
        }
        return null;
    }

    pub fn defaultBits(self: OutputFormat) BitsMode {
        return switch (self) {
            .bin, .coff, .dbg, .elf32, .macho32, .rdf, .win32, .xdf => .bits_32,
            .elf64, .macho64, .win64 => .bits_64,
            .elfx32 => .bits_32,
        };
    }

    pub fn defaultExtension(self: OutputFormat) []const u8 {
        return switch (self) {
            .bin => "",
            .win32, .win64 => ".obj",
            else => ".o",
        };
    }

    pub fn isRelocatableObject(self: OutputFormat) bool {
        return switch (self) {
            .bin, .dbg => false,
            else => true,
        };
    }
};

pub const DebugFormat = enum {
    default,
    null,
    dwarf2,
    stabs,
    cv8,

    pub fn fromString(name: []const u8) ?DebugFormat {
        if (std.ascii.eqlIgnoreCase(name, "none")) return .null;
        inline for (std.meta.fields(DebugFormat)) |field| {
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(DebugFormat, field.name);
        }
        return null;
    }
};

pub const ListFormat = enum {
    nasm,
    null,

    pub fn fromString(name: []const u8) ?ListFormat {
        inline for (std.meta.fields(ListFormat)) |field| {
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(ListFormat, field.name);
        }
        return null;
    }
};

pub const Parser = enum {
    nasm,
    gas,
    tasm,

    pub fn fromString(name: []const u8) ?Parser {
        inline for (std.meta.fields(Parser)) |field| {
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(Parser, field.name);
        }
        return null;
    }
};

pub const Preprocessor = enum {
    nasm,
    raw,

    pub fn fromString(name: []const u8) ?Preprocessor {
        inline for (std.meta.fields(Preprocessor)) |field| {
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(Preprocessor, field.name);
        }
        return null;
    }
};

pub const Architecture = enum {
    x86,

    pub fn fromString(name: []const u8) ?Architecture {
        if (std.ascii.eqlIgnoreCase(name, "amd64")) return .x86;
        if (std.ascii.eqlIgnoreCase(name, "x86_64")) return .x86;
        if (std.ascii.eqlIgnoreCase(name, "x64")) return .x86;
        if (std.ascii.eqlIgnoreCase(name, "i386")) return .x86;
        if (std.ascii.eqlIgnoreCase(name, "x86")) return .x86;
        return null;
    }
};

pub const Machine = enum {
    x86,
    amd64,

    pub fn fromString(name: []const u8) ?Machine {
        if (std.ascii.eqlIgnoreCase(name, "x86")) return .x86;
        if (std.ascii.eqlIgnoreCase(name, "i386")) return .x86;
        if (std.ascii.eqlIgnoreCase(name, "amd64")) return .amd64;
        if (std.ascii.eqlIgnoreCase(name, "x86_64")) return .amd64;
        if (std.ascii.eqlIgnoreCase(name, "x64")) return .amd64;
        return null;
    }

    pub fn bits(self: Machine) BitsMode {
        return switch (self) {
            .x86 => .bits_32,
            .amd64 => .bits_64,
        };
    }
};

pub const BitsMode = enum(u8) {
    bits_16 = 16,
    bits_32 = 32,
    bits_64 = 64,

    pub fn fromInt(bits: u8) ?BitsMode {
        return switch (bits) {
            16 => .bits_16,
            32 => .bits_32,
            64 => .bits_64,
            else => null,
        };
    }
};

pub const CommandOptions = struct {
    allocator: std.mem.Allocator,
    arch: Architecture = .x86,
    machine: ?Machine = null,
    parser: Parser = .nasm,
    preprocessor: Preprocessor = .nasm,
    format: OutputFormat = .bin,
    debug_format: DebugFormat = .default,
    list_format: ListFormat = .nasm,
    bits: BitsMode = .bits_32,
    source_path: ?[]const u8 = null,
    output_path: ?[]const u8 = null,
    listing_path: ?[]const u8 = null,
    include_paths: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    predefines: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 },
    warnings_as_errors: bool = false,
    emit_debug_symbols: bool = false,

    pub fn init(allocator: std.mem.Allocator) CommandOptions {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *CommandOptions) void {
        if (self.source_path) |path| self.allocator.free(path);
        if (self.output_path) |path| self.allocator.free(path);
        if (self.listing_path) |path| self.allocator.free(path);
        for (self.include_paths.items) |path| self.allocator.free(path);
        self.include_paths.deinit(self.allocator);
        for (self.predefines.items) |define| self.allocator.free(define);
        self.predefines.deinit(self.allocator);
    }

    pub fn setFormat(self: *CommandOptions, format: OutputFormat) void {
        self.format = format;
        self.bits = if (self.machine) |machine| machine.bits() else format.defaultBits();
    }

    pub fn setMachine(self: *CommandOptions, machine: Machine) void {
        self.machine = machine;
        self.bits = machine.bits();
    }

    pub fn ensureOutputPath(self: *CommandOptions) !void {
        if (self.output_path != null) return;
        const source = self.source_path orelse return YasmError.MissingInput;
        self.output_path = try deriveOutputPath(self.allocator, source, self.format);
    }
};

pub fn parseCommandLine(allocator: std.mem.Allocator, argv: []const []const u8) !CommandOptions {
    var options = CommandOptions.init(allocator);
    errdefer options.deinit();

    var i: usize = 0;
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];
        if (arg.len == 0) continue;
        if (std.mem.eql(u8, arg, "--")) {
            i += 1;
            while (i < argv.len) : (i += 1) try setInput(&options, argv[i]);
            break;
        }

        if (!std.mem.startsWith(u8, arg, "-") or std.mem.eql(u8, arg, "-")) {
            try setInput(&options, arg);
            continue;
        }

        if (std.mem.startsWith(u8, arg, "--")) {
            try parseLongOption(&options, argv, &i, arg[2..]);
            continue;
        }

        try parseShortOption(&options, argv, &i, arg);
    }

    if (options.source_path == null) return YasmError.MissingInput;
    try options.ensureOutputPath();
    return options;
}

fn parseShortOption(options: *CommandOptions, argv: []const []const u8, i: *usize, arg: []const u8) !void {
    if (arg.len < 2) return YasmError.InvalidOption;
    const opt = arg[1];
    const value = if (arg.len > 2) arg[2..] else try nextValue(argv, i);

    switch (opt) {
        'a' => options.arch = Architecture.fromString(value) orelse return YasmError.UnsupportedArchitecture,
        'f' => options.setFormat(OutputFormat.fromString(value) orelse return YasmError.UnsupportedFormat),
        'g' => {
            options.debug_format = DebugFormat.fromString(value) orelse return YasmError.UnsupportedDebugFormat;
            options.emit_debug_symbols = options.debug_format != .null;
        },
        'L' => options.list_format = ListFormat.fromString(value) orelse return YasmError.InvalidOption,
        'l' => try replaceOwned(&options.listing_path, options.allocator, value),
        'm' => options.setMachine(Machine.fromString(value) orelse return YasmError.UnsupportedMachine),
        'o' => try replaceOwned(&options.output_path, options.allocator, value),
        'p' => options.parser = Parser.fromString(value) orelse return YasmError.UnsupportedParser,
        'r' => options.preprocessor = Preprocessor.fromString(value) orelse return YasmError.UnsupportedPreprocessor,
        'D' => try options.predefines.append(options.allocator, try options.allocator.dupe(u8, value)),
        'I' => try options.include_paths.append(options.allocator, try options.allocator.dupe(u8, value)),
        'W' => {
            if (std.ascii.eqlIgnoreCase(value, "error")) options.warnings_as_errors = true;
        },
        else => return YasmError.InvalidOption,
    }
}

fn parseLongOption(options: *CommandOptions, argv: []const []const u8, i: *usize, arg: []const u8) !void {
    const eq = std.mem.indexOfScalar(u8, arg, '=');
    const name = if (eq) |pos| arg[0..pos] else arg;
    const inline_value = if (eq) |pos| arg[pos + 1 ..] else null;

    if (std.ascii.eqlIgnoreCase(name, "version") or std.ascii.eqlIgnoreCase(name, "help")) return;

    if (std.ascii.eqlIgnoreCase(name, "arch")) {
        const value = inline_value orelse try nextValue(argv, i);
        options.arch = Architecture.fromString(value) orelse return YasmError.UnsupportedArchitecture;
    } else if (std.ascii.eqlIgnoreCase(name, "oformat")) {
        const value = inline_value orelse try nextValue(argv, i);
        options.setFormat(OutputFormat.fromString(value) orelse return YasmError.UnsupportedFormat);
    } else if (std.ascii.eqlIgnoreCase(name, "dformat")) {
        const value = inline_value orelse try nextValue(argv, i);
        options.debug_format = DebugFormat.fromString(value) orelse return YasmError.UnsupportedDebugFormat;
        options.emit_debug_symbols = options.debug_format != .null;
    } else if (std.ascii.eqlIgnoreCase(name, "lformat")) {
        const value = inline_value orelse try nextValue(argv, i);
        options.list_format = ListFormat.fromString(value) orelse return YasmError.InvalidOption;
    } else if (std.ascii.eqlIgnoreCase(name, "list")) {
        const value = inline_value orelse try nextValue(argv, i);
        try replaceOwned(&options.listing_path, options.allocator, value);
    } else if (std.ascii.eqlIgnoreCase(name, "machine")) {
        const value = inline_value orelse try nextValue(argv, i);
        options.setMachine(Machine.fromString(value) orelse return YasmError.UnsupportedMachine);
    } else if (std.ascii.eqlIgnoreCase(name, "objfile")) {
        const value = inline_value orelse try nextValue(argv, i);
        try replaceOwned(&options.output_path, options.allocator, value);
    } else if (std.ascii.eqlIgnoreCase(name, "parser")) {
        const value = inline_value orelse try nextValue(argv, i);
        options.parser = Parser.fromString(value) orelse return YasmError.UnsupportedParser;
    } else if (std.ascii.eqlIgnoreCase(name, "preproc")) {
        const value = inline_value orelse try nextValue(argv, i);
        options.preprocessor = Preprocessor.fromString(value) orelse return YasmError.UnsupportedPreprocessor;
    } else {
        return YasmError.InvalidOption;
    }
}

fn nextValue(argv: []const []const u8, i: *usize) ![]const u8 {
    if (i.* + 1 >= argv.len) return YasmError.MissingOptionValue;
    i.* += 1;
    return argv[i.*];
}

fn setInput(options: *CommandOptions, path: []const u8) !void {
    if (options.source_path != null) return YasmError.MultipleInputs;
    options.source_path = try options.allocator.dupe(u8, path);
}

fn replaceOwned(slot: *?[]const u8, allocator: std.mem.Allocator, value: []const u8) !void {
    if (slot.*) |old| allocator.free(old);
    slot.* = try allocator.dupe(u8, value);
}

pub fn deriveOutputPath(allocator: std.mem.Allocator, input: []const u8, format: OutputFormat) ![]const u8 {
    if (std.mem.eql(u8, input, "-")) return try allocator.dupe(u8, "yasm.out");

    const ext = format.defaultExtension();
    const slash = lastPathSeparator(input);
    const basename_start = if (slash) |idx| idx + 1 else 0;
    const basename = input[basename_start..];
    if (basename.len == 0) return try allocator.dupe(u8, "yasm.out");

    const dot_rel = lastDotAfterSeparator(basename);
    const stem_end = if (dot_rel) |idx| basename_start + idx else input.len;

    if (format == .bin) {
        if (dot_rel == null) return try allocator.dupe(u8, input);
        return try allocator.dupe(u8, input[0..stem_end]);
    }

    return try std.mem.concat(allocator, u8, &.{ input[0..stem_end], ext });
}

fn lastPathSeparator(path: []const u8) ?usize {
    var i = path.len;
    while (i > 0) {
        i -= 1;
        if (path[i] == '/' or path[i] == '\\') return i;
    }
    return null;
}

fn lastDotAfterSeparator(basename: []const u8) ?usize {
    var i = basename.len;
    while (i > 0) {
        i -= 1;
        if (basename[i] == '.') return i;
    }
    return null;
}

test "parse YASM ELF64 command" {
    const argv = [_][]const u8{ "-g", "dwarf2", "-f", "elf64", "ast01.asm", "-l", "ast01.lst" };
    var options = try parseCommandLine(std.testing.allocator, &argv);
    defer options.deinit();

    try std.testing.expectEqual(OutputFormat.elf64, options.format);
    try std.testing.expectEqual(DebugFormat.dwarf2, options.debug_format);
    try std.testing.expectEqual(BitsMode.bits_64, options.bits);
    try std.testing.expectEqualStrings("ast01.asm", options.source_path.?);
    try std.testing.expectEqualStrings("ast01.o", options.output_path.?);
    try std.testing.expectEqualStrings("ast01.lst", options.listing_path.?);
}

test "parse compact short options" {
    const argv = [_][]const u8{ "-felf64", "-gdwarf2", "-o", "out.o", "main.asm" };
    var options = try parseCommandLine(std.testing.allocator, &argv);
    defer options.deinit();

    try std.testing.expectEqual(OutputFormat.elf64, options.format);
    try std.testing.expectEqual(DebugFormat.dwarf2, options.debug_format);
    try std.testing.expectEqualStrings("out.o", options.output_path.?);
}

test "derive raw binary output path removes extension" {
    const path = try deriveOutputPath(std.testing.allocator, "boot/loader.asm", .bin);
    defer std.testing.allocator.free(path);
    try std.testing.expectEqualStrings("boot/loader", path);
}
