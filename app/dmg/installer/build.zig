const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("installer.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "rosette-installer",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const check_step = b.step("check", "Check installer sources");
    const exe_test = b.addTest(.{ .root_module = exe_mod });
    check_step.dependOn(&exe_test.step);
}
