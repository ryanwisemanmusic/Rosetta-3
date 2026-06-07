const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bundle_step = b.step("bundle", "Build Rosette.app bundle");
    const check_step = b.step("check", "Check Rosette app sources");

    const app_name = "Rosette";

    // Lightweight macOS launcher binary
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "rosette",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    {
        const exe_test = b.addTest(.{ .root_module = exe_mod });
        check_step.dependOn(&exe_test.step);
    }

    // Info.plist
    const plist_install = b.addInstallFile(
        b.path("Info.plist"),
        b.fmt("{s}.app/Contents/Info.plist", .{app_name}),
    );
    bundle_step.dependOn(&plist_install.step);

    // Binary inside the bundle
    const bin_install = b.addInstallFileWithDir(
        exe.getEmittedBin(),
        .{ .custom = b.fmt("{s}.app/Contents/MacOS", .{app_name}) },
        "rosette",
    );
    bin_install.step.dependOn(&exe.step);
    bundle_step.dependOn(&bin_install.step);

    // PkgInfo (required by macOS for .app bundles)
    const pkg_info_content = "APPL????";
    const write_pkg_info = b.addWriteFiles();
    _ = write_pkg_info.add("PkgInfo", pkg_info_content);
    const pkg_info_install = b.addInstallFileWithDir(
        write_pkg_info.getDirectory(),
        .{ .custom = b.fmt("{s}.app/Contents", .{app_name}) },
        "PkgInfo",
    );
    bundle_step.dependOn(&pkg_info_install.step);
}
