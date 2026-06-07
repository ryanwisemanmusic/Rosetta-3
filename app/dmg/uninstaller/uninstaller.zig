const std = @import("std");

pub fn main(init: std.process.Init) !void {
    std.debug.print("=== Rosette Uninstaller ===\n\n", .{});

    try runCmd(init.io, &[_][]const u8{
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
        "-u",
        "/Applications/Rosette.app",
    });

    try runCmd(init.io, &[_][]const u8{ "rm", "-rf", "/Applications/Rosette.app" });

    const home = std.c.getenv("HOME") orelse "/tmp";
    var buf: [512]u8 = undefined;
    const agent_path = try std.fmt.bufPrint(&buf, "{s}/Library/LaunchAgents/com.rosette.translator.plist", .{home});
    try runCmd(init.io, &[_][]const u8{ "rm", "-f", agent_path });

    try runCmd(init.io, &[_][]const u8{ "rm", "-f", "/tmp/Rosette.dmg", "/tmp/Rosette-tmp.dmg" });

    std.debug.print(
        \\
        \\Rosette has been removed from your system.
        \\
    , .{});
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
