const std = @import("std");

const ParsedLine = union(enum) {
    section: []const u8,
    equ: struct { name: []const u8, value: []const u8 },
    label: []const u8,
    instruction: struct { op: []const u8, args: []const u8 },
    data_decl: struct { name: []const u8, kind: []const u8, value: []const u8 },
    ignore,
};

fn trimComment(line: []const u8) []const u8 {
    var split = std.mem.splitScalar(u8, line, ';');
    return std.mem.trim(u8, split.first(), " \t\r");
}

fn parseLine(line: []const u8) ParsedLine {
    const trimmed = trimComment(line);
    if (trimmed.len == 0) return .ignore;

    if (std.mem.startsWith(u8, trimmed, "section .")) {
        return .{ .section = trimmed["section .".len..] };
    }

    if (std.mem.indexOf(u8, trimmed, " equ ")) |idx| {
        return .{ .equ = .{
            .name = std.mem.trim(u8, trimmed[0..idx], " \t"),
            .value = std.mem.trim(u8, trimmed[idx + 5 ..], " \t"),
        } };
    }

    if (trimmed[trimmed.len - 1] == ':') {
        return .{ .label = trimmed[0 .. trimmed.len - 1] };
    }

    const data_kinds = [_][]const u8{ " db ", " dw ", " dd ", " times " };
    for (data_kinds) |kind| {
        if (std.mem.indexOf(u8, trimmed, kind)) |idx| {
            return .{ .data_decl = .{
                .name = std.mem.trim(u8, trimmed[0..idx], " \t"),
                .kind = std.mem.trim(u8, kind, " \t"),
                .value = std.mem.trim(u8, trimmed[idx + kind.len ..], " \t"),
            } };
        }
    }

    const first_space = std.mem.indexOfScalar(u8, trimmed, ' ') orelse trimmed.len;
    return .{ .instruction = .{
        .op = trimmed[0..first_space],
        .args = if (first_space < trimmed.len) std.mem.trim(u8, trimmed[first_space + 1 ..], " \t") else "",
    } };
}

fn writeHeader(writer: anytype) !void {
    try writer.writeAll(
        \\const std = @import("std");
        \\const Executor = @import("instruction_operations.zig").Executor;
        \\const abi = @import("abi_handshake.zig");
        \\
        \\pub export fn rosette_run_prototype() void {
        \\    const allocator = std.heap.page_allocator;
        \\    var ex = Executor.init(allocator, 1024 * 1024);
        \\    defer ex.deinit();
        \\    ex.regs.esp = 0x100000;
        \\
    );
}

fn writeFooter(writer: anytype) !void {
    try writer.writeAll(
        \\
        \\    _main(&ex);
        \\}
        \\
    );
}

fn translateInstruction(writer: anytype, op: []const u8, args: []const u8) !void {
    if (std.ascii.eqlIgnoreCase(op, "ret")) {
        try writer.writeAll("    return;\n");
        return;
    }

    if (std.ascii.eqlIgnoreCase(op, "call")) {
        if (args.len > 0 and args[0] == '_') {
            try writer.print("    // external call {s}\n", .{args});
        } else {
            try writer.print("    {s}(ex);\n", .{args});
        }
        return;
    }

    if (std.ascii.eqlIgnoreCase(op, "mov")) {
        var split = std.mem.splitScalar(u8, args, ',');
        const dst = std.mem.trim(u8, split.next() orelse "", " \t");
        const src = std.mem.trim(u8, split.next() orelse "", " \t");
        const regs = [_][]const u8{ "eax", "ebx", "ecx", "edx", "esi", "edi", "ebp", "esp" };

        var dst_reg = false;
        var src_reg = false;
        for (regs) |reg| {
            if (std.ascii.eqlIgnoreCase(dst, reg)) dst_reg = true;
            if (std.ascii.eqlIgnoreCase(src, reg)) src_reg = true;
        }

        if (dst_reg and src_reg) {
            try writer.print("    ex.mov_reg_reg(.{s}, .{s});\n", .{ dst, src });
            return;
        }
        if (dst_reg) {
            try writer.print("    ex.mov_reg_imm(.{s}, {s});\n", .{ dst, src });
            return;
        }
    }

    try writer.print("    // TODO: {s} {s}\n", .{ op, args });
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);
    if (args.len != 3) {
        std.debug.print("usage: {s} <input.asm> <output.zig>\n", .{args[0]});
        return error.InvalidArguments;
    }

    const asm_source = try std.Io.Dir.cwd().readFileAlloc(init.io, args[1], allocator, .limited(1024 * 1024));
    var output: std.ArrayList(u8) = .empty;
    var writer_state: std.Io.Writer.Allocating = .fromArrayList(allocator, &output);
    defer output = writer_state.toArrayList();
    const writer = &writer_state.writer;

    try writeHeader(writer);

    var current_section: ?[]const u8 = null;
    var line_iter = std.mem.splitScalar(u8, asm_source, '\n');
    while (line_iter.next()) |line| {
        switch (parseLine(line)) {
            .ignore => {},
            .section => |name| current_section = name,
            .equ => |entry| try writer.print("    // EQU {s} = {s}\n", .{ entry.name, entry.value }),
            .data_decl => |decl| {
                if (current_section != null and std.mem.eql(u8, current_section.?, "data")) {
                    try writer.print("    // DATA {s} {s} {s}\n", .{ decl.name, decl.kind, decl.value });
                }
            },
            .label => |name| try writer.print("fn {s}(ex: *Executor) void {{\n", .{name}),
            .instruction => |inst| try translateInstruction(writer, inst.op, inst.args),
        }
    }

    try writeFooter(writer);
    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[2], .data = output.items });
}
