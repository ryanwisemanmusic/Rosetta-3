const std = @import("std");

pub fn locateAssemblySource(allocator: std.mem.Allocator, io: std.Io, argv0: []const u8) ![]u8 {
    const abs_argv0 = try std.fs.path.resolve(allocator, &.{argv0});
    defer allocator.free(abs_argv0);
    const suite_dir = std.fs.path.dirname(abs_argv0) orelse "/";

    const explicit = try readSuiteCfgSourcePath(allocator, io, suite_dir);
    if (explicit) |path| return path;

    return error.NoAssemblySourceFound;
}

fn readSuiteCfgSourcePath(allocator: std.mem.Allocator, io: std.Io, suite_dir: []const u8) !?[]u8 {
    const cfg_path = try std.fs.path.resolve(allocator, &.{ suite_dir, "suite.cfg" });
    defer allocator.free(cfg_path);

    std.Io.Dir.cwd().access(io, cfg_path, .{}) catch return null;

    const cwd = std.Io.Dir.cwd();
    const contents = try cwd.readFileAlloc(io, cfg_path, allocator, .limited(64 * 1024));
    defer allocator.free(contents);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (!std.mem.startsWith(u8, line, "ASM_SOURCE=")) continue;
        const rel = line["ASM_SOURCE=".len..];
        return try std.fs.path.resolve(allocator, &.{ suite_dir, rel });
    }
    return null;
}
