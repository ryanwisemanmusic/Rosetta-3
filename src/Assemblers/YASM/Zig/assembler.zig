const std = @import("std");
const yasm = @import("yasm_core.zig");
const directives = @import("directives.zig");
const encoding = @import("encoding.zig");
const listing = @import("listing.zig");
const output = @import("output.zig");
const preprocessor = @import("preprocessor.zig");
const segments = @import("segments.zig");
const symbols = @import("symbols.zig");

const Allocator = std.mem.Allocator;

pub const SourceProfileKind = enum {
    unknown,
    nasm_compatible,
    yasm_linux_elf64,
};

pub const SourceProfile = struct {
    kind: SourceProfileKind = .unknown,
    score: u32 = 0,
    has_sections: bool = false,
    has_globals: bool = false,
    has_linux_syscalls: bool = false,
    has_assignment_header: bool = false,
};

pub const AssemblySummary = struct {
    profile: SourceProfile,
    source_lines: u32 = 0,
    instruction_count: u32 = 0,
    data_directive_count: u32 = 0,
    syscall_count: u32 = 0,
    section_count: u32 = 0,
    symbol_count: u32 = 0,
};

pub const Assembler = struct {
    allocator: Allocator,
    options: yasm.CommandOptions,
    section_manager: segments.SectionManager,
    symbol_table: symbols.SymbolTable,
    pp: preprocessor.Preprocessor,
    listing_state: listing.ListingState,
    current_offset: u64 = 0,

    pub fn init(allocator: Allocator) Assembler {
        return .{
            .allocator = allocator,
            .options = yasm.CommandOptions.init(allocator),
            .section_manager = segments.SectionManager.init(allocator),
            .symbol_table = symbols.SymbolTable.init(allocator),
            .pp = preprocessor.Preprocessor.init(allocator),
            .listing_state = listing.ListingState.init(allocator),
        };
    }

    pub fn deinit(self: *Assembler) void {
        self.options.deinit();
        self.section_manager.deinit();
        self.symbol_table.deinit();
        self.pp.deinit();
        self.listing_state.deinit();
    }

    pub fn configureFromArgs(self: *Assembler, argv: []const []const u8) !void {
        self.options.deinit();
        self.options = try yasm.parseCommandLine(self.allocator, argv);
        self.section_manager.setBits(self.options.bits);
        if (self.options.listing_path) |path| self.listing_state.enable(path);
        for (self.options.include_paths.items) |path| try self.pp.addIncludePath(path);
        for (self.options.predefines.items) |define| {
            const eq = std.mem.indexOfScalar(u8, define, '=') orelse define.len;
            const name = define[0..eq];
            const value = if (eq < define.len) define[eq + 1 ..] else "1";
            try self.pp.define(name, value);
        }
    }

    pub fn setFormat(self: *Assembler, format: yasm.OutputFormat) void {
        self.options.setFormat(format);
        self.section_manager.setBits(self.options.bits);
    }

    pub fn setBits(self: *Assembler, bits: yasm.BitsMode) void {
        self.options.bits = bits;
        self.section_manager.setBits(bits);
    }

    pub fn analyzeSource(self: *Assembler, source: []const u8) !AssemblySummary {
        try self.pp.processSource(source);
        var summary = AssemblySummary{
            .profile = detectSourceProfile(source),
            .source_lines = countLines(source),
        };

        var line_number: u32 = 0;
        for (self.pp.output_lines.items) |line| {
            line_number += 1;
            try self.processLogicalLine(line, line_number, &summary);
        }

        summary.section_count = @intCast(self.section_manager.sections.items.len);
        summary.symbol_count = @intCast(self.symbol_table.count());
        return summary;
    }

    pub fn assemblePlaceholder(self: *Assembler, source: []const u8) ![]u8 {
        _ = try self.analyzeSource(source);
        return try output.emitPlaceholderObject(self.allocator, self.options.format);
    }

    pub fn validateArtifact(self: *Assembler, bytes: []const u8) bool {
        return output.validateForFormat(self.options.format, bytes);
    }

    fn processLogicalLine(self: *Assembler, line: []const u8, line_number: u32, summary: *AssemblySummary) !void {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0) return;

        var rest = trimmed;
        if (std.mem.indexOfScalar(u8, trimmed, ':')) |colon| {
            const label = std.mem.trim(u8, trimmed[0..colon], " \t");
            if (label.len > 0 and std.mem.indexOfAny(u8, label, " []") == null) {
                const current_section = self.section_manager.current_section;
                try self.symbol_table.define(label, .local, current_section, @intCast(self.current_offset), 0);
                rest = std.mem.trim(u8, trimmed[colon + 1 ..], " \t");
                if (rest.len == 0) return;
            }
        }

        const token = directives.firstToken(rest);
        if (token.len == 0) return;
        const after_token = std.mem.trim(u8, rest[token.len..], " \t");

        if (isSymbolName(token) and after_token.len > 0) {
            const next_token = directives.firstToken(after_token);
            const after_next = std.mem.trim(u8, after_token[next_token.len..], " \t");
            if (std.ascii.eqlIgnoreCase(next_token, "equ")) {
                try self.symbol_table.define(token, .equ, null, parseInt(i64, after_next) catch 0, 0);
                return;
            }
            if (directives.DataDirective.fromString(next_token)) |data_directive| {
                const current_section = self.section_manager.current_section orelse try self.section_manager.ensureText();
                try self.symbol_table.define(token, .local, current_section, @intCast(self.current_offset), 0);
                try self.recordDataDirective(data_directive, after_next, line_number, rest, summary);
                return;
            }
        }

        if (directives.Directive.fromString(token)) |directive| {
            try self.handleDirective(directive, after_token);
            return;
        }

        if (directives.DataDirective.fromString(token)) |data_directive| {
            try self.recordDataDirective(data_directive, after_token, line_number, rest, summary);
            return;
        }

        const inst = try encoding.summarize(rest, self.allocator);
        summary.instruction_count += 1;
        if (inst.class == .system and std.ascii.eqlIgnoreCase(inst.mnemonic, "syscall")) summary.syscall_count += 1;
        const size = encoding.placeholderLength(inst);
        self.current_offset += size;
        try self.listing_state.addLine(line_number, self.current_offset, size, rest);
    }

    fn handleDirective(self: *Assembler, directive: directives.Directive, operands_text: []const u8) !void {
        switch (directive) {
            .bits => {
                const bits = parseInt(u8, operands_text) catch 0;
                if (yasm.BitsMode.fromInt(bits)) |mode| self.setBits(mode);
            },
            .section, .segment => {
                const name = directives.firstToken(operands_text);
                if (name.len > 0) _ = try self.section_manager.beginSection(name, segments.sectionFlagsForName(name), 16);
            },
            .global => {
                var it = std.mem.splitScalar(u8, operands_text, ',');
                while (it.next()) |item| {
                    const name = std.mem.trim(u8, item, " \t");
                    if (name.len > 0) try self.symbol_table.markGlobal(name);
                }
            },
            .@"extern" => {
                var it = std.mem.splitScalar(u8, operands_text, ',');
                while (it.next()) |item| {
                    const name = std.mem.trim(u8, item, " \t");
                    if (name.len > 0) try self.symbol_table.declareExtern(name);
                }
            },
            else => {},
        }
    }

    fn recordDataDirective(self: *Assembler, data_directive: directives.DataDirective, operands_text: []const u8, line_number: u32, source_line: []const u8, summary: *AssemblySummary) !void {
        summary.data_directive_count += 1;
        const byte_count = estimateDataBytes(data_directive, operands_text);
        const section_idx = self.section_manager.current_section orelse try self.section_manager.ensureText();
        self.section_manager.sections.items[section_idx].offset += byte_count;
        self.section_manager.sections.items[section_idx].size += byte_count;
        self.current_offset += byte_count;
        try self.listing_state.addLine(line_number, self.current_offset, @intCast(byte_count), source_line);
    }
};

