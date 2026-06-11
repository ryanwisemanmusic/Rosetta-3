const std = @import("std");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("sys/stat.h");
    @cInclude("unistd.h");
});

const block_begin = "# >>> Rosette shell integration >>>";
const block_end = "# <<< Rosette shell integration <<<";
const max_text_file = 512 * 1024;

const Detection = struct {
    detected: bool,
    score: u32,
    kind: []const u8,
    signals: []const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len < 2) return usage(args[0]);

    if (std.mem.eql(u8, args[1], "install")) {
        const source_root = if (args.len >= 3) args[2] else "";
        try installOrUpdate(init, allocator, source_root);
        return;
    }
    if (std.mem.eql(u8, args[1], "update")) {
        const source_root = if (args.len >= 3) args[2] else "";
        try installOrUpdate(init, allocator, source_root);
        return;
    }
    if (std.mem.eql(u8, args[1], "uninstall")) {
        try uninstallShell(init, allocator);
        return;
    }
    if (std.mem.eql(u8, args[1], "detect")) {
        const project_dir = if (args.len >= 3) args[2] else ".";
        const resolved = try absolutePath(allocator, project_dir);
        const detection = try detectProject(init.io, allocator, resolved);
        if (detection.detected) {
            std.debug.print("detected: {s} score={d} signals={s}\n", .{ detection.kind, detection.score, detection.signals });
            std.process.exit(0);
        }
        std.debug.print("not detected: score={d} signals={s}\n", .{ detection.score, detection.signals });
        std.process.exit(1);
    }
    if (std.mem.eql(u8, args[1], "prepare-make")) {
        if (args.len < 4) return usage(args[0]);
        try prepareMake(init, allocator, args[2], args[3], args[4..]);
        return;
    }
    if (std.mem.eql(u8, args[1], "finish-make")) {
        if (args.len < 4) return usage(args[0]);
        try finishMake(allocator, args[2], args[3], args[4..]);
        return;
    }
    if (std.mem.eql(u8, args[1], "tool")) {
        if (args.len < 3) return usage(args[0]);
        try runTool(init, allocator, args[2], args[3..]);
        return;
    }

    return usage(args[0]);
}

fn usage(exe_name: []const u8) void {
    std.debug.print(
        \\Rosette global shell helper
        \\
        \\Usage:
        \\  {s} install [source-root]
        \\  {s} update [source-root]
        \\  {s} uninstall
        \\  {s} detect [project-directory]
        \\  {s} prepare-make <project-directory> <env-file> [make-args...]
        \\  {s} finish-make <project-directory> <status> [make-args...]
        \\  {s} tool <tool-name> [tool-args...]
        \\
    , .{ exe_name, exe_name, exe_name, exe_name, exe_name, exe_name, exe_name });
}

fn installOrUpdate(init: std.process.Init, allocator: std.mem.Allocator, source_root: []const u8) !void {
    const home = try homeDir(allocator);
    const rosette_dir = try std.fs.path.join(allocator, &.{ home, ".rosette" });
    const bin_dir = try std.fs.path.join(allocator, &.{ rosette_dir, "bin" });
    const wrapper_dir = try std.fs.path.join(allocator, &.{ rosette_dir, "wrappers" });
    const helper_path = try std.fs.path.join(allocator, &.{ bin_dir, "rosette-shell" });
    const shell_path = try std.fs.path.join(allocator, &.{ rosette_dir, "rosette-shell.sh" });

    try makePathRecursive(allocator, bin_dir);
    try makePathRecursive(allocator, wrapper_dir);
    try copySelf(init, allocator, helper_path);
    try ensureWrappers(allocator, wrapper_dir, helper_path);

    const snippet = buildShellSnippet();
    try writeFilePath(allocator, shell_path, snippet);
    try chmodPath(allocator, shell_path, 0o644);

    const block = try buildProfileBlock(allocator);
    const zshrc = try std.fs.path.join(allocator, &.{ home, ".zshrc" });
    const bashrc = try std.fs.path.join(allocator, &.{ home, ".bashrc" });
    try ensureProfileBlock(init.io, allocator, zshrc, block, true);
    try ensureProfileBlock(init.io, allocator, bashrc, block, fileExists(allocator, bashrc));

    if (source_root.len != 0) {
        const config_path = try std.fs.path.join(allocator, &.{ rosette_dir, "source-root" });
        const source_text = try std.fmt.allocPrint(allocator, "{s}\n", .{source_root});
        try writeFilePath(allocator, config_path, source_text);
    }

    std.debug.print("Rosette shell integration installed.\n", .{});
    std.debug.print("source: {s}\n", .{shell_path});
}

