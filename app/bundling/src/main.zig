const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len > 1 and std.mem.eql(u8, args[1], "--install")) {
        try runInstaller(init.io, allocator);
        return;
    }
    if (args.len > 1 and std.mem.eql(u8, args[1], "--uninstall")) {
        try runUninstaller(init.io);
        return;
    }
    if (args.len > 1 and std.mem.eql(u8, args[1], "--register")) {
        try runCmd(init.io, &[_][]const u8{
            "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
            "-f",
            "/Applications/Rosette.app",
        });
        return;
    }

    std.debug.print(
        \\Rosette — x86/x64/DOS → ARM64 NEON translator
        \\
        \\Usage:
        \\  Rosette.app/Contents/MacOS/rosette --install     Install Rosette system-wide
        \\  Rosette.app/Contents/MacOS/rosette --uninstall   Remove Rosette from system
        \\  Rosette.app/Contents/MacOS/rosette --register    Re-register with LaunchServices
        \\
        \\To translate an executable, use the CLI:
        \\  rosette <program.exe> [trace.log]
        \\
    , .{});
}

fn runInstaller(io: std.Io, allocator: std.mem.Allocator) !void {
    const self_path = try std.process.executablePathAlloc(io, allocator);
    defer allocator.free(self_path);

    const app_bundle = self_path[0 .. self_path.len - "Contents/MacOS/rosette".len];

    std.debug.print("Installing Rosette to /Applications ...\n", .{});
    try runCmd(io, &[_][]const u8{ "cp", "-R", app_bundle, "/Applications/" });

    try runCmd(io, &[_][]const u8{
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
        "-f",
        "/Applications/Rosette.app",
    });
    std.debug.print("Rosette installed.\n", .{});
}

fn runUninstaller(io: std.Io) !void {
    std.debug.print("Removing Rosette from /Applications ...\n", .{});
    try runCmd(io, &[_][]const u8{ "rm", "-rf", "/Applications/Rosette.app" });
    try runCmd(io, &[_][]const u8{
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
        "-u",
        "/Applications/Rosette.app",
    });

    const home = std.c.getenv("HOME") orelse "/tmp";
    var buf: [512]u8 = undefined;
    const agent_path = try std.fmt.bufPrint(&buf, "{s}/Library/LaunchAgents/com.rosette.translator.plist", .{home});
    try runCmd(io, &[_][]const u8{ "rm", "-f", agent_path });

    std.debug.print("Rosette uninstalled.\n", .{});
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
