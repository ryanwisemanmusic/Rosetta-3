const std = @import("std");
const exe_runner = @import("exe_runner");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len > 1 and std.mem.eql(u8, args[1], "--open")) {
        if (args.len < 3) return usage(args[0]);
        const launch_allowed = if (args.len > 3)
            !std.mem.eql(u8, args[3], "--parse-only")
        else
            true;
        try runExecutable(init, allocator, args[2], launch_allowed);
        return;
    }
    if (args.len > 1 and std.mem.eql(u8, args[1], "--install")) {
        const destination_dir = if (args.len >= 3) args[2] else "/Applications";
        try runInstaller(init, allocator, destination_dir);
        return;
    }
    if (args.len > 1 and std.mem.eql(u8, args[1], "--uninstall")) {
        const app_path = if (args.len >= 3) args[2] else "/Applications/Rosette.app";
        try runUninstaller(init.io, app_path);
        return;
    }
    if (args.len > 1 and std.mem.eql(u8, args[1], "--register")) {
        const app_path = if (args.len >= 3) args[2] else try currentBundlePath(init, allocator);
        try registerApp(init.io, app_path);
        return;
    }
    if (args.len > 1 and std.mem.eql(u8, args[1], "--unregister")) {
        const app_path = if (args.len >= 3) args[2] else "/Applications/Rosette.app";
        try unregisterApp(init.io, app_path);
        return;
    }

    usage(args[0]);
}

fn usage(exe_name: []const u8) void {
    std.debug.print(
        \\Rosette helper
        \\
        \\Usage:
        \\  {s} --open <program.exe>
        \\  {s} --install [destination-directory]
        \\  {s} --uninstall [path-to-Rosette.app]
        \\  {s} --register [path-to-Rosette.app]
        \\  {s} --unregister [path-to-Rosette.app]
        \\
    , .{ exe_name, exe_name, exe_name, exe_name, exe_name });
}

fn runExecutable(init: std.process.Init, allocator: std.mem.Allocator, exe_path: []const u8, launch_allowed: bool) !void {
    const log_path = try defaultTraceLogPath(allocator, exe_path);
    _ = std.c.write(2, "[BOOT] rosette-cli: --open ", 27);
    _ = std.c.write(2, exe_path.ptr, exe_path.len);
    _ = std.c.write(2, "\n", 1);
    std.debug.print("Rosette intake accepted: {s}\n", .{exe_path});
    std.debug.print("trace: {s}\n", .{log_path});
    try exe_runner.core.run(init, exe_path, log_path, launch_allowed);
}

fn defaultTraceLogPath(allocator: std.mem.Allocator, exe_path: []const u8) ![:0]u8 {
    const log_text = try std.fmt.allocPrint(allocator, "{s}.trace.log", .{exe_path});
    return allocator.dupeZ(u8, log_text);
}

fn runInstaller(init: std.process.Init, allocator: std.mem.Allocator, destination_dir: []const u8) !void {
    const bundle_path = try currentBundlePath(init, allocator);
    const installed_path = try std.fs.path.join(allocator, &.{ destination_dir, "Rosette.app" });

    std.debug.print("Installing Rosette...\n", .{});
    std.debug.print("source: {s}\n", .{bundle_path});
    std.debug.print("target: {s}\n", .{installed_path});

    try runCmd(init.io, &[_][]const u8{ "rm", "-rf", installed_path });
    try runCmd(init.io, &[_][]const u8{ "cp", "-R", bundle_path, destination_dir });
    try registerApp(init.io, installed_path);

    std.debug.print("Rosette installed successfully.\n", .{});
}

fn runUninstaller(io: std.Io, app_path: []const u8) !void {
    std.debug.print("Removing Rosette from {s}\n", .{app_path});
    try unregisterApp(io, app_path);
    try runCmd(io, &[_][]const u8{ "rm", "-rf", app_path });
    try removeLaunchAgent(io);
    std.debug.print("Rosette uninstalled successfully.\n", .{});
}

fn currentBundlePath(init: std.process.Init, allocator: std.mem.Allocator) ![]const u8 {
    const self_path = try std.process.executablePathAlloc(init.io, allocator);
    const suffix = "Contents/MacOS/rosette-cli";
    if (std.mem.endsWith(u8, self_path, suffix)) {
        const end = self_path.len - suffix.len;
        return self_path[0..end];
    }
    return "/Applications/Rosette.app";
}

fn registerApp(io: std.Io, app_path: []const u8) !void {
    try runCmd(io, &[_][]const u8{
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
        "-f",
        app_path,
    });
}

fn unregisterApp(io: std.Io, app_path: []const u8) !void {
    try runCmd(io, &[_][]const u8{
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
        "-u",
        app_path,
    });
}

fn removeLaunchAgent(io: std.Io) !void {
    const home = std.c.getenv("HOME") orelse return;
    var buf: [512]u8 = undefined;
    const agent_path = try std.fmt.bufPrint(&buf, "{s}/Library/LaunchAgents/com.rosette.translator.plist", .{home});
    try runCmd(io, &[_][]const u8{ "rm", "-f", agent_path });
}

fn runCmd(io: std.Io, argv: []const []const u8) !void {
    var child = try std.process.spawn(io, .{
        .argv = argv,
        .stdout = .inherit,
        .stderr = .inherit,
    });
    const term = try child.wait(io);
    _ = term;
}

test "default trace path follows executable path" {
    const log_path = try defaultTraceLogPath(std.testing.allocator, "assets/exe_examples/Console-Tetris.exe");
    defer std.testing.allocator.free(log_path);
    try std.testing.expectEqualStrings("assets/exe_examples/Console-Tetris.exe.trace.log", log_path);
}
