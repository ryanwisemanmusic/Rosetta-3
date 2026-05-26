const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const is_macos = target.result.os.tag == .macos;
    const root_header = if (is_macos)
        b.path("include/shims/macos/win32/windows_base.h")
    else
        b.path("include/shims/win32/win32/windows_base.h");

    const translate_windows_base = b.addTranslateC(.{
        .root_source_file = root_header,
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_windows_base.addIncludePath(b.path("include/shims/macos"));
    translate_windows_base.addIncludePath(b.path("include/shims/win32"));
    translate_windows_base.addIncludePath(b.path("include"));

    const windows_base_module = b.addModule("windows_base", .{
        .root_source_file = translate_windows_base.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const translate_sysdefs = b.addTranslateC(.{
        .root_source_file = b.path("include/win32/Zig/sys_defines_bridge.h"),
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_sysdefs.addIncludePath(b.path("include/shims/macos"));
    translate_sysdefs.addIncludePath(b.path("include/shims/win32"));
    translate_sysdefs.addIncludePath(b.path("include"));

    const sysdefs_module = b.addModule("win32_sysdefs", .{
        .root_source_file = translate_sysdefs.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const zig_module = b.createModule(.{
        .root_source_file = b.path("include/win32/Zig/var_sizes.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (is_macos) zig_module.addIncludePath(b.path("include/shims/macos"));
    zig_module.addIncludePath(b.path("include/shims/win32"));
    zig_module.addIncludePath(b.path("include"));
    zig_module.addImport("windows_base", windows_base_module);
    zig_module.addImport("win32_sysdefs", sysdefs_module);

    const check_step = b.step("check", "Check Rosetta 3 Zig sources");
    const zig_tests = b.addTest(.{
        .root_module = zig_module,
    });
    check_step.dependOn(&zig_tests.step);

    const lib = b.addLibrary(.{
        .name = "rosetta3_zig",
        .linkage = .static,
        .root_module = zig_module,
    });
    b.installArtifact(lib);
}
