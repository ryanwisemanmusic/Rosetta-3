const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const jwasm_assembler = @import("JWASM/Zig/assembler.zig");
const fasm_assembler = @import("FASM/Zig/assembler.zig");
const yasm_assembler = @import("YASM/Zig/assembler.zig");
const yasm_handshake_mod = @import("YASM/Zig/abi_handshake.zig");

const max_path = 4096;

const Mode = enum {
    assemble,
    validate,
};

var g_debug_enabled: c_int = 1;
var g_fail_fast_enabled: c_int = 1;
var g_log_path_storage: [max_path]u8 = [_]u8{0} ** max_path;

pub export fn rosette_debug_enabled() c_int {
    return g_debug_enabled;
}

pub export fn rosette_debug_log_path() [*:0]const u8 {
    return @ptrCast(&g_log_path_storage);
}

pub export fn rosette_runtime_abi_fail_fast_enabled() c_int {
    return g_fail_fast_enabled;
}

fn setLogPath(path: []const u8) void {
    const capped_len = @min(path.len, g_log_path_storage.len - 1);
    @memset(&g_log_path_storage, 0);
    @memcpy(g_log_path_storage[0..capped_len], path[0..capped_len]);
    g_log_path_storage[capped_len] = 0;
}

fn containsIgnoreCase(allocator: std.mem.Allocator, haystack: []const u8, needle: []const u8) !bool {
    const lower_haystack = try std.ascii.allocLowerString(allocator, haystack);
    defer allocator.free(lower_haystack);
    const lower_needle = try std.ascii.allocLowerString(allocator, needle);
    defer allocator.free(lower_needle);
    return std.mem.indexOf(u8, lower_haystack, lower_needle) != null;
}

fn containsAnyIgnoreCase(allocator: std.mem.Allocator, haystack: []const u8, needles: []const []const u8) !bool {
    for (needles) |needle| {
        if (try containsIgnoreCase(allocator, haystack, needle)) return true;
    }
    return false;
}

fn failValidation(comptime domain: []const u8, comptime check: []const u8, comptime fmt: []const u8, args: anytype) !void {
    runtime_abi.common.violation(domain, check, fmt, args);
    return error.ValidationFailed;
}

fn validateJwasmProfile(allocator: std.mem.Allocator, tool: []const u8, source: []const u8) !void {
    runtime_abi.common.noteValidation();
    if (source.len == 0) {
        return failValidation("assembler-jwasm", "empty_source", "tool={s}", .{tool});
    }

    if (std.mem.eql(u8, tool, "jwasm-irvine32")) {
        const irvine_needles = [_][]const u8{
            "Irvine32.inc",
            "WriteString",
            "ReadKey",
            "Gotoxy",
            "Clrscr",
        };
        if (!try containsAnyIgnoreCase(allocator, source, &irvine_needles)) {
            return failValidation("assembler-jwasm", "profile_mismatch", "expected irvine32 markers", .{});
        }
    } else {
        const jwasm_needles = [_][]const u8{
            ".model",
            " proc",
            " endp",
            "includelib",
            "byte ",
            "word ",
            "dword ",
            "qword ",
        };
        if (!try containsAnyIgnoreCase(allocator, source, &jwasm_needles)) {
            return failValidation("assembler-jwasm", "profile_mismatch", "expected jwasm/masm markers", .{});
        }
    }
}

fn validateFasmProfile(allocator: std.mem.Allocator, source: []const u8) !void {
    runtime_abi.common.noteValidation();
    if (source.len == 0) {
        return failValidation("assembler-fasm", "empty_source", "fasm source empty", .{});
    }

    const fasm_needles = [_][]const u8{
        "format ",
        "section ",
        "use16",
        "use32",
        "use64",
    };
    if (!try containsAnyIgnoreCase(allocator, source, &fasm_needles)) {
        return failValidation("assembler-fasm", "profile_mismatch", "expected fasm markers", .{});
    }
}

fn validateNasmProfile(allocator: std.mem.Allocator, source: []const u8) !void {
    runtime_abi.common.noteValidation();
    if (source.len == 0) {
        return failValidation("assembler-nasm", "empty_source", "nasm source empty", .{});
    }

    const nasm_needles = [_][]const u8{
        "section ",
        "bits ",
        "global ",
        "extern ",
        "%define",
    };
    if (!try containsAnyIgnoreCase(allocator, source, &nasm_needles)) {
        return failValidation("assembler-nasm", "profile_mismatch", "expected nasm markers", .{});
    }
}

fn validateYasmProfile(source: []const u8) !yasm_assembler.SourceProfile {
    runtime_abi.common.noteValidation();
    if (source.len == 0) {
        try failValidation("assembler-yasm", "empty_source", "yasm source empty", .{});
        unreachable;
    }

    const profile = yasm_assembler.detectSourceProfile(source);
    if (profile.kind == .unknown) {
        try failValidation("assembler-yasm", "profile_mismatch", "expected yasm/nasm-compatible ELF64 markers", .{});
        unreachable;
    }
    return profile;
}

fn validateArtifactBytes(comptime domain: []const u8, bytes: []const u8, artifact_path: []const u8) !void {
    runtime_abi.common.noteValidation();
    if (bytes.len > 16 * 1024 * 1024) {
        return failValidation(domain, "artifact_too_large", "{s}: {d}", .{ artifact_path, bytes.len });
    }
    if (bytes.len > 0 and bytes.len <= 15) {
        runtime_abi.common.writeLine("[runtime-abi][{s}][artifact] small artifact {d} bytes\n", .{ domain, bytes.len });
    }
}

