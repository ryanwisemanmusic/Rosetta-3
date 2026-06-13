const builtin = @import("builtin");

const log_path = "/tmp/rosette-yasm-abi.log";

pub const yasm_core = @import("yasm_core.zig");
pub const directives = @import("directives.zig");
pub const operands = @import("operands.zig");
pub const encoding = @import("encoding.zig");
pub const segments = @import("segments.zig");
pub const preprocessor = @import("preprocessor.zig");
pub const symbols = @import("symbols.zig");
pub const output = @import("output.zig");
pub const listing = @import("listing.zig");
pub const assembler = @import("assembler.zig");
pub const abi_handshake = @import("abi_handshake.zig");

pub export fn rosette_debug_enabled() c_int {
    return 1;
}

pub export fn rosette_debug_log_path() [*:0]const u8 {
    return log_path;
}

pub export fn rosette_runtime_abi_fail_fast_enabled() c_int {
    return 0;
}

comptime {
    if (builtin.is_test) {
        _ = yasm_core;
        _ = directives;
        _ = operands;
        _ = encoding;
        _ = segments;
        _ = preprocessor;
        _ = symbols;
        _ = output;
        _ = listing;
        _ = assembler;
        _ = abi_handshake;
    }
}