fn uninstallShell(init: std.process.Init, allocator: std.mem.Allocator) !void {
    const home = try homeDir(allocator);
    const rosette_dir = try std.fs.path.join(allocator, &.{ home, ".rosette" });
    const bin_dir = try std.fs.path.join(allocator, &.{ rosette_dir, "bin" });
    const wrapper_dir = try std.fs.path.join(allocator, &.{ rosette_dir, "wrappers" });
    const shell_path = try std.fs.path.join(allocator, &.{ rosette_dir, "rosette-shell.sh" });
    const helper_path = try std.fs.path.join(allocator, &.{ bin_dir, "rosette-shell" });
    const source_root = try std.fs.path.join(allocator, &.{ rosette_dir, "source-root" });

    const zshrc = try std.fs.path.join(allocator, &.{ home, ".zshrc" });
    const bashrc = try std.fs.path.join(allocator, &.{ home, ".bashrc" });
    try removeProfileBlock(init.io, allocator, zshrc);
    try removeProfileBlock(init.io, allocator, bashrc);

    try unlinkIfExists(allocator, shell_path);
    try unlinkIfExists(allocator, source_root);
    try removeWrappers(allocator, wrapper_dir);
    try unlinkIfExists(allocator, helper_path);
    rmdirIfEmpty(allocator, wrapper_dir) catch {};
    rmdirIfEmpty(allocator, bin_dir) catch {};
    rmdirIfEmpty(allocator, rosette_dir) catch {};

    std.debug.print("Rosette shell integration removed.\n", .{});
}

fn prepareMake(
    init: std.process.Init,
    allocator: std.mem.Allocator,
    project_dir_raw: []const u8,
    env_path: []const u8,
    make_args: []const []const u8,
) !void {
    const project_dir = try absolutePath(allocator, project_dir_raw);
    const detection = try detectProject(init.io, allocator, project_dir);
    if (!detection.detected) std.process.exit(1);

    const home = try homeDir(allocator);
    const wrapper_dir = try std.fs.path.join(allocator, &.{ home, ".rosette", "wrappers" });
    try makePathRecursive(allocator, wrapper_dir);

    const helper_path = try currentHelperPath(init, allocator);
    try ensureWrappers(allocator, wrapper_dir, helper_path);

    const trace_dir = try std.fs.path.join(allocator, &.{ project_dir, ".rosette" });
    try makePathRecursive(allocator, trace_dir);
    const trace_path = try std.fs.path.join(allocator, &.{ trace_dir, "rosette-shell.trace.log" });

    try appendMakeStartTrace(allocator, trace_path, project_dir, detection, make_args);
    const env_text = try buildMakeEnv(allocator, project_dir, wrapper_dir, helper_path, trace_path, detection.kind);
    try writeFilePath(allocator, env_path, env_text);
    std.process.exit(0);
}

fn finishMake(allocator: std.mem.Allocator, project_dir: []const u8, status_text: []const u8, make_args: []const []const u8) !void {
    const trace_path_raw = std.c.getenv("ROSETTE_SHELL_TRACE") orelse return;
    const trace_path = std.mem.sliceTo(trace_path_raw, 0);

    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(allocator);
    try out.appendSlice(allocator, "finish status=");
    try out.appendSlice(allocator, status_text);
    try out.appendSlice(allocator, " cwd=");
    try out.appendSlice(allocator, project_dir);
    try out.appendSlice(allocator, " args=");
    try appendArgs(&out, allocator, make_args);
    try out.append(allocator, '\n');
    try appendFilePath(allocator, trace_path, out.items);
}