pub fn detectSourceProfile(source: []const u8) SourceProfile {
    var profile = SourceProfile{};
    profile.has_sections = containsIgnoreCase(source, "section .text") or
        containsIgnoreCase(source, "section\t.text") or
        containsIgnoreCase(source, "section .data") or
        containsIgnoreCase(source, "section\t.data");
    profile.has_globals = containsIgnoreCase(source, "global _start") or
        containsIgnoreCase(source, "global checkParams") or
        containsIgnoreCase(source, "global getWord");
    profile.has_linux_syscalls = containsIgnoreCase(source, "syscall") or
        containsIgnoreCase(source, "SYS_exit") or
        containsIgnoreCase(source, "SYS_read") or
        containsIgnoreCase(source, "SYS_write");
    profile.has_assignment_header = containsIgnoreCase(source, "Assignment:") or
        containsIgnoreCase(source, "Assignment #");

    if (profile.has_sections) profile.score += 2;
    if (profile.has_globals) profile.score += 2;
    if (profile.has_linux_syscalls) profile.score += 2;
    if (profile.has_assignment_header) profile.score += 2;

    profile.kind = if (profile.score >= 5 and profile.has_linux_syscalls)
        .yasm_linux_elf64
    else if (profile.has_sections or profile.has_globals)
        .nasm_compatible
    else
        .unknown;
    return profile;
}

