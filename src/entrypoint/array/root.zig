pub const ArrayPreserve = @import("entrypoint_array_preserve_common").ArrayPreserve;
pub const initArrayPreserve = @import("entrypoint_array_preserve_common").initArrayPreserve;
pub const push = @import("entrypoint_array_preserve_common").arrayPush;
pub const pop = @import("entrypoint_array_preserve_common").arrayPop;
pub const get = @import("entrypoint_array_preserve_common").arrayGet;
pub const set = @import("entrypoint_array_preserve_common").arraySet;
pub const DOS = @import("entrypoint_array_preserve_dos");
pub const x86 = @import("entrypoint_array_preserve_x86");
pub const x64 = @import("entrypoint_array_preserve_x64");
pub const NEON = @import("entrypoint_array_preserve_neon");

test "arch modules accessible" {
    _ = DOS;
    _ = x86;
    _ = x64;
    _ = NEON;
}