fn runTool(init: std.process.Init, allocator: std.mem.Allocator, tool_name: []const u8, tool_args: []const []const u8) !void {
    const active = std.c.getenv("ROSETTE_SHELL_ACTIVE") orelse "";
    if (!std.mem.eql(u8, std.mem.sliceTo(active, 0), "1")) {
        try execResolved(init.io, allocator, tool_name, tool_args);
    }

    if (std.mem.eql(u8, tool_name, "ld")) {
        try appendToolTrace(allocator, tool_name, "zig-cc-linux-nostdlib", tool_args);
        try execZigLd(init.io, allocator, tool_args);
    } else if (isCxxTool(tool_name)) {
        try appendToolTrace(allocator, tool_name, "zig-cxx-linux", tool_args);
        try execZigCompiler(init.io, allocator, "c++", tool_args);
    } else if (isCcTool(tool_name)) {
        try appendToolTrace(allocator, tool_name, "zig-cc-linux", tool_args);
        try execZigCompiler(init.io, allocator, "cc", tool_args);
    } else {
        try appendToolTrace(allocator, tool_name, "native", tool_args);
        try execResolved(init.io, allocator, tool_name, tool_args);
    }
}

fn detectProject(io: std.Io, allocator: std.mem.Allocator, project_dir: []const u8) !Detection {
    var score: u32 = 0;
    var has_yasm_elf64 = false;
    var has_cs218 = false;
    var has_cpp = false;
    var saw_makefile = false;
    var signals: std.ArrayList(u8) = .empty;

    if (try readProjectFile(io, allocator, project_dir, "Makefile")) |makefile| {
        saw_makefile = true;
        if (containsIgnoreCase(makefile, "CS 218")) {
            score += 3;
            has_cs218 = true;
            try addSignal(&signals, allocator, "makefile:cs218");
        }
        if (containsIgnoreCase(makefile, "yasm -g dwarf2 -f elf64")) {
            score += 4;
            has_yasm_elf64 = true;
            try addSignal(&signals, allocator, "makefile:yasm-elf64");
        }
        if (containsIgnoreCase(makefile, "LD") and containsIgnoreCase(makefile, "ld -g")) {
            score += 1;
            try addSignal(&signals, allocator, "makefile:linux-ld");
        }
        if (containsIgnoreCase(makefile, "g++") and containsIgnoreCase(makefile, "-z noexecstack")) {
            score += 2;
            has_cpp = true;
            try addSignal(&signals, allocator, "makefile:linux-cxx");
        }
    }

    if (!saw_makefile) {
        if (try readProjectFile(io, allocator, project_dir, "makefile")) |makefile| {
            if (containsIgnoreCase(makefile, "CS 218")) {
                score += 3;
                has_cs218 = true;
                try addSignal(&signals, allocator, "makefile:cs218");
            }
            if (containsIgnoreCase(makefile, "yasm -g dwarf2 -f elf64")) {
                score += 4;
                has_yasm_elf64 = true;
                try addSignal(&signals, allocator, "makefile:yasm-elf64");
            }
        }
    }

    try scoreAssemblyFiles(io, allocator, project_dir, &score, &signals);

    const detected = score >= 7 and (has_yasm_elf64 or has_cs218);
    const kind = if (has_cpp) "cs218-yasm-elf64-cxx" else "cs218-yasm-elf64";
    if (signals.items.len == 0) try signals.appendSlice(allocator, "none");

    return .{
        .detected = detected,
        .score = score,
        .kind = kind,
        .signals = signals.items,
    };
}

fn scoreAssemblyFiles(
    io: std.Io,
    allocator: std.mem.Allocator,
    project_dir: []const u8,
    score: *u32,
    signals: *std.ArrayList(u8),
) !void {
    var dir = std.Io.Dir.openDirAbsolute(io, project_dir, .{ .iterate = true }) catch return;
    defer dir.close(io);

    var it = dir.iterate();
    var files_seen: usize = 0;
    while (try it.next(io)) |entry| {
        if (!std.ascii.endsWithIgnoreCase(entry.name, ".asm")) continue;
        files_seen += 1;
        if (files_seen > 12) break;

        const path = try std.fs.path.join(allocator, &.{ project_dir, entry.name });
        const data = std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(max_text_file)) catch continue;
        if (containsIgnoreCase(data, "Assignment:") or containsIgnoreCase(data, "Assignment #")) {
            score.* += 1;
            try addSignal(signals, allocator, "asm:assignment");
        }
        if (containsIgnoreCase(data, "section .text") or containsIgnoreCase(data, "section\t.text")) {
            score.* += 1;
            try addSignal(signals, allocator, "asm:text-section");
        }
        if (containsIgnoreCase(data, "global _start") or containsIgnoreCase(data, "global checkParams")) {
            score.* += 1;
            try addSignal(signals, allocator, "asm:globals");
        }
        if (containsIgnoreCase(data, "SYS_exit") or containsIgnoreCase(data, "SYS_read") or containsIgnoreCase(data, "SYS_write")) {
            score.* += 1;
            try addSignal(signals, allocator, "asm:linux-syscalls");
        }
        if (containsIgnoreCase(data, "syscall")) {
            score.* += 1;
            try addSignal(signals, allocator, "asm:syscall");
        }
    }
}

