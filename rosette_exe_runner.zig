pub export fn rosette_debug_enabled() c_int {
    return 1;
}

pub export fn rosette_debug_log_path() [*:0]const u8 {
    return "rosette-exe-runner.log";
}

pub export fn rosette_runtime_abi_fail_fast_enabled() c_int {
    return 0;
}

pub const core = @import("src/tooling/exe_parser/exe_runner_core.zig");
pub const main = @import("src/tooling/exe_parser/runtime/rosette_exe_runner.zig").main;
