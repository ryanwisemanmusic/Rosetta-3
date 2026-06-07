const std = @import("std");
const macho = @import("macho_parser.zig");

pub const LaunchStrategy = enum {
    direct_native,
    codesign_then_launch,
    rosette_thunk,
    unsupported_architecture,
};

pub const LaunchDiagnostic = struct {
    strategy: LaunchStrategy,
    can_launch: bool,
    architecture: []const u8,
    machine_readable: bool,
    reason: []const u8,
    suggestion: []const u8,
};

pub const LaunchAttempt = struct {
    success: bool,
    pid: ?u32,
    diagnostics: LaunchDiagnostic,
};

pub const AppLauncher = struct {
    app_path: []const u8,
    executable_path: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, app_path: []const u8, executable_path: []const u8) AppLauncher {
        return .{
            .app_path = app_path,
            .executable_path = executable_path,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *AppLauncher) void {
        self.allocator.free(self.app_path);
        self.allocator.free(self.executable_path);
    }

    pub fn diagnoseExecutable(self: AppLauncher) !LaunchDiagnostic {
        const file = std.fs.cwd().openFile(self.executable_path, .{}) catch |err| {
            return LaunchDiagnostic{
                .strategy = .unsupported_architecture,
                .can_launch = false,
                .architecture = "unknown",
                .machine_readable = false,
                .reason = try std.fmt.allocPrint(self.allocator, "cannot open executable: {s}", .{@errorName(err)}),
                .suggestion = "verify the app bundle is intact",
            };
        };
        defer file.close();

        const data = try file.readToEndAlloc(self.allocator, std.math.maxInt(u32));
        defer self.allocator.free(data);

        return diagnoseMachO(data);
    }

    pub fn launchDirect(self: AppLauncher) !LaunchAttempt {
        const diagnostic = try self.diagnoseExecutable();
        if (!diagnostic.can_launch) {
            return LaunchAttempt{
                .success = false,
                .pid = null,
                .diagnostics = diagnostic,
            };
        }

        var child = std.process.Child.init(&.{ "/usr/bin/open", self.app_path }, self.allocator);
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        try child.spawn();
        const term = try child.wait();

        const success = term.Exited == 0;
        return LaunchAttempt{
            .success = success,
            .pid = child.id,
            .diagnostics = diagnostic,
        };
    }

    pub fn codesignAndLaunch(self: AppLauncher) !LaunchAttempt {
        const diagnostic = try self.diagnoseExecutable();

        const resign = std.process.Child.init(&.{ "codesign", "--force", "-s", "-", "--deep", self.app_path }, self.allocator);
        try resign.spawn();
        const resign_term = try resign.wait();
        if (resign_term.Exited != 0) {
            return LaunchAttempt{
                .success = false,
                .pid = null,
                .diagnostics = LaunchDiagnostic{
                    .strategy = .codesign_then_launch,
                    .can_launch = false,
                    .architecture = diagnostic.architecture,
                    .machine_readable = true,
                    .reason = "ad-hoc codesigning failed",
                    .suggestion = "check codesign invocation or entitlement issues",
                },
            };
        }

        var child = std.process.Child.init(&.{ "/usr/bin/open", self.app_path }, self.allocator);
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        try child.spawn();
        const term = try child.wait();

        const success = term.Exited == 0;
        return LaunchAttempt{
            .success = success,
            .pid = child.id,
            .diagnostics = LaunchDiagnostic{
                .strategy = .codesign_then_launch,
                .can_launch = success,
                .architecture = diagnostic.architecture,
                .machine_readable = true,
                .reason = if (success)
                    "launched after ad-hoc re-signing"
                else
                    "launch failed even after re-signing",
                .suggestion = if (success)
                    ""
                else
                    "the binary may be fundamentally incompatible with this system",
            },
        };
    }

    pub fn launchWithDiagnostics(self: AppLauncher) !LaunchAttempt {
        const diagnostic = try self.diagnoseExecutable();

        if (diagnostic.can_launch) {
            return try self.launchDirect();
        }

        if (diagnostic.strategy == .rosette_thunk) {
            _ = try self.codesignAndLaunch();
            return LaunchAttempt{
                .success = false,
                .pid = null,
                .diagnostics = diagnostic,
            };
        }

        if (diagnostic.strategy == .unsupported_architecture) {
            return LaunchAttempt{
                .success = false,
                .pid = null,
                .diagnostics = diagnostic,
            };
        }

        return LaunchAttempt{
            .success = false,
            .pid = null,
            .diagnostics = diagnostic,
        };
    }
};