fn readProjectFile(io: std.Io, allocator: std.mem.Allocator, project_dir: []const u8, name: []const u8) !?[]u8 {
    const path = try std.fs.path.join(allocator, &.{ project_dir, name });
    return std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(max_text_file)) catch null;
}

fn appendMakeStartTrace(
    allocator: std.mem.Allocator,
    trace_path: []const u8,
    project_dir: []const u8,
    detection: Detection,
    make_args: []const []const u8,
) !void {
    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(allocator);

    try out.appendSlice(allocator, "# Rosette global shell trace\n");
    try out.appendSlice(allocator, "project = ");
    try out.appendSlice(allocator, project_dir);
    try out.append(allocator, '\n');
    try out.appendSlice(allocator, "kind = ");
    try out.appendSlice(allocator, detection.kind);
    try out.append(allocator, '\n');
    try out.appendSlice(allocator, "score = ");
    try appendInt(&out, allocator, detection.score);
    try out.append(allocator, '\n');
    try out.appendSlice(allocator, "signals = ");
    try out.appendSlice(allocator, detection.signals);
    try out.append(allocator, '\n');
    try out.appendSlice(allocator, "make_args = ");
    try appendArgs(&out, allocator, make_args);
    try out.append(allocator, '\n');
    try appendFilePath(allocator, trace_path, out.items);
}

fn appendToolTrace(allocator: std.mem.Allocator, tool_name: []const u8, strategy: []const u8, tool_args: []const []const u8) !void {
    const trace_path_raw = std.c.getenv("ROSETTE_SHELL_TRACE") orelse return;
    const trace_path = std.mem.sliceTo(trace_path_raw, 0);
    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(allocator);

    try out.appendSlice(allocator, "tool[");
    try out.appendSlice(allocator, tool_name);
    try out.appendSlice(allocator, "] strategy=");
    try out.appendSlice(allocator, strategy);
    try out.appendSlice(allocator, " args=");
    try appendArgs(&out, allocator, tool_args);
    try out.append(allocator, '\n');
    try appendFilePath(allocator, trace_path, out.items);
}

fn buildMakeEnv(
    allocator: std.mem.Allocator,
    project_dir: []const u8,
    wrapper_dir: []const u8,
    helper_path: []const u8,
    trace_path: []const u8,
    kind: []const u8,
) ![]const u8 {
    const current_path = getenvSlice("PATH") orelse "";
    const tmp = getenvSlice("TMPDIR") orelse "/tmp";
    const local_cache = try std.fs.path.join(allocator, &.{ tmp, "rosette-zig-cache" });
    const global_cache = try std.fs.path.join(allocator, &.{ tmp, "rosette-zig-global-cache" });
    const wrapped_path = try std.fmt.allocPrint(allocator, "{s}:{s}", .{ wrapper_dir, current_path });

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "# generated by rosette-shell prepare-make\n");
    try appendExport(&out, allocator, "ROSETTE_SHELL_ACTIVE", "1");
    try appendExport(&out, allocator, "ROSETTE_SHELL_PROJECT_KIND", kind);
    try appendExport(&out, allocator, "ROSETTE_SHELL_PROJECT_DIR", project_dir);
    try appendExport(&out, allocator, "ROSETTE_SHELL_TRACE", trace_path);
    try appendExport(&out, allocator, "ROSETTE_SHELL_HELPER", helper_path);
    try appendExport(&out, allocator, "ROSETTE_SHELL_WRAPPER_DIR", wrapper_dir);
    try appendExport(&out, allocator, "ROSETTE_SHELL_ORIGINAL_PATH", current_path);
    try appendExport(&out, allocator, "PATH", wrapped_path);
    try appendExport(&out, allocator, "ZIG_LOCAL_CACHE_DIR", local_cache);
    try appendExport(&out, allocator, "ZIG_GLOBAL_CACHE_DIR", global_cache);
    try out.appendSlice(allocator, "unset MAKEFILES\n");
    return out.items;
}

