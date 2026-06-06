const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const add_adc = @import("ADD/ADC.zig");
const add_adcx = @import("ADD/ADCX.zig");
const add_add = @import("ADD/ADD.zig");
const add_addpd = @import("ADD/ADDPD.zig");
const add_addps = @import("ADD/ADDPS.zig");
const add_addsd = @import("ADD/ADDSD.zig");
const add_addss = @import("ADD/ADDSS.zig");
const add_addsubpd = @import("ADD/ADDSUBPD.zig");
const add_addsubps = @import("ADD/ADDSUBPS.zig");
const add_adox = @import("ADD/ADOX.zig");
const ascii_aaa = @import("ASCII/AAA.zig");
const ascii_aad = @import("ASCII/AAD.zig");
const ascii_aam = @import("ASCII/AAM.zig");
const ascii_aas = @import("ASCII/AAS.zig");
const div_div = @import("DIV/DIV.zig");
const div_idiv = @import("DIV/IDIV.zig");
const inc_dec_dec = @import("INC-DEC/DEC.zig");
const inc_dec_inc = @import("INC-DEC/INC.zig");
const mov_mov = @import("MOV/MOV.zig");
const mul_imul = @import("MUL/IMUL.zig");
const mul_mul = @import("MUL/MUL.zig");
const sub_sub = @import("SUB/SUB.zig");
const sub_subpd = @import("SUB/SUBPD.zig");
const sub_subps = @import("SUB/SUBPS.zig");
const sub_subsd = @import("SUB/SUBSD.zig");
const sub_subss = @import("SUB/SUBSS.zig");

pub const TableMetadata = struct {
    name: []const u8,
    category: []const u8,
    handler: []const u8,
    jit_lowering: []const u8,
    encoding_count: usize,
    source_path: []const u8,
    has_semantic: bool,
    has_flags: bool,
};

pub const InstructionTable = struct {
    family: []const u8,
    path: []const u8,
    source: []const u8,

    pub fn metadata(self: InstructionTable) TableMetadata {
        return .{
            .name = stringAssignment(self.source, "name") orelse mnemonicFromPath(self.path),
            .category = stringAssignment(self.source, "category") orelse "uncategorized",
            .handler = stringAssignment(self.source, "handler") orelse "",
            .jit_lowering = stringAssignment(self.source, "jit_lowering") orelse "",
            .encoding_count = countEncodingRows(self.source),
            .source_path = self.path,
            .has_semantic = hasAnyAssignment(self.source, &[_][]const u8{
                "semantic",
                "semantic_general",
                "semantic_legacy",
                "semantic_one_operand",
            }),
            .has_flags = hasAnyAssignment(self.source, &[_][]const u8{
                "flags",
                "flags_written",
                "flags_affected",
                "flags_set_or_cleared",
                "mxcsr_used",
                "simd_fp_exceptions",
            }),
        };
    }

    pub fn validate(self: InstructionTable) void {
        const meta = self.metadata();
        runtime_abi.isa.validateX86Table(.{
            .name = meta.name,
            .category = meta.category,
            .handler = meta.handler,
            .jit_lowering = meta.jit_lowering,
            .source_path = meta.source_path,
            .encoding_count = meta.encoding_count,
            .has_semantic = meta.has_semantic,
            .has_flags = meta.has_flags,
        });
    }
};

pub const tables = [_]InstructionTable{
    entry(add_adc.family, add_adc.path, add_adc.source),
    entry(add_adcx.family, add_adcx.path, add_adcx.source),
    entry(add_add.family, add_add.path, add_add.source),
    entry(add_addpd.family, add_addpd.path, add_addpd.source),
    entry(add_addps.family, add_addps.path, add_addps.source),
    entry(add_addsd.family, add_addsd.path, add_addsd.source),
    entry(add_addss.family, add_addss.path, add_addss.source),
    entry(add_addsubpd.family, add_addsubpd.path, add_addsubpd.source),
    entry(add_addsubps.family, add_addsubps.path, add_addsubps.source),
    entry(add_adox.family, add_adox.path, add_adox.source),
    entry(ascii_aaa.family, ascii_aaa.path, ascii_aaa.source),
    entry(ascii_aad.family, ascii_aad.path, ascii_aad.source),
    entry(ascii_aam.family, ascii_aam.path, ascii_aam.source),
    entry(ascii_aas.family, ascii_aas.path, ascii_aas.source),
    entry(div_div.family, div_div.path, div_div.source),
    entry(div_idiv.family, div_idiv.path, div_idiv.source),
    entry(inc_dec_dec.family, inc_dec_dec.path, inc_dec_dec.source),
    entry(inc_dec_inc.family, inc_dec_inc.path, inc_dec_inc.source),
    entry(mov_mov.family, mov_mov.path, mov_mov.source),
    entry(mul_imul.family, mul_imul.path, mul_imul.source),
    entry(mul_mul.family, mul_mul.path, mul_mul.source),
    entry(sub_sub.family, sub_sub.path, sub_sub.source),
    entry(sub_subpd.family, sub_subpd.path, sub_subpd.source),
    entry(sub_subps.family, sub_subps.path, sub_subps.source),
    entry(sub_subsd.family, sub_subsd.path, sub_subsd.source),
    entry(sub_subss.family, sub_subss.path, sub_subss.source),
};

