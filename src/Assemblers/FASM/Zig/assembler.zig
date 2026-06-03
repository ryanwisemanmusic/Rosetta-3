const std = @import("std");
const fasm = @import("fasm_core.zig");
const memory = @import("memory.zig");
const errors = @import("errors.zig");
const symbols = @import("symbols.zig");
const tables = @import("tables.zig");
const expr_calc = @import("expr_calc.zig");
const preprocessor = @import("preprocessor.zig");
const parser_mod = @import("parser.zig");

const Allocator = std.mem.Allocator;

pub const AssemblerState = struct {
    allocator: Allocator,
    symbol_table: symbols.SymbolTable,
    current_address: u64 = 0,
    start_address: u64 = 0,
    code_type: fasm.CodeType = .code_32,
    output_format: fasm.OutputFormat = .flat_binary,
    format_flags: fasm.FormatFlags = .{},
    pass_count: u16 = 1,
    max_passes: u32 = fasm.MAX_PASSES,
    changed: bool = true,
    variable_area: memory.VariableArea = undefined,
    output: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },

    pub fn init(allocator: Allocator) Allocator.Error!AssemblerState {
        return AssemblerState{
            .allocator = allocator,
            .symbol_table = symbols.SymbolTable.init(allocator),
            .variable_area = try memory.VariableArea.init(1024 * 1024),
            .output = .{ .items = &.{}, .capacity = 0 },
        };
    }

    pub fn deinit(self: *AssemblerState) void {
        self.symbol_table.deinit();
        self.variable_area.deinit();
        self.output.deinit(self.allocator);
    }

    pub fn reset(self: *AssemblerState) void {
        self.variable_area.reset();
        self.current_address = self.start_address;
        self.changed = false;
        self.output.shrinkRetainingCapacity(0);
    }

    pub fn assemble(self: *AssemblerState, source: []const u8) ![]const u8 {
        self.output.shrinkRetainingCapacity(0);

        while (self.changed and self.pass_count <= self.max_passes) {
            self.reset();
            try self.assemblePass(source);
            self.pass_count += 1;
            self.symbol_table.pass_count = self.pass_count;
        }

        if (self.changed and self.pass_count > self.max_passes) {
            return errors.AssemblerError.CodeCannotBeGenerated;
        }

        return self.output.items;
    }

    fn assemblePass(self: *AssemblerState, source: []const u8) !void {
        var pp = preprocessor.Preprocessor.init(self.allocator);
        defer pp.deinit();

        var source_parser = parser_mod.SourceParser.init(source);

        while (try source_parser.parseLine()) |parsed_line| {
            try pp.processLine(parsed_line.raw_line, 0, parsed_line.line_number);
            parsed_line.deinit(self.allocator);
        }

        for (pp.lines.items) |preprocessed_line| {
            if (preprocessed_line.text.len == 0) continue;

            const line_with_newline = try std.mem.concat(self.allocator, u8, &.{ preprocessed_line.text, "\n" });
            defer self.allocator.free(line_with_newline);
            var line_parser = parser_mod.SourceParser.init(line_with_newline);
            while (try line_parser.parseLine()) |line| {
                try self.processLine(&line);
                line.deinit(self.allocator);
            }
        }

        if (self.pass_count == 1) {
            self.changed = true;
        }
    }

    fn processLine(self: *AssemblerState, line: *const parser_mod.ParsedLine) !void {
        if (line.label.len > 0) {
            try self.symbol_table.define(line.label, self.current_address, .{
                .defined = true,
                .defined_this_pass = true,
            });
        }

        switch (line.directive) {
            .use16 => self.code_type = .code_16,
            .use32 => self.code_type = .code_32,
            .use64 => self.code_type = .code_64,
            .@"format" => {
                if (line.operands.len > 0) {
                    self.output_format = self.parseFormat(line.operands[0]);
                }
            },
            .@"align" => {
                if (line.operands.len > 0) {
                    const val = expr_calc.evaluateToU64(line.operands[0], self.allocator) catch 1;
                    if (val > 0) {
                        const mask = val - 1;
                        const misalignment = self.current_address & mask;
                        if (misalignment > 0) {
                            const padding = val - misalignment;
                            try self.output.appendNTimes(self.allocator, 0x90, @as(usize, @intCast(padding)));
                            self.current_address += padding;
                        }
                    }
                }
            },
            .@"org" => {
                if (line.operands.len > 0) {
                    self.current_address = expr_calc.evaluateToU64(line.operands[0], self.allocator) catch 0;
                }
            },
            .none => {
                if (line.is_data) {
                    try self.emitData(line);
                } else if (line.instruction.len > 0) {
                    try self.emitInstruction(line);
                }
            },
            else => {},
        }
    }

    fn parseFormat(_: *AssemblerState, format_str: []const u8) fasm.OutputFormat {
        if (std.ascii.eqlIgnoreCase(format_str, "binary")) return .flat_binary;
        if (std.ascii.eqlIgnoreCase(format_str, "MZ")) return .mz_executable;
        if (std.ascii.eqlIgnoreCase(format_str, "PE")) return .pe_executable;
        if (std.ascii.eqlIgnoreCase(format_str, "COFF")) return .coff_object;
        if (std.ascii.eqlIgnoreCase(format_str, "ELF")) return .elf_object;
        return .flat_binary;
    }

    fn emitData(self: *AssemblerState, line: *const parser_mod.ParsedLine) !void {
        const size = @intFromEnum(line.data_type);
        _ = size;
        for (line.operands) |operand| {
            const trimmed = std.mem.trim(u8, operand, " \t");
            if (trimmed.len == 0) continue;

            if (trimmed[0] == '\'' or trimmed[0] == '"') {
                const inner = trimmed[1 .. trimmed.len - 1];
                try self.output.appendSlice(self.allocator, inner);
                self.current_address += inner.len;
            } else {
                switch (line.data_type) {
                    .db => {
                        const val: u8 = @as(u8, @truncate(expr_calc.evaluateToU64(trimmed, self.allocator) catch 0));
                        try self.output.append(self.allocator, val);
                        self.current_address += 1;
                    },
                    .dw => {
                        const val: u16 = @as(u16, @truncate(expr_calc.evaluateToU64(trimmed, self.allocator) catch 0));
                        try self.output.appendSlice(self.allocator, std.mem.asBytes(&val));
                        self.current_address += 2;
                    },
                    .dd => {
                        const val: u32 = @as(u32, @truncate(expr_calc.evaluateToU64(trimmed, self.allocator) catch 0));
                        try self.output.appendSlice(self.allocator, std.mem.asBytes(&val));
                        self.current_address += 4;
                    },
                    .dq => {
                        const val = expr_calc.evaluateToU64(trimmed, self.allocator) catch 0;
                        try self.output.appendSlice(self.allocator, std.mem.asBytes(&val));
                        self.current_address += 8;
                    },
                    else => {
                        const val: u32 = @as(u32, @truncate(expr_calc.evaluateToU64(trimmed, self.allocator) catch 0));
                        try self.output.appendSlice(self.allocator, std.mem.asBytes(&val));
                        self.current_address += 4;
                    },
                }
            }
        }
    }

    fn emitInstruction(self: *AssemblerState, line: *const parser_mod.ParsedLine) !void {
        const inst = line.instruction;
        _ = inst;

        // For now, emit a simple encoding placeholder.
        // Full instruction encoding is handled by x86_64.zig and avx.zig.
        self.current_address += 1;
        try self.output.append(self.allocator, 0x90);
    }
};

pub fn assemble(source: []const u8, allocator: Allocator) ![]const u8 {
    var state = try AssemblerState.init(allocator);
    defer state.deinit();
    const result = try state.assemble(source);
    return try allocator.dupe(u8, result);
}

test "empty source assembly" {
    const alloc = std.testing.allocator;
    const result = try assemble("", alloc);
    defer alloc.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "simple label" {
    const alloc = std.testing.allocator;
    const result = try assemble("start:\n", alloc);
    defer alloc.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "data emission" {
    const alloc = std.testing.allocator;
    const result = try assemble("db 0x90\n", alloc);
    defer alloc.free(result);
    try std.testing.expectEqual(@as(usize, 1), result.len);
    try std.testing.expectEqual(@as(u8, 0x90), result[0]);
}

test "use64 directive" {
    var state = try AssemblerState.init(std.testing.allocator);
    defer state.deinit();
    _ = try state.assemble("use64\n");
    try std.testing.expectEqual(@as(fasm.CodeType, .code_64), state.code_type);
}
