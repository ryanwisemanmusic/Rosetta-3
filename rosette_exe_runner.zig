// =============================================================================
// ROSETTE EXE RUNNER — DEEP DEBUG GATE SYSTEM (CUSTOM _start, NO LIBC)
// =============================================================================
// This file provides its own `_start` entry point to bypass Zig's
// posixCallMainAndExit / __init_array which hangs on macOS with -lc.
// All output uses raw ARM64 svc #0x80 syscalls — zero libc dependency.
// =============================================================================

const std = @import("std");

const GATE_STOP: u32 = 999;
const FD_STDERR: u64 = 2;
const SYS_WRITE: u64 = 4;

// ---- LIBC STUBS -----------------------------------------------------------
// Provide setenv so exe_runner_core.zig compiles without -lc
export fn setenv(name: [*:0]const u8, value: [*:0]const u8, overwrite: c_int) c_int {
    _ = name; _ = value; _ = overwrite;
    return 0;
}

// ---- RAW ARM64 SYSCALL OUTPUT ---------------------------------------------
fn sys_write(fd: u64, buf: [*]const u8, len: u64) void {
    asm volatile (
        \\ mov x16, %[sysno]
        \\ mov x0, %[fd]
        \\ mov x1, %[buf]
        \\ mov x2, %[len]
        \\ svc #0x80
        :
        : [sysno] "r" (SYS_WRITE),
          [fd] "r" (fd),
          [buf] "r" (buf),
          [len] "r" (len)
        : .{ .x0 = true, .x1 = true, .x2 = true, .x16 = true, .memory = true }
    );
}

fn write_str(s: []const u8) void {
    sys_write(FD_STDERR, s.ptr, s.len);
}

fn write_num(n: u32) void {
    var buf: [12]u8 = undefined;
    var i: u32 = 12;
    var val = n;
    while (i > 0) {
        i -= 1;
        buf[i] = @as(u8, @intCast(48 + (val % 10)));
        val /= 10;
        if (val == 0) break;
    }
    write_str(buf[i..12]);
}

fn gate(id: u32, msg: []const u8) void {
    write_str("[GATE ");
    write_num(id);
    write_str("] ");
    write_str(msg);
    write_str("\n");
    if (id == GATE_STOP) {
        write_str("[ABORT] gate stop reached — infinite loop\n");
        while (true) {}
    }
}

fn gate_done() void {
    write_str("[OK] all gates passed\n");
}

// ---- ABI HANDSHAKE EXPORTS -------------------------------------------------
pub export fn rosette_debug_enabled() c_int { return 1; }
pub export fn rosette_debug_log_path() [*:0]const u8 { return "rosette-exe-runner.log"; }
pub export fn rosette_runtime_abi_fail_fast_enabled() c_int { return 1; }

// ---- CUSTOM ENTRY POINT (_start) ------------------------------------------
// This runs before ANYTHING else. No libc init, no __init_array.
// start.zig detects our _start declaration and skips exporting its own.
pub fn _start() callconv(.c) noreturn {
    main();
    while (true) {}
}

comptime {
    @export(&_start, .{ .name = "_start" });
}

pub fn main() void {
    gate(0, "_start entry — raw svc #0x80 works");
    gate(0, "_start entry — raw svc #0x80 works");

    gate(1, "stack alloc");
    var buf: [64]u8 = undefined;
    _ = &buf;

    gate(2, "page_allocator");
    const page = std.heap.page_allocator;
    _ = page;

    gate(3, "ArenaAllocator");
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    gate(4, "heap alloc");
    const m = arena.allocator().alloc(u8, 64) catch {
        gate(4, "heap alloc failed");
        while (true) {}
    };
    _ = m;

    gate(5, "string dupe");
    const d = arena.allocator().dupe(u8, "hello") catch {
        gate(5, "dupe failed");
        while (true) {}
    };
    _ = d;

    gate(6, "about to import abort_trap_taxonomy");
    {
        const traps = @import("abort_trap_taxonomy");
        _ = traps.AbortTrap.UnsupportedInstruction;
    }
    gate(7, "abort_trap_taxonomy ok");

    gate(8, "about to import entrypoint_code_text_segment");
    {
        const t = @import("entrypoint_code_text_segment");
        _ = t.Segment;
    }
    gate(9, "entrypoint_code_text_segment ok");

    gate(10, "about to import runtime_abi_handshake");
    {
        const abi = @import("runtime_abi_handshake");
        _ = abi.x86;
    }
    gate(11, "runtime_abi_handshake ok");

    gate(12, "about to call abi.x86.init()");
    {
        const abi = @import("runtime_abi_handshake");
        abi.x86.init();
    }
    gate(13, "abi.x86.init() ok");

    gate(14, "about to import isa_registry");
    {
        const isa = @import("isa_registry");
        _ = isa;
    }
    gate(15, "isa_registry ok");

    gate(16, "about to import bridge_register_tracing");
    {
        const b = @import("bridge_register_tracing");
        _ = b;
    }
    gate(17, "bridge_register_tracing ok");

    gate(18, "about to import bridge_memory");
    {
        const b = @import("bridge_memory");
        _ = b;
    }
    gate(19, "bridge_memory ok");

    gate(20, "about to import bridge_stack");
    {
        const b = @import("bridge_stack");
        _ = b;
    }
    gate(21, "bridge_stack ok");

    gate(22, "about to import bridge_heap");
    {
        const b = @import("bridge_heap");
        _ = b;
    }
    gate(23, "bridge_heap ok");

    gate(24, "about to import bridge_instruction_decoding");
    {
        const b = @import("bridge_instruction_decoding");
        _ = b;
    }
    gate(25, "bridge_instruction_decoding ok");

    gate(26, "about to import bridge_flags");
    {
        const b = @import("bridge_flags");
        _ = b;
    }
    gate(27, "bridge_flags ok");

    gate(28, "about to import bridge_string_ops");
    {
        const b = @import("bridge_string_ops");
        _ = b;
    }
    gate(29, "bridge_string_ops ok");

    gate(30, "about to import bridge_exceptions");
    {
        const b = @import("bridge_exceptions");
        _ = b;
    }
    gate(31, "bridge_exceptions ok");

    gate(32, "about to import exe_runner_core.zig");
    {
        const c = @import("src/tooling/exe_parser/exe_runner_core.zig");
        _ = c;
    }
    gate(33, "exe_runner_core.zig ok");

    gate(34, "about to import runtime/rosette_exe_runner.zig");
    {
        const r = @import("src/tooling/exe_parser/runtime/rosette_exe_runner.zig");
        _ = r;
    }
    gate(35, "runtime/rosette_exe_runner.zig ok");

    gate_done();
    while (true) {}
}