fn buildShellSnippet() []const u8 {
    return
    \\# Rosette shell integration. This does not replace make; it only
    \\# checks the current directory before delegating to command make.
    \\if [ -z "${ROSETTE_SHELL_DISABLE:-}" ]; then
    \\  export ROSETTE_SHELL_HELPER="${ROSETTE_SHELL_HELPER:-$HOME/.rosette/bin/rosette-shell}"
    \\  if [ -x "$ROSETTE_SHELL_HELPER" ]; then
    \\    make() {
    \\      local __rosette_env __rosette_status __rosette_old_path
    \\      local __rosette_old_makefiles __rosette_had_makefiles
    \\      __rosette_env="${TMPDIR:-/tmp}/rosette-shell-env.$$"
    \\      __rosette_old_path="$PATH"
    \\      __rosette_had_makefiles=0
    \\      if [ "${MAKEFILES+x}" = "x" ]; then
    \\        __rosette_had_makefiles=1
    \\        __rosette_old_makefiles="$MAKEFILES"
    \\      fi
    \\      if "$ROSETTE_SHELL_HELPER" prepare-make "$PWD" "$__rosette_env" "$@" >/dev/null 2>&1; then
    \\        . "$__rosette_env"
    \\        rm -f "$__rosette_env"
    \\        command make "$@"
    \\        __rosette_status=$?
    \\        "$ROSETTE_SHELL_HELPER" finish-make "$PWD" "$__rosette_status" "$@" >/dev/null 2>&1 || true
    \\        PATH="$__rosette_old_path"
    \\        if [ "$__rosette_had_makefiles" = "1" ]; then
    \\          export MAKEFILES="$__rosette_old_makefiles"
    \\        else
    \\          unset MAKEFILES
    \\        fi
    \\        unset ROSETTE_SHELL_ACTIVE ROSETTE_SHELL_PROJECT_KIND ROSETTE_SHELL_PROJECT_DIR
    \\        unset ROSETTE_SHELL_TRACE ROSETTE_SHELL_WRAPPER_DIR ROSETTE_SHELL_ORIGINAL_PATH
    \\        return "$__rosette_status"
    \\      fi
    \\      rm -f "$__rosette_env"
    \\      PATH="$__rosette_old_path"
    \\      command make "$@"
    \\    }
    \\  fi
    \\fi
    \\
    ;
}

fn buildProfileBlock(allocator: std.mem.Allocator) ![]const u8 {
    return try std.fmt.allocPrint(allocator,
        \\{s}
        \\[ -f "$HOME/.rosette/rosette-shell.sh" ] && . "$HOME/.rosette/rosette-shell.sh"
        \\{s}
        \\
    , .{ block_begin, block_end });
}

fn ensureProfileBlock(io: std.Io, allocator: std.mem.Allocator, path: []const u8, block: []const u8, create_if_missing: bool) !void {
    const existing = std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024)) catch |err| switch (err) {
        error.FileNotFound => {
            if (!create_if_missing) return;
            try writeFilePath(allocator, path, block);
            return;
        },
        else => return err,
    };

    const updated = try replaceManagedBlock(allocator, existing, block);
    if (!std.mem.eql(u8, existing, updated)) try writeFilePath(allocator, path, updated);
}

fn removeProfileBlock(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !void {
    const existing = std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024)) catch return;
    const removed = try removeManagedBlock(allocator, existing);
    if (!std.mem.eql(u8, existing, removed)) try writeFilePath(allocator, path, removed);
}

fn replaceManagedBlock(allocator: std.mem.Allocator, existing: []const u8, block: []const u8) ![]const u8 {
    const begin = std.mem.indexOf(u8, existing, block_begin);
    if (begin) |start| {
        if (std.mem.indexOfPos(u8, existing, start, block_end)) |end_start| {
            var end = end_start + block_end.len;
            if (end < existing.len and existing[end] == '\n') end += 1;
            var out: std.ArrayList(u8) = .empty;
            errdefer out.deinit(allocator);
            try out.appendSlice(allocator, existing[0..start]);
            try out.appendSlice(allocator, block);
            try out.appendSlice(allocator, existing[end..]);
            return out.items;
        }
    }

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, existing);
    if (existing.len != 0 and existing[existing.len - 1] != '\n') try out.append(allocator, '\n');
    try out.appendSlice(allocator, block);
    return out.items;
}