pub fn diagnoseMachO(data: []const u8) LaunchDiagnostic {
    if (data.len < 4) {
        return LaunchDiagnostic{
            .strategy = .unsupported_architecture,
            .can_launch = false,
            .architecture = "truncated",
            .machine_readable = true,
            .reason = "executable is too small to contain a Mach-O header",
            .suggestion = "the binary appears corrupt",
        };
    }

    const magic = std.mem.readInt(u32, data[0..4], .little);

    if (magic == macho.MH_MAGIC or magic == macho.MH_CIGAM) {
        const cputype = std.mem.readInt(u32, data[4..8], .little);
        if (cputype == macho.CPU_TYPE_I386) {
            return LaunchDiagnostic{
                .strategy = .rosette_thunk,
                .can_launch = false,
                .architecture = "i386",
                .machine_readable = true,
                .reason = "32-bit Intel binary requires thunking on ARM64",
                .suggestion = "use rosette_thunk launch strategy to wrap the 32-bit binary",
            };
        }
        return LaunchDiagnostic{
            .strategy = .direct_native,
            .can_launch = true,
            .architecture = "x86_32",
            .machine_readable = true,
            .reason = "32-bit non-i386 binary",
            .suggestion = "launch directly",
        };
    }

    if (magic == macho.MH_MAGIC_64 or magic == macho.MH_CIGAM_64) {
        const cputype = std.mem.readInt(u32, data[4..8], .little);
        const arch_name = if (cputype == macho.CPU_TYPE_X86_64)
            "x86_64"
        else if (cputype == macho.CPU_TYPE_ARM64)
            "arm64"
        else
            "unknown_64";
        const known_64 = std.mem.eql(u8, arch_name, "x86_64") or std.mem.eql(u8, arch_name, "arm64");
        return LaunchDiagnostic{
            .strategy = .direct_native,
            .can_launch = known_64,
            .architecture = arch_name,
            .machine_readable = true,
            .reason = if (std.mem.eql(u8, arch_name, "arm64"))
                "native ARM64 binary"
            else if (std.mem.eql(u8, arch_name, "x86_64"))
                "x86_64 — runs under Rosetta 2"
            else
                "unknown 64-bit architecture",
            .suggestion = if (known_64)
                "launch directly"
            else
                "verify the binary architecture",
        };
    }

    const fat_magic = std.mem.readInt(u32, data[0..4], .big);
    const is_fat = fat_magic == 0xCAFEBABE or fat_magic == 0xBEBAFECA or
        fat_magic == 0xCAFEBABF or fat_magic == 0xBFBAFECA;

    if (is_fat) {
        return LaunchDiagnostic{
            .strategy = .direct_native,
            .can_launch = false,
            .architecture = "universal",
            .machine_readable = true,
            .reason = "universal binary — needs slice extraction before launch",
            .suggestion = "extract the native arm64 slice and re-sign",
        };
    }

    return LaunchDiagnostic{
        .strategy = .unsupported_architecture,
        .can_launch = false,
        .architecture = "unknown",
        .machine_readable = false,
        .reason = "unrecognised Mach-O magic — not a valid macOS binary",
        .suggestion = "verify the file is a Mach-O executable",
    };
}

test "diagnose i386 executable" {
    var hdr = macho.MachHeader32{
        .magic = macho.MH_MAGIC,
        .cputype = macho.CPU_TYPE_I386,
        .cpusubtype = 3,
        .filetype = macho.MH_EXECUTE,
        .ncmds = 0,
        .sizeofcmds = 0,
        .flags = 0,
    };
    const bytes = std.mem.asBytes(&hdr);

    const diag = diagnoseMachO(bytes);
    try std.testing.expectEqual(false, diag.can_launch);
    try std.testing.expectEqualStrings("i386", diag.architecture);
    try std.testing.expect(diag.strategy == .rosette_thunk);
}

test "diagnose x86_64 executable" {
    var hdr = macho.MachHeader64{
        .magic = macho.MH_MAGIC_64,
        .cputype = macho.CPU_TYPE_X86_64,
        .cpusubtype = 3,
        .filetype = macho.MH_EXECUTE,
        .ncmds = 0,
        .sizeofcmds = 0,
        .flags = 0,
        .reserved = 0,
    };
    const bytes = std.mem.asBytes(&hdr);

    const diag = diagnoseMachO(bytes);
    try std.testing.expect(diag.can_launch);
    try std.testing.expectEqualStrings("x86_64", diag.architecture);
    try std.testing.expect(diag.strategy == .direct_native);
}

test "diagnose arm64 executable" {
    var hdr = macho.MachHeader64{
        .magic = macho.MH_MAGIC_64,
        .cputype = macho.CPU_TYPE_ARM64,
        .cpusubtype = 3,
        .filetype = macho.MH_EXECUTE,
        .ncmds = 0,
        .sizeofcmds = 0,
        .flags = 0,
        .reserved = 0,
    };
    const bytes = std.mem.asBytes(&hdr);

    const diag = diagnoseMachO(bytes);
    try std.testing.expect(diag.can_launch);
    try std.testing.expectEqualStrings("arm64", diag.architecture);
    try std.testing.expect(diag.strategy == .direct_native);
}

test "diagnose truncated data" {
    const bytes = &[_]u8{ 0, 0, 0 };

    const diag = diagnoseMachO(bytes);
    try std.testing.expect(!diag.can_launch);
    try std.testing.expectEqualStrings("truncated", diag.architecture);
}

test "launch result struct works" {
    const attempt = LaunchAttempt{
        .success = false,
        .pid = null,
        .diagnostics = LaunchDiagnostic{
            .strategy = .unsupported_architecture,
            .can_launch = false,
            .architecture = "i386",
            .machine_readable = true,
            .reason = "test reason",
            .suggestion = "test suggestion",
        },
    };
    try std.testing.expect(!attempt.success);
    try std.testing.expect(attempt.pid == null);
    try std.testing.expectEqualStrings("i386", attempt.diagnostics.architecture);
}
