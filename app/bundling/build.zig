const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bundle_step = b.step("bundle", "Build Rosette.app bundle");
    const check_step = b.step("check", "Check Rosette app sources");

    const app_name = "Rosette";

    // Zig helper for command-line work from the Cocoa app.
    const helper_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const pe_parser_mod = b.createModule(.{
        .root_source_file = b.path("../../src/tooling/exe_parser/pe_parser.zig"),
        .target = target,
        .optimize = optimize,
    });
    helper_mod.addImport("pe_parser", pe_parser_mod);
    const helper = b.addExecutable(.{
        .name = "rosette-cli",
        .root_module = helper_mod,
    });
    b.installArtifact(helper);

    {
        const helper_test = b.addTest(.{ .root_module = helper_mod });
        check_step.dependOn(&helper_test.step);
    }

    // Native Cocoa shell launched by Finder.
    const app_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    app_mod.addCSourceFile(.{
        .file = b.path("src/RosetteApp.m"),
        .flags = &.{ "-fobjc-arc", "-Wall", "-Wextra" },
    });
    app_mod.linkFramework("Cocoa", .{});

    const app_exe = b.addExecutable(.{
        .name = "rosette",
        .root_module = app_mod,
    });
    b.installArtifact(app_exe);

    // Info.plist
    const plist_install = b.addInstallFile(
        b.path("Info.plist"),
        b.fmt("{s}.app/Contents/Info.plist", .{app_name}),
    );
    bundle_step.dependOn(&plist_install.step);

    // Binary inside the bundle
    const bin_install = b.addInstallFileWithDir(
        app_exe.getEmittedBin(),
        .{ .custom = b.fmt("{s}.app/Contents/MacOS", .{app_name}) },
        "rosette",
    );
    bin_install.step.dependOn(&app_exe.step);
    bundle_step.dependOn(&bin_install.step);

    const helper_install = b.addInstallFileWithDir(
        helper.getEmittedBin(),
        .{ .custom = b.fmt("{s}.app/Contents/MacOS", .{app_name}) },
        "rosette-cli",
    );
    helper_install.step.dependOn(&helper.step);
    bundle_step.dependOn(&helper_install.step);

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