fn removeManagedBlock(allocator: std.mem.Allocator, existing: []const u8) ![]const u8 {
    const begin = std.mem.indexOf(u8, existing, block_begin) orelse return existing;
    const end_start = std.mem.indexOfPos(u8, existing, begin, block_end) orelse return existing;
    var end = end_start + block_end.len;
    if (end < existing.len and existing[end] == '\n') end += 1;

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, existing[0..begin]);
    try out.appendSlice(allocator, existing[end..]);
    return out.items;
}

fn ensureWrappers(allocator: std.mem.Allocator, wrapper_dir: []const u8, helper_path: []const u8) !void {
    try makePathRecursive(allocator, wrapper_dir);
    const tools = [_][]const u8{ "yasm", "ld", "g++", "c++", "gcc", "cc", "clang", "clang++" };
    for (tools) |tool| {
        const path = try std.fs.path.join(allocator, &.{ wrapper_dir, tool });
        const script = try std.fmt.allocPrint(allocator,
            \\#!/bin/sh
            \\exec "{s}" tool "{s}" "$@"
            \\
        , .{ helper_path, tool });
        try writeFilePath(allocator, path, script);
        try chmodPath(allocator, path, 0o755);
    }
}

fn removeWrappers(allocator: std.mem.Allocator, wrapper_dir: []const u8) !void {
    const tools = [_][]const u8{ "yasm", "ld", "g++", "c++", "gcc", "cc", "clang", "clang++" };
    for (tools) |tool| {
        const path = try std.fs.path.join(allocator, &.{ wrapper_dir, tool });
        try unlinkIfExists(allocator, path);
    }
}

fn copySelf(init: std.process.Init, allocator: std.mem.Allocator, destination: []const u8) !void {
    const self_path = try std.process.executablePathAlloc(init.io, allocator);
    const resolved_dest = try std.fs.path.resolve(allocator, &.{destination});
    const resolved_self = try std.fs.path.resolve(allocator, &.{self_path});
    if (std.mem.eql(u8, resolved_self, resolved_dest)) {
        try chmodPath(allocator, destination, 0o755);
        return;
    }

    const bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, self_path, allocator, .unlimited);
    try writeFilePath(allocator, destination, bytes);
    try chmodPath(allocator, destination, 0o755);
}

fn currentHelperPath(init: std.process.Init, allocator: std.mem.Allocator) ![]const u8 {
    if (getenvSlice("ROSETTE_SHELL_HELPER")) |helper| return try allocator.dupe(u8, helper);
    return try std.process.executablePathAlloc(init.io, allocator);
}

fn execZigLd(io: std.Io, allocator: std.mem.Allocator, tool_args: []const []const u8) !void {
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.append(allocator, try resolveToolPath(allocator, "zig"));
    try argv.append(allocator, "cc");
    try argv.append(allocator, "-target");
    try argv.append(allocator, "x86_64-linux-gnu");
    try argv.append(allocator, "-nostdlib");
    try appendFilteredLinuxArgs(&argv, allocator, tool_args, true);
    try execArgv(io, argv.items);
}

fn execZigCompiler(io: std.Io, allocator: std.mem.Allocator, zig_mode: []const u8, tool_args: []const []const u8) !void {
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.append(allocator, try resolveToolPath(allocator, "zig"));
    try argv.append(allocator, zig_mode);
    try argv.append(allocator, "-target");
    try argv.append(allocator, "x86_64-linux-gnu");
    try argv.append(allocator, "-Wno-nullability-completeness");
    try appendFilteredLinuxArgs(&argv, allocator, tool_args, false);
    try execArgv(io, argv.items);
}

fn appendFilteredLinuxArgs(
    argv: *std.ArrayList([]const u8),
    allocator: std.mem.Allocator,
    tool_args: []const []const u8,
    strip_ld_debug: bool,
) !void {
    var i: usize = 0;
    while (i < tool_args.len) : (i += 1) {
        const arg = tool_args[i];
        if (strip_ld_debug and std.mem.eql(u8, arg, "-g")) continue;
        if (std.mem.eql(u8, arg, "-z") and i + 1 < tool_args.len and std.mem.eql(u8, tool_args[i + 1], "noexecstack")) {
            i += 1;
            continue;
        }
        try argv.append(allocator, arg);
    }
}

