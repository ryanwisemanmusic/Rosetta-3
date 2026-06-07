const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const payload_app = b.option([]const u8, "payload-app", "Path to the Rosette.app payload");

    const app_name = "Rosette Installer";
    const bundle_step = b.step("bundle", "Build Rosette Installer.app");
    const check_step = b.step("check", "Check installer sources");

    const helper_mod = b.createModule(.{
        .root_source_file = b.path("installer.zig"),
        .target = target,
        .optimize = optimize,
    });
    const helper = b.addExecutable(.{
        .name = "rosette-install-helper",
        .root_module = helper_mod,
    });
    b.installArtifact(helper);

    const helper_test = b.addTest(.{ .root_module = helper_mod });
    check_step.dependOn(&helper_test.step);

    const app_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    app_mod.addCSourceFile(.{
        .file = b.path("src/InstallerApp.m"),
        .flags = &.{ "-fobjc-arc", "-Wall", "-Wextra" },
    });
    app_mod.linkFramework("Cocoa", .{});

    const app_exe = b.addExecutable(.{
        .name = "rosette-installer",
        .root_module = app_mod,
    });
    b.installArtifact(app_exe);
    check_step.dependOn(&app_exe.step);

    const plist_install = b.addInstallFile(
        b.path("Info.plist"),
        b.fmt("{s}.app/Contents/Info.plist", .{app_name}),
    );
    bundle_step.dependOn(&plist_install.step);

    const app_bin_install = b.addInstallFileWithDir(
        app_exe.getEmittedBin(),
        .{ .custom = b.fmt("{s}.app/Contents/MacOS", .{app_name}) },
        "rosette-installer",
    );
    app_bin_install.step.dependOn(&app_exe.step);
    bundle_step.dependOn(&app_bin_install.step);

    const helper_install = b.addInstallFileWithDir(
        helper.getEmittedBin(),
        .{ .custom = b.fmt("{s}.app/Contents/MacOS", .{app_name}) },
        "rosette-install-helper",
    );
    helper_install.step.dependOn(&helper.step);
    bundle_step.dependOn(&helper_install.step);

    if (payload_app) |path| {
        const payload_install = b.addInstallDirectory(.{
            .source_dir = .{ .cwd_relative = path },
            .install_dir = .prefix,
            .install_subdir = b.fmt("{s}.app/Contents/Resources/Rosette.app", .{app_name}),
        });
        bundle_step.dependOn(&payload_install.step);
    }

    const write_pkg_info = b.addWriteFiles();
    _ = write_pkg_info.add("PkgInfo", "APPL????");
    const pkg_info_install = b.addInstallFileWithDir(
        write_pkg_info.getDirectory(),
        .{ .custom = b.fmt("{s}.app/Contents", .{app_name}) },
        "PkgInfo",
    );
    bundle_step.dependOn(&pkg_info_install.step);
}
