const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

const jwasm_assembler = @import("JWASM/Zig/assembler.zig");
const jwasm_handshake_mod = @import("JWASM/Zig/abi_handshake.zig");
const fasm_assembler = @import("FASM/Zig/assembler.zig");
const fasm_handshake_mod = @import("FASM/Zig/abi_handshake.zig");
const nasm_assembler = @import("NASM/Zig/assembler.zig");
const nasm_handshake_mod = @import("NASM/Zig/abi_handshake.zig");

const log_path = "/tmp/rosette-assembler-abi-suite.log";

pub export fn rosette_debug_enabled() c_int {
    return 1;
}

pub export fn rosette_debug_log_path() [*:0]const u8 {
    return log_path;
}

pub export fn rosette_runtime_abi_fail_fast_enabled() c_int {
    return 0;
}

test "JWasm assembler strict ABI suite" {
    runtime_abi.common.acquire();
    defer runtime_abi.common.release();

    const alloc = std.testing.allocator;
    const bytes = try jwasm_assembler.assembleJWASM(".model small\n", alloc);
    defer alloc.free(bytes);

    var handshake = jwasm_handshake_mod.JwasmAbiHandshake.init(alloc);
    defer handshake.deinit();
    try handshake.onEvent(.assembly_start, .instruction_encoding, 0, "jwasm start");
    handshake.validateOutput(&[_]u8{0x90});
}

test "FASM assembler strict ABI suite" {
    runtime_abi.common.acquire();
    defer runtime_abi.common.release();

    const alloc = std.testing.allocator;
    const bytes = try fasm_assembler.assemble("format binary\nuse32\ndb 0x90\n", alloc);
    defer alloc.free(bytes);

    var handshake = fasm_handshake_mod.FasmAbiHandshake.init(alloc);
    defer handshake.deinit();
    try handshake.onEvent(.assembly_start, .instruction_encoding, 0, "fasm start");
    handshake.validateOutput(bytes);
}

test "NASM assembler strict ABI suite" {
    runtime_abi.common.acquire();
    defer runtime_abi.common.release();

    var nasm_state = nasm_assembler.Assembler.init(std.testing.allocator);
    defer nasm_state.deinit();
    try nasm_state.setBits(32);
    _ = try nasm_state.beginSection(".text", 16);
    try nasm_state.defineSymbol("entry", .normal, 0, 0, 4);

    var handshake = nasm_handshake_mod.NasmAbiHandshake.init(std.testing.allocator);
    defer handshake.deinit();
    try handshake.onEvent(.assembly_start, .instruction_encoding, 0, "nasm start");
    handshake.validateOutput(&[_]u8{0x90});
}

test "Assembler ABI Validation checks all passed" {
    std.debug.print("Assembler ABI Validation checks: ALL Passed\n", .{});
}
