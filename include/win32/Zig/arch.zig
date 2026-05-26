const builtin = @import("builtin");

pub export fn zig_arch() u32 {
    return switch (builtin.target.cpu.arch) {
        .x86_64 => 1,
        .aarch64 => 2,
        else => 0,
    };
}