fn estimateDataBytes(directive: directives.DataDirective, operands_text: []const u8) u64 {
    const trimmed = std.mem.trim(u8, operands_text, " \t");
    if (trimmed.len == 0) return 0;
    if (directive.reservesSpace()) {
        const count = parseInt(u64, trimmed) catch 1;
        return count * directive.byteSize();
    }
    var count: u64 = 1;
    for (trimmed) |ch| {
        if (ch == ',') count += 1;
    }
    return count * directive.byteSize();
}

fn parseInt(comptime T: type, text: []const u8) !T {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return error.InvalidCharacter;
    if (std.mem.startsWith(u8, trimmed, "0x") or std.mem.startsWith(u8, trimmed, "0X")) {
        return try std.fmt.parseInt(T, trimmed[2..], 16);
    }
    return try std.fmt.parseInt(T, trimmed, 10);
}

fn isSymbolName(text: []const u8) bool {
    if (text.len == 0) return false;
    if (std.ascii.isDigit(text[0])) return false;
    for (text) |ch| {
        if (std.ascii.isAlphanumeric(ch) or ch == '_' or ch == '.' or ch == '$' or ch == '@') continue;
        return false;
    }
    return true;
}

fn countLines(source: []const u8) u32 {
    if (source.len == 0) return 0;
    var count: u32 = 1;
    for (source) |ch| {
        if (ch == '\n') count += 1;
    }
    return count;
}

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    return std.ascii.indexOfIgnoreCase(haystack, needle) != null;
}

test "detect assignment-style YASM profile" {
    const sample =
        \\; Assignment: 1
        \\section .text
        \\global _start
        \\_start:
        \\  mov rax, SYS_exit
        \\  syscall
    ;
    const profile = detectSourceProfile(sample);
    try std.testing.expectEqual(SourceProfileKind.yasm_linux_elf64, profile.kind);
}

test "analyze yasm source" {
    var assembler = Assembler.init(std.testing.allocator);
    defer assembler.deinit();
    assembler.setFormat(.elf64);
    const summary = try assembler.analyzeSource(
        \\section .data
        \\value dq 1
        \\SYS_exit equ 60
        \\section .text
        \\global _start
        \\_start:
        \\  syscall
    );
    try std.testing.expectEqual(@as(u32, 2), summary.section_count);
    try std.testing.expectEqual(@as(u32, 1), summary.data_directive_count);
    try std.testing.expectEqual(@as(u32, 1), summary.syscall_count);
    try std.testing.expect(assembler.symbol_table.lookup("_start") != null);
    try std.testing.expect(assembler.symbol_table.lookup("value") != null);
    try std.testing.expect(assembler.symbol_table.lookup("SYS_exit") != null);
}

test "configure from YASM ELF64 command line" {
    var assembler = Assembler.init(std.testing.allocator);
    defer assembler.deinit();
    const argv = [_][]const u8{ "-g", "dwarf2", "-f", "elf64", "ast01.asm", "-l", "ast01.lst" };
    try assembler.configureFromArgs(&argv);
    try std.testing.expectEqual(yasm.OutputFormat.elf64, assembler.options.format);
    try std.testing.expect(assembler.listing_state.enabled);
}
