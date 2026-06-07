const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len >= 2 and std.mem.eql(u8, args[1], "--install")) {
        if (args.len < 4) return usage(args[0]);
        try installApp(init.io, allocator, args[2], args[3]);
        return;
    }

    if (args.len >= 2 and std.mem.eql(u8, args[1], "--register")) {
        if (args.len < 3) return usage(args[0]);
        try registerApp(init.io, args[2]);
        return;
    }

    usage(args[0]);
}

fn usage(exe_name: []const u8) void {
    std.debug.print(
        \\Rosette installer helper
        \\
        \\Usage:
        \\  {s} --install <payload-Rosette.app> <destination-directory>
        \\  {s} --register <installed-Rosette.app>
        \\
    , .{ exe_name, exe_name });
}

fn installApp(io: std.Io, allocator: std.mem.Allocator, payload_app: []const u8, destination_dir: []const u8) !void {
    const target_app = try std.fs.path.join(allocator, &.{ destination_dir, "Rosette.app" });

    std.debug.print("Preparing destination: {s}\n", .{destination_dir});
    try runCmd(io, &[_][]const u8{ "mkdir", "-p", destination_dir });

    std.debug.print("Removing old copy, if present: {s}\n", .{target_app});
    try runCmd(io, &[_][]const u8{ "rm", "-rf", target_app });

    std.debug.print("Copying Rosette.app...\n", .{});
    try runCmd(io, &[_][]const u8{ "cp", "-R", payload_app, destination_dir });

    std.debug.print("Registering file associations...\n", .{});
    try registerApp(io, target_app);

    std.debug.print("Installation complete: {s}\n", .{target_app});
}

fn registerApp(io: std.Io, app_path: []const u8) !void {
    try runCmd(io, &[_][]const u8{
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
        "-f",
        app_path,
    });
}

fn runCmd(io: std.Io, argv: []const []const u8) !void {
    var child = try std.process.spawn(io, .{
        .argv = argv,
        .stdout = .inherit,
        .stderr = .inherit,
    });
    const term = try child.wait(io);
    switch (term) {
        .exited => |code| if (code != 0) return error.CommandFailed,
        else => return error.CommandFailed,
    }
}