fn execResolved(io: std.Io, allocator: std.mem.Allocator, tool_name: []const u8, tool_args: []const []const u8) !void {
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.append(allocator, try resolveToolPath(allocator, tool_name));
    for (tool_args) |arg| try argv.append(allocator, arg);
    try execArgv(io, argv.items);
}

fn execArgv(io: std.Io, argv: []const []const u8) !void {
    var child = std.process.spawn(io, .{
        .argv = argv,
        .stdin = .inherit,
        .stdout = .inherit,
        .stderr = .inherit,
    }) catch |err| {
        std.debug.print("rosette-shell: failed to spawn {s}: {s}\n", .{ argv[0], @errorName(err) });
        std.process.exit(127);
    };
    const term = child.wait(io) catch |err| {
        std.debug.print("rosette-shell: failed waiting for {s}: {s}\n", .{ argv[0], @errorName(err) });
        std.process.exit(127);
    };
    switch (term) {
        .exited => |code| std.process.exit(code),
        .signal => |sig| std.process.exit(128 + @as(u8, @intCast(@intFromEnum(sig)))),
        .stopped => std.process.exit(128),
        .unknown => std.process.exit(1),
    }
}

fn resolveToolPath(allocator: std.mem.Allocator, tool_name: []const u8) ![]const u8 {
    if (std.mem.indexOfScalar(u8, tool_name, '/') != null) return tool_name;
    const search_path = getenvSlice("ROSETTE_SHELL_ORIGINAL_PATH") orelse getenvSlice("PATH") orelse "";
    const wrapper_dir = getenvSlice("ROSETTE_SHELL_WRAPPER_DIR") orelse "";

    var it = std.mem.splitScalar(u8, search_path, ':');
    while (it.next()) |dir| {
        if (dir.len == 0) continue;
        if (wrapper_dir.len != 0 and std.mem.eql(u8, dir, wrapper_dir)) continue;
        const candidate = try std.fs.path.join(allocator, &.{ dir, tool_name });
        if (canExecute(allocator, candidate)) return candidate;
    }
    return tool_name;
}

fn isCxxTool(tool_name: []const u8) bool {
    return std.mem.eql(u8, tool_name, "g++") or
        std.mem.eql(u8, tool_name, "c++") or
        std.mem.eql(u8, tool_name, "clang++");
}

fn isCcTool(tool_name: []const u8) bool {
    return std.mem.eql(u8, tool_name, "gcc") or
        std.mem.eql(u8, tool_name, "cc") or
        std.mem.eql(u8, tool_name, "clang");
}

fn appendExport(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, value: []const u8) !void {
    try out.appendSlice(allocator, "export ");
    try out.appendSlice(allocator, name);
    try out.append(allocator, '=');
    try appendShellQuoted(out, allocator, value);
    try out.append(allocator, '\n');
}

fn appendShellQuoted(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    try out.append(allocator, '\'');
    for (value) |ch| {
        if (ch == '\'') {
            try out.appendSlice(allocator, "'\\''");
        } else {
            try out.append(allocator, ch);
        }
    }
    try out.append(allocator, '\'');
}

fn appendArgs(out: *std.ArrayList(u8), allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) {
        try out.appendSlice(allocator, "(default)");
        return;
    }
    for (args, 0..) |arg, i| {
        if (i != 0) try out.append(allocator, ' ');
        try appendShellQuoted(out, allocator, arg);
    }
}

fn appendInt(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u32) !void {
    const text = try std.fmt.allocPrint(allocator, "{d}", .{value});
    try out.appendSlice(allocator, text);
}

fn addSignal(signals: *std.ArrayList(u8), allocator: std.mem.Allocator, text: []const u8) !void {
    if (signals.items.len != 0) try signals.appendSlice(allocator, ",");
    try signals.appendSlice(allocator, text);
}

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;

    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        var matched = true;
        for (needle, 0..) |needle_ch, j| {
            if (std.ascii.toLower(haystack[i + j]) != std.ascii.toLower(needle_ch)) {
                matched = false;
                break;
            }
        }
        if (matched) return true;
    }
    return false;
}

