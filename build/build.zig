const std = @import("std");
const builtin = @import("builtin");

/// Reference-only headers (upstream win32, thr, winsdk). Not part of the public API.
const reference_include = "../.rosetta3/include";

pub fn build(b: *std.Build) void {
    var target_query = b.standardTargetOptionsQueryOnly(.{});
    const host_os = target_query.os_tag orelse builtin.target.os.tag;
    if (host_os == .macos) {
        const deployment: std.SemanticVersion = .{ .major = 13, .minor = 0, .patch = 0 };
        target_query.os_tag = .macos;
        target_query.os_version_min = .{ .semver = deployment };
        target_query.os_version_max = .{ .semver = deployment };
    }
    const target = b.resolveTargetQuery(target_query);
    const optimize = b.standardOptimizeOption(.{});

    const is_macos = target.result.os.tag == .macos;
    const root_header = if (is_macos)
        b.path("../include/shims/macos/win32/windows_base.h")
    else
        b.path("../include/shims/win32/win32/windows_base.h");

    const translate_windows_base = b.addTranslateC(.{
        .root_source_file = root_header,
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_windows_base.addIncludePath(b.path("../include/shims/macos"));
    translate_windows_base.addIncludePath(b.path("../include/shims/win32"));
    translate_windows_base.addIncludePath(b.path("../include"));

    const windows_base_module = b.addModule("windows_base", .{
        .root_source_file = translate_windows_base.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const translate_sysdefs = b.addTranslateC(.{
        .root_source_file = b.path("../include/win32/Zig/sys_defines_bridge.h"),
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_sysdefs.addIncludePath(b.path("../include/shims/macos"));
    translate_sysdefs.addIncludePath(b.path("../include/shims/win32"));
    translate_sysdefs.addIncludePath(b.path("../include"));
    translate_sysdefs.addIncludePath(b.path(reference_include));

    const sysdefs_module = b.addModule("win32_sysdefs", .{
        .root_source_file = translate_sysdefs.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const translate_win32 = b.addTranslateC(.{
        .root_source_file = b.path("../include/win32/Zig/win32_bridge.h"),
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_win32.addIncludePath(b.path("../include/shims/macos"));
    translate_win32.addIncludePath(b.path("../include/shims/win32"));
    translate_win32.addIncludePath(b.path("../include"));
    translate_win32.addIncludePath(b.path(reference_include));

    const win32_all_module = b.addModule("win32_all", .{
        .root_source_file = translate_win32.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const translate_behavior = b.addTranslateC(.{
        .root_source_file = b.path("../include/win32/Zig/behavior_bridge.h"),
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_behavior.addIncludePath(b.path("../include/shims/macos"));
    translate_behavior.addIncludePath(b.path("../include/shims/win32"));
    translate_behavior.addIncludePath(b.path("../include"));
    translate_behavior.addIncludePath(b.path(reference_include));

    const behavior_module = b.addModule("behavior_api", .{
        .root_source_file = translate_behavior.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const translate_mmsystem = b.addTranslateC(.{
        .root_source_file = b.path("../include/win32/Zig/mmsystem_bridge.h"),
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_mmsystem.addIncludePath(b.path("../include/shims/macos"));
    translate_mmsystem.addIncludePath(b.path("../include/shims/win32"));
    translate_mmsystem.addIncludePath(b.path("../include"));

    const mmsystem_module = b.addModule("win32_mmsystem", .{
        .root_source_file = translate_mmsystem.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const translate_shim_surface = b.addTranslateC(.{
        .root_source_file = b.path("../include/win32/Zig/shim_surface_bridge.h"),
        .target = target,
        .optimize = optimize,
    });
    if (is_macos) translate_shim_surface.addIncludePath(b.path("../include/shims/macos"));
    translate_shim_surface.addIncludePath(b.path("../include/shims/win32"));
    translate_shim_surface.addIncludePath(b.path("../include"));
    translate_shim_surface.addIncludePath(b.path(reference_include));

    const shim_surface_module = b.addModule("win32_shim_surface", .{
        .root_source_file = translate_shim_surface.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const zig_module = b.createModule(.{
        .root_source_file = b.path("../include/win32/Zig/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const win32_pending_module = b.createModule(.{
        .root_source_file = b.path("../include/win32/Zig/win32_pending_bridge.zig"),
        .target = target,
        .optimize = optimize,
    });
    win32_pending_module.addImport("windows_base", windows_base_module);

    const behavior_zig_module = b.createModule(.{
        .root_source_file = b.path("../include/win32/Zig/behavior.zig"),
        .target = target,
        .optimize = optimize,
    });
    behavior_zig_module.addImport("behavior_api", behavior_module);
    if (is_macos) behavior_zig_module.addIncludePath(b.path("../include/shims/macos"));
    behavior_zig_module.addIncludePath(b.path("../include/shims/win32"));
    behavior_zig_module.addIncludePath(b.path("../include"));

    const x86_asm_module = b.createModule(.{
        .root_source_file = b.path("../src/x86-ASM/title_entries.zig"),
        .target = target,
        .optimize = optimize,
    });
    const runtime_abi_module = b.createModule(.{
        .root_source_file = b.path("../runtime-abi-handshake/runtime.zig"),
        .target = target,
        .optimize = optimize,
    });

    const dos_scene_module = b.createModule(.{
        .root_source_file = b.path("../src/DOS/graphics/scene.zig"),
        .target = target,
        .optimize = optimize,
    });
    const dos_palette_module = b.createModule(.{
        .root_source_file = b.path("../src/DOS/graphics/palette.zig"),
        .target = target,
        .optimize = optimize,
    });
    const dos_renderer_module = b.createModule(.{
        .root_source_file = b.path("../src/DOS/graphics/renderer.zig"),
        .target = target,
        .optimize = optimize,
    });
    const dos_platform_module = b.createModule(.{
        .root_source_file = b.path("../src/DOS/platform.zig"),
        .target = target,
        .optimize = optimize,
    });

    x86_asm_module.addImport("dos_scene", dos_scene_module);
    x86_asm_module.addImport("dos_palette", dos_palette_module);
    x86_asm_module.addImport("dos_renderer", dos_renderer_module);
    x86_asm_module.addImport("dos_platform", dos_platform_module);
    x86_asm_module.addImport("runtime_abi_handshake", runtime_abi_module);
    dos_scene_module.addImport("runtime_abi_handshake", runtime_abi_module);

    if (is_macos) zig_module.addIncludePath(b.path("../include/shims/macos"));
    zig_module.addIncludePath(b.path("../include/shims/win32"));
    zig_module.addIncludePath(b.path("../include"));
    zig_module.addImport("windows_base", windows_base_module);
    zig_module.addImport("win32_sysdefs", sysdefs_module);
    zig_module.addImport("win32_all", win32_all_module);
    zig_module.addImport("win32_pending", win32_pending_module);
    zig_module.addImport("win32_mmsystem", mmsystem_module);
    zig_module.addImport("win32_shim_surface", shim_surface_module);
    zig_module.addImport("behavior_api", behavior_module);
    zig_module.addImport("behavior", behavior_zig_module);
    zig_module.addImport("x86_asm", x86_asm_module);
    zig_module.addImport("runtime_abi_handshake", runtime_abi_module);
    zig_module.addImport("dos_scene", dos_scene_module);
    zig_module.addImport("dos_palette", dos_palette_module);
    zig_module.addImport("dos_renderer", dos_renderer_module);
    zig_module.addImport("dos_platform", dos_platform_module);

    const check_step = b.step("check", "Check Rosetta 3 Zig sources");

    const zig_tests = b.addTest(.{
        .root_module = zig_module,
    });
    check_step.dependOn(&zig_tests.step);

    const third_party_test_files = [_][]const u8{
        "crypto/sha.zig",
        "crypto/des.zig",
        "crypto/rijndael.zig",
        "dxbc/dxbc_checksum.zig",
        "endianness/endianness.zig",
        "fxaa/fxaa.zig",
        "half/half.zig",
        "renderdoc/renderdoc.zig",
        "avx_to_neon/avx_to_neon.zig",
        "llvm/llvm.zig",
        "microprofile/microprofile.zig",
        "mspack/mspack.zig",
        "stb/stb.zig",
    };
    inline for (third_party_test_files) |rel_path| {
        const tp_mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("../third_party/{s}", .{rel_path})),
            .target = target,
            .optimize = optimize,
        });
        if (is_macos) tp_mod.addIncludePath(b.path("../include/shims/macos"));
        tp_mod.addIncludePath(b.path("../include/shims/win32"));
        tp_mod.addIncludePath(b.path("../include"));
        const tp_test = b.addTest(.{ .root_module = tp_mod });
        check_step.dependOn(&tp_test.step);
    }

    // Graphics ABI validation tests
    {
        const gfx_abi_mod = b.createModule(.{
            .root_source_file = b.path("../src/x86-ASM/graphics/abi.zig"),
            .target = target,
            .optimize = optimize,
        });
        gfx_abi_mod.addImport("runtime_abi_handshake", runtime_abi_module);
        const gfx_abi_test = b.addTest(.{ .root_module = gfx_abi_mod });
        check_step.dependOn(&gfx_abi_test.step);
    }

    {
        const runtime_abi_test = b.addTest(.{ .root_module = runtime_abi_module });
        check_step.dependOn(&runtime_abi_test.step);
    }

    {
        const dos_exec_mod = b.createModule(.{
            .root_source_file = b.path("../src/DOS/execution/session.zig"),
            .target = target,
            .optimize = optimize,
        });
        dos_exec_mod.addImport("runtime_abi_handshake", runtime_abi_module);
        const dos_exec_test = b.addTest(.{ .root_module = dos_exec_mod });
        check_step.dependOn(&dos_exec_test.step);
    }

    {
        const x64_state_mod = b.createModule(.{
            .root_source_file = b.path("../src/x64-ASM/x64_state.zig"),
            .target = target,
            .optimize = optimize,
        });
        x64_state_mod.addImport("runtime_abi_handshake", runtime_abi_module);
        const x64_state_test = b.addTest(.{ .root_module = x64_state_mod });
        check_step.dependOn(&x64_state_test.step);
    }

    {
        const x64_addr_mod = b.createModule(.{
            .root_source_file = b.path("../src/x64-ASM/addressing64.zig"),
            .target = target,
            .optimize = optimize,
        });
        x64_addr_mod.addImport("runtime_abi_handshake", runtime_abi_module);
        const x64_addr_test = b.addTest(.{ .root_module = x64_addr_mod });
        check_step.dependOn(&x64_addr_test.step);
    }

    // Aggregate Win32 ABI handshake suite
    {
        const abi_suite_mod = b.createModule(.{
            .root_source_file = b.path("../include/win32/Zig/abi_suite.zig"),
            .target = target,
            .optimize = optimize,
        });
        if (is_macos) abi_suite_mod.addIncludePath(b.path("../include/shims/macos"));
        abi_suite_mod.addIncludePath(b.path("../include/shims/win32"));
        abi_suite_mod.addIncludePath(b.path("../include"));
        abi_suite_mod.addImport("windows_base", windows_base_module);
        abi_suite_mod.addImport("win32_sysdefs", sysdefs_module);
        abi_suite_mod.addImport("win32_all", win32_all_module);
        abi_suite_mod.addImport("win32_pending", win32_pending_module);
        abi_suite_mod.addImport("win32_mmsystem", mmsystem_module);
        abi_suite_mod.addImport("win32_shim_surface", shim_surface_module);
        abi_suite_mod.addImport("behavior_api", behavior_module);
        abi_suite_mod.addImport("behavior", behavior_zig_module);
        abi_suite_mod.addImport("x86_asm", x86_asm_module);
        abi_suite_mod.addImport("runtime_abi_handshake", runtime_abi_module);
        abi_suite_mod.addImport("dos_scene", dos_scene_module);
        abi_suite_mod.addImport("dos_palette", dos_palette_module);
        abi_suite_mod.addImport("dos_renderer", dos_renderer_module);
        abi_suite_mod.addImport("dos_platform", dos_platform_module);
        const abi_suite_test = b.addTest(.{ .root_module = abi_suite_mod });
        check_step.dependOn(&abi_suite_test.step);
    }

    const lib = b.addLibrary(.{
        .name = "rosetta3_zig",
        .linkage = .static,
        .root_module = zig_module,
    });
    b.installArtifact(lib);
}
