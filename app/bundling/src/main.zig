const std = @import("std");
const pe_parser = @import("pe_parser");

const machine_i386: u16 = 0x014c;
const machine_amd64: u16 = 0x8664;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len > 1 and std.mem.eql(u8, args[1], "--open")) {
        if (args.len < 3) return usage(args[0]);
        try inspectExecutable(init, allocator, args[2]);
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

fn inspectExecutable(init: std.process.Init, allocator: std.mem.Allocator, exe_path: []const u8) !void {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, exe_path, allocator, .limited(128 * 1024 * 1024));
    const image = try pe_parser.parse(allocator, bytes);
    defer allocator.free(image.sections);

    std.debug.print("Rosette intake accepted: {s}\n", .{exe_path});
    std.debug.print("machine: {s} (0x{x:0>4})\n", .{ machineName(image.machine), image.machine });
    std.debug.print("entry RVA: 0x{x:0>8}\n", .{image.entry_rva});
    std.debug.print("image base: 0x{x}\n", .{image.image_base});
    std.debug.print("sections: {d}\n", .{image.number_of_sections});

    for (image.sections, 0..) |section, index| {
        const raw_name = std.mem.sliceTo(&section.name, 0);
        const name = if (raw_name.len == 0) "<unnamed>" else raw_name;
        std.debug.print(
            "  [{d}] {s} va=0x{x:0>8} raw=0x{x:0>8}\n",
            .{ index, name, section.virtual_address, section.raw_size },
        );
    }

    std.debug.print("status: parsed; execution will route through the Rosette translator when this PE target is supported.\n", .{});
}

fn machineName(machine: u16) []const u8 {
    return switch (machine) {
        machine_i386 => "i386",
        machine_amd64 => "amd64",
        else => "unknown",
    };
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

test "machine names cover PE targets used by Rosette intake" {
    try std.testing.expectEqualStrings("i386", machineName(machine_i386));
    try std.testing.expectEqualStrings("amd64", machineName(machine_amd64));
}