pub fn tableCount() usize {
    return tables.len;
}

pub fn findByName(name: []const u8) ?InstructionTable {
    for (tables) |table| {
        const meta = table.metadata();
        if (std.ascii.eqlIgnoreCase(meta.name, name)) return table;
    }
    return null;
}

pub fn validateAll() void {
    for (tables) |table| table.validate();
    validateUniqueNames();
}

fn entry(family: []const u8, path: []const u8, source: []const u8) InstructionTable {
    return .{ .family = family, .path = path, .source = source };
}

fn validateUniqueNames() void {
    for (tables, 0..) |lhs, i| {
        const lhs_name = lhs.metadata().name;
        for (tables[i + 1 ..]) |rhs| {
            const rhs_name = rhs.metadata().name;
            if (std.ascii.eqlIgnoreCase(lhs_name, rhs_name)) {
                runtime_abi.isa.validateNoDuplicateInstruction(lhs_name, lhs.path, rhs.path);
            }
        }
    }
}

fn stripLineComment(line: []const u8) []const u8 {
    const idx = std.mem.indexOf(u8, line, "//") orelse return line;
    return line[0..idx];
}

fn stringAssignment(source: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        if (!std.mem.startsWith(u8, line, key)) continue;
        const rest = std.mem.trim(u8, line[key.len..], " \t");
        if (!std.mem.startsWith(u8, rest, "=")) continue;
        const value = std.mem.trim(u8, rest[1..], " \t");
        if (value.len < 2 or value[0] != '"') continue;
        const end = std.mem.indexOfScalar(u8, value[1..], '"') orelse continue;
        return value[1 .. 1 + end];
    }
    return null;
}

fn hasAnyAssignment(source: []const u8, keys: []const []const u8) bool {
    for (keys) |key| {
        if (hasAssignment(source, key)) return true;
    }
    return false;
}

fn hasAssignment(source: []const u8, key: []const u8) bool {
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        if (!std.mem.startsWith(u8, line, key)) continue;
        const rest = std.mem.trim(u8, line[key.len..], " \t");
        if (std.mem.startsWith(u8, rest, "=")) return true;
    }
    return false;
}

fn countEncodingRows(source: []const u8) usize {
    const block_start = std.mem.indexOf(u8, source, "encodings") orelse return 0;
    const bracket_rel = std.mem.indexOfScalar(u8, source[block_start..], '[') orelse return 0;
    const body_start = block_start + bracket_rel + 1;
    const body_end_rel = std.mem.indexOfScalar(u8, source[body_start..], ']') orelse return 0;
    const body = source[body_start .. body_start + body_end_rel];

    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, body, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        if (std.mem.startsWith(u8, line, "{")) count += 1;
    }
    return count;
}

fn mnemonicFromPath(path: []const u8) []const u8 {
    const slash = std.mem.lastIndexOfScalar(u8, path, '/') orelse 0;
    const start = if (path[slash] == '/') slash + 1 else slash;
    const dot = std.mem.lastIndexOfScalar(u8, path, '.') orelse path.len;
    return path[start..dot];
}

test "x86 ISA tables expose required metadata" {
    try std.testing.expectEqual(@as(usize, 26), tableCount());
    validateAll();
    const add = (findByName("ADD") orelse return error.MissingAdd).metadata();
    try std.testing.expectEqualStrings("x86_add", add.handler);
    try std.testing.expect(add.encoding_count >= 1);
}
