const math = @import("root.zig");

pub export fn rosette_debug_enabled() c_int {
    return 0;
}

pub export fn rosette_debug_log_path() [*:0]const u8 {
    return "".ptr;
}

pub export fn rosette_runtime_abi_fail_fast_enabled() c_int {
    return 0;
}

test "ISA Math standalone harness validates mirrored x86 and NEON arithmetic" {
    math.validateAll();
    try math.exerciseAll();
}