fn writeArtifact(io: std.Io, path: []const u8, bytes: []const u8) !void {
    try std.Io.Dir.writeFile(.cwd(), io, .{
        .sub_path = path,
        .data = bytes,
    });
}

fn readFileAbsoluteAlloc(io: std.Io, allocator: std.mem.Allocator, path: []const u8, max_bytes: usize) ![]u8 {
    return try std.Io.Dir.readFileAlloc(.cwd(), io, path, allocator, .limited(max_bytes));
}

fn runAssemble(io: std.Io, allocator: std.mem.Allocator, tool: []const u8, source_path: []const u8, artifact_path: []const u8) !void {
    const source = try readFileAbsoluteAlloc(io, allocator, source_path, 32 * 1024 * 1024);
    defer allocator.free(source);

    if (std.mem.eql(u8, tool, "jwasm") or std.mem.eql(u8, tool, "jwasm-irvine32")) {
        try validateJwasmProfile(allocator, tool, source);
        const bytes = try jwasm_assembler.assembleJWASM(source, allocator);
        defer allocator.free(bytes);
        try validateArtifactBytes("assembler-jwasm", bytes, artifact_path);
        try writeArtifact(io, artifact_path, bytes);
        runtime_abi.common.writeLine("[runtime-abi][assembler][jwasm] assembled {s} -> {s} bytes={d}\n", .{ source_path, artifact_path, bytes.len });
        return;
    }

    if (std.mem.eql(u8, tool, "fasm")) {
        try validateFasmProfile(allocator, source);
        const bytes = try fasm_assembler.assemble(source, allocator);
        defer allocator.free(bytes);
        try validateArtifactBytes("assembler-fasm", bytes, artifact_path);
        try writeArtifact(io, artifact_path, bytes);
        runtime_abi.common.writeLine("[runtime-abi][assembler][fasm] assembled {s} -> {s} bytes={d}\n", .{ source_path, artifact_path, bytes.len });
        return;
    }

    if (std.mem.eql(u8, tool, "nasm")) {
        try validateNasmProfile(allocator, source);
        const artifact_bytes = try readFileAbsoluteAlloc(io, allocator, artifact_path, 64 * 1024 * 1024);
        defer allocator.free(artifact_bytes);
        try validateArtifactBytes("assembler-nasm", artifact_bytes, artifact_path);
        runtime_abi.common.writeLine("[runtime-abi][assembler][nasm] validated {s} -> {s} bytes={d}\n", .{ source_path, artifact_path, artifact_bytes.len });
        return;
    }

    if (std.mem.eql(u8, tool, "yasm") or
        std.mem.eql(u8, tool, "yasm-elf64") or
        std.mem.eql(u8, tool, "yasm-linux-elf64"))
    {
        const profile = try validateYasmProfile(source);
        var yasm_state = yasm_assembler.Assembler.init(allocator);
        defer yasm_state.deinit();
        yasm_state.setFormat(.elf64);
        const summary = try yasm_state.analyzeSource(source);

        const artifact_bytes = try readFileAbsoluteAlloc(io, allocator, artifact_path, 64 * 1024 * 1024);
        defer allocator.free(artifact_bytes);
        try validateArtifactBytes("assembler-yasm", artifact_bytes, artifact_path);

        var handshake = yasm_handshake_mod.YasmAbiHandshake.init(allocator);
        defer handshake.deinit();
        handshake.validateSourceProfile(profile);
        handshake.validateArtifact(.elf64, artifact_bytes);
        if (handshake.validator.error_count > 0) return error.ValidationFailed;

        runtime_abi.common.writeLine(
            "[runtime-abi][assembler][yasm] validated {s} -> {s} bytes={d} profile={s} instructions={d} syscalls={d}\n",
            .{ source_path, artifact_path, artifact_bytes.len, @tagName(summary.profile.kind), summary.instruction_count, summary.syscall_count },
        );
        return;
    }

    return failValidation("assembler", "unknown_tool", "{s}", .{tool});
}

fn parseMode(value: []const u8) !Mode {
    if (std.mem.eql(u8, value, "assemble")) return .assemble;
    if (std.mem.eql(u8, value, "validate")) return .validate;
    return error.InvalidMode;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 7) {
        std.debug.print("usage: {s} <tool> <source> <artifact> <log-path> <fail-fast:0|1> <mode>\n", .{args[0]});
        return error.InvalidArguments;
    }

    const tool = args[1];
    const source_path = args[2];
    const artifact_path = args[3];
    const log_path = args[4];
    g_fail_fast_enabled = if (std.mem.eql(u8, args[5], "0")) 0 else 1;
    const mode = try parseMode(args[6]);

    setLogPath(log_path);
    runtime_abi.common.acquire();
    defer runtime_abi.common.release();

    std.debug.print("ABI Validation layer: ACTIVE\n", .{});
    runtime_abi.common.writeLine("[runtime-abi][assembler] tool={s} source={s} artifact={s} mode={s}\n", .{
        tool,
        source_path,
        artifact_path,
        @tagName(mode),
    });

    switch (mode) {
        .assemble => try runAssemble(init.io, allocator, tool, source_path, artifact_path),
        .validate => try runAssemble(init.io, allocator, tool, source_path, artifact_path),
    }

    std.debug.print("ABI Validation checks: ALL Passed\n", .{});
}
