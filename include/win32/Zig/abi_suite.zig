const std = @import("std");

const var_sizes = @import("var_sizes.zig");
const atomic_abi = @import("atomic.zig");
const console_window_abi = @import("console_window_abi.zig");
const dbghelp_abi = @import("dbghelp.zig");
const dds_abi = @import("dds.zig");
const fiber_abi = @import("fiber.zig");
const file_abi = @import("file.zig");
const gdi_abi = @import("gdi.zig");
const intrin_abi = @import("intrin.zig");
const io_abi = @import("io.zig");
const mmsystem_abi = @import("mmsystem.zig");
const process_abi = @import("process.zig");
const shim_surface_abi = @import("shim_surface.zig");
const synchapi_abi = @import("synchapi.zig");
const threads_abi = @import("threads.zig");
const window_abi = @import("window.zig");

pub const module_stride: c_int = 1000;

pub const Module = enum(c_int) {
    windows_base = 1,
    sysinfo = 2,
    behavior = 3,
    console_window = 4,
    mmsystem = 5,
    atomic = 6,
    dbghelp = 7,
    dds = 8,
    fiber = 9,
    file = 10,
    gdi = 11,
    intrin = 12,
    io = 13,
    process = 14,
    synchapi = 15,
    threads = 16,
    window = 17,
    shim_surface = 18,
};

pub const Result = struct {
    module: Module,
    name: []const u8,
    code: c_int,
};

pub const ModuleRunner = struct {
    module: Module,
    name: []const u8,
    validate: *const fn () c_int,
};

fn validateWindowsBase() c_int {
    return var_sizes.rosetta3_validate_abi();
}

fn validateSysinfo() c_int {
    return var_sizes.rosetta3_validate_sysinfo();
}

fn validateBehavior() c_int {
    return var_sizes.rosetta3_validate_behavior();
}

fn validateConsoleWindow() c_int {
    return console_window_abi.rosetta3_validate_console_window_abi();
}

fn validateMmsystem() c_int {
    return mmsystem_abi.rosetta3_validate_mmsystem();
}

fn validateAtomic() c_int {
    return atomic_abi.rosetta3_validate_atomic();
}

fn validateDbghelp() c_int {
    return dbghelp_abi.rosetta3_validate_dbghelp();
}

fn validateDds() c_int {
    return dds_abi.rosetta3_validate_dds();
}

fn validateFiber() c_int {
    return fiber_abi.rosetta3_validate_fiber();
}

fn validateFile() c_int {
    return file_abi.rosetta3_validate_file();
}

fn validateGdi() c_int {
    return gdi_abi.rosetta3_validate_gdi();
}

fn validateIntrin() c_int {
    return intrin_abi.rosetta3_validate_intrin();
}

fn validateIo() c_int {
    return io_abi.rosetta3_validate_io();
}

fn validateProcess() c_int {
    return process_abi.rosetta3_validate_process();
}

fn validateSynchapi() c_int {
    return synchapi_abi.rosetta3_validate_synchapi();
}

fn validateThreads() c_int {
    return threads_abi.rosetta3_validate_threads();
}

fn validateWindow() c_int {
    return window_abi.rosetta3_validate_window();
}

fn validateShimSurface() c_int {
    return shim_surface_abi.rosetta3_validate_shim_surface();
}

pub const module_table = [_]ModuleRunner{
    .{ .module = .windows_base, .name = "windows_base", .validate = validateWindowsBase },
    .{ .module = .sysinfo, .name = "sysinfo", .validate = validateSysinfo },
    .{ .module = .behavior, .name = "behavior", .validate = validateBehavior },
    .{ .module = .console_window, .name = "console_window_abi", .validate = validateConsoleWindow },
    .{ .module = .mmsystem, .name = "mmsystem", .validate = validateMmsystem },
    .{ .module = .atomic, .name = "atomic", .validate = validateAtomic },
    .{ .module = .dbghelp, .name = "dbghelp", .validate = validateDbghelp },
    .{ .module = .dds, .name = "dds", .validate = validateDds },
    .{ .module = .fiber, .name = "fiber", .validate = validateFiber },
    .{ .module = .file, .name = "file", .validate = validateFile },
    .{ .module = .gdi, .name = "gdi", .validate = validateGdi },
    .{ .module = .intrin, .name = "intrin", .validate = validateIntrin },
    .{ .module = .io, .name = "io", .validate = validateIo },
    .{ .module = .process, .name = "process", .validate = validateProcess },
    .{ .module = .synchapi, .name = "synchapi", .validate = validateSynchapi },
    .{ .module = .threads, .name = "threads", .validate = validateThreads },
    .{ .module = .window, .name = "window", .validate = validateWindow },
    .{ .module = .shim_surface, .name = "shim_surface", .validate = validateShimSurface },
};

fn encodeFailure(module: Module, code: c_int) c_int {
    return @intFromEnum(module) * module_stride + code;
}

pub fn validateAll() c_int {
    inline for (module_table) |entry| {
        const code = entry.validate();
        if (code != 0) return encodeFailure(entry.module, code);
    }
    return 0;
}

pub fn printReport() void {
    std.debug.print(
        \\================================================================================
        \\ Rosetta 3 ABI Handshake Suite
        \\================================================================================
        \\
    , .{});
    inline for (module_table) |entry| {
        const code = entry.validate();
        std.debug.print("  {s:20} : {s}", .{ entry.name, if (code == 0) "OK" else "FAIL" });
        if (code != 0) {
            std.debug.print(" (code {d})", .{code});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

pub fn failureName(code: c_int) [*:0]const u8 {
    if (code == 0) return "OK";
    const module_id = @divTrunc(code, module_stride);
    return switch (module_id) {
        @intFromEnum(Module.windows_base) => "windows_base",
        @intFromEnum(Module.sysinfo) => "sysinfo",
        @intFromEnum(Module.behavior) => "behavior",
        @intFromEnum(Module.console_window) => "console_window_abi",
        @intFromEnum(Module.mmsystem) => "mmsystem",
        @intFromEnum(Module.atomic) => "atomic",
        @intFromEnum(Module.dbghelp) => "dbghelp",
        @intFromEnum(Module.dds) => "dds",
        @intFromEnum(Module.fiber) => "fiber",
        @intFromEnum(Module.file) => "file",
        @intFromEnum(Module.gdi) => "gdi",
        @intFromEnum(Module.intrin) => "intrin",
        @intFromEnum(Module.io) => "io",
        @intFromEnum(Module.process) => "process",
        @intFromEnum(Module.synchapi) => "synchapi",
        @intFromEnum(Module.threads) => "threads",
        @intFromEnum(Module.window) => "window",
        @intFromEnum(Module.shim_surface) => "shim_surface",
        else => "unknown_handshake_module",
    };
}

pub export fn rosetta3_validate_handshake_suite() c_int {
    return validateAll();
}

pub export fn rosetta3_handshake_suite_failure_name(code: c_int) [*:0]const u8 {
    return failureName(code);
}

pub export fn rosetta3_print_handshake_suite_report() void {
    printReport();
}

test "aggregate ABI suite passes" {
    try std.testing.expectEqual(@as(c_int, 0), validateAll());
}