fn getenvSlice(name: [:0]const u8) ?[]const u8 {
    const value = std.c.getenv(name) orelse return null;
    return std.mem.sliceTo(value, 0);
}

fn homeDir(allocator: std.mem.Allocator) ![]const u8 {
    if (getenvSlice("HOME")) |home| return try allocator.dupe(u8, home);
    return error.HomeNotSet;
}

fn absolutePath(allocator: std.mem.Allocator, raw_path: []const u8) ![]const u8 {
    const resolved = try std.fs.path.resolve(allocator, &.{raw_path});
    if (std.fs.path.isAbsolute(resolved)) return resolved;

    const cwd_buf = try allocator.alloc(u8, std.posix.PATH_MAX);
    defer allocator.free(cwd_buf);
    const cwd = std.c.realpath(".", cwd_buf.ptr) orelse return error.CwdResolveFailed;
    return try std.fs.path.resolve(allocator, &.{ std.mem.sliceTo(cwd, 0), resolved });
}

fn makePathRecursive(allocator: std.mem.Allocator, raw_path: []const u8) !void {
    if (raw_path.len == 0) return;
    var current: std.ArrayList(u8) = .empty;
    defer current.deinit(allocator);

    if (raw_path[0] == '/') try current.append(allocator, '/');
    var it = std.mem.splitScalar(u8, raw_path, '/');
    while (it.next()) |part| {
        if (part.len == 0) continue;
        if (current.items.len > 1 and current.items[current.items.len - 1] != '/') try current.append(allocator, '/');
        try current.appendSlice(allocator, part);
        const path_z = try allocator.dupeZ(u8, current.items);
        if (c.mkdir(path_z.ptr, 0o755) != 0) {
            if (c.access(path_z.ptr, 0) != 0) return error.MakePathFailed;
        }
    }
}

fn writeFilePath(allocator: std.mem.Allocator, path: []const u8, data: []const u8) !void {
    const parent = std.fs.path.dirname(path);
    if (parent) |dir| try makePathRecursive(allocator, dir);
    const path_z = try allocator.dupeZ(u8, path);
    const fp = c.fopen(path_z.ptr, "wb");
    if (fp == null) return error.FileWriteFailed;
    defer _ = c.fclose(fp);

    if (data.len != 0) {
        const wrote = c.fwrite(data.ptr, 1, data.len, fp);
        if (wrote != data.len) return error.FileWriteFailed;
    }
}

fn appendFilePath(allocator: std.mem.Allocator, path: []const u8, data: []const u8) !void {
    const parent = std.fs.path.dirname(path);
    if (parent) |dir| try makePathRecursive(allocator, dir);
    const path_z = try allocator.dupeZ(u8, path);
    const fp = c.fopen(path_z.ptr, "ab");
    if (fp == null) return error.FileWriteFailed;
    defer _ = c.fclose(fp);

    if (data.len != 0) {
        const wrote = c.fwrite(data.ptr, 1, data.len, fp);
        if (wrote != data.len) return error.FileWriteFailed;
    }
}

fn chmodPath(allocator: std.mem.Allocator, path: []const u8, mode: u16) !void {
    const path_z = try allocator.dupeZ(u8, path);
    if (c.chmod(path_z.ptr, mode) != 0) return error.ChmodFailed;
}

fn unlinkIfExists(allocator: std.mem.Allocator, path: []const u8) !void {
    const path_z = try allocator.dupeZ(u8, path);
    if (c.unlink(path_z.ptr) != 0 and c.access(path_z.ptr, 0) == 0) return error.UnlinkFailed;
}

fn rmdirIfEmpty(allocator: std.mem.Allocator, path: []const u8) !void {
    const path_z = try allocator.dupeZ(u8, path);
    if (c.rmdir(path_z.ptr) != 0 and c.access(path_z.ptr, 0) == 0) return error.RmdirFailed;
}

fn fileExists(allocator: std.mem.Allocator, path: []const u8) bool {
    const path_z = allocator.dupeZ(u8, path) catch return false;
    return c.access(path_z.ptr, 0) == 0;
}

fn canExecute(allocator: std.mem.Allocator, path: []const u8) bool {
    const path_z = allocator.dupeZ(u8, path) catch return false;
    return c.access(path_z.ptr, 1) == 0;
}
