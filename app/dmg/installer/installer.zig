const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len < 2) {
        std.debug.print(
            \\Rosette DMG Installer
            \\
            \\Usage:
            \\  installer <path-to-Rosette.app>   Create Rosette.dmg and install
            \\  installer --make-dmg <source>      Create Rosette.dmg only
            \\
        , .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "--make-dmg")) {
        if (args.len < 3) {
            std.debug.print("Usage: installer --make-dmg <source-folder>\n", .{});
            return;
        }
        try createDMG(init.io, args[2]);
        std.debug.print("Created Rosette.dmg\n", .{});
        return;
    }

    const app_path = args[1];

    std.debug.print("=== Rosette Installer ===\n\n", .{});

    std.debug.print("[1/3] Creating Rosette.dmg ...\n", .{});
    try createDMG(init.io, app_path);

    std.debug.print("[2/3] Opening DMG ...\n", .{});
    try runCmd(init.io, &[_][]const u8{ "open", "Rosette.dmg" });

    std.debug.print("[3/3] Installing Rosette to /Applications ...\n", .{});
    std.debug.print("Drag Rosette.app into /Applications in the Finder window.\n", .{});
    try runCmd(init.io, &[_][]const u8{
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
        "-f",
        "/Applications/Rosette.app",
    });

    std.debug.print(
        \\
        \\Next steps:
        \\  1. Drag Rosette.app into /Applications (in the opened Finder window)
        \\  2. Right-click any .exe → Get Info → Open with → Rosette
        \\
    , .{});
}

fn createDMG(io: std.Io, source_path: []const u8) !void {
    const temp_dmg = "Rosette-tmp.dmg";
    const dmg_path = "Rosette.dmg";

    runCmd(io, &[_][]const u8{ "rm", "-f", temp_dmg, dmg_path }) catch {};

    try runCmd(io, &[_][]const u8{
        "hdiutil",    "create",
        "-srcfolder", source_path,
        "-volname",   "Rosette",
        "-fs",        "HFS+",
        "-format",    "UDRW",
        temp_dmg,
    });

    try runCmd(io, &[_][]const u8{
        "hdiutil", "convert", temp_dmg,
        "-format", "UDZO",    "-o",
        dmg_path,
    });

    runCmd(io, &[_][]const u8{ "rm", "-f", temp_dmg }) catch {};
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
