comptime {
    _ = @import("abi_suite.zig");
    _ = @import("dll_translator");
}

pub export fn rosetta3_dll_icon_count_a(path_z: [*:0]const u8) c_int {
    return @import("dll_translator").dllIconCountA(path_z);
}

pub export fn rosetta3_dll_extract_icon_a(path_z: [*:0]const u8, index: c_int) usize {
    return @import("dll_translator").dllExtractIconA(path_z, index);
}

pub export fn rosetta3_dll_icon_count_w(path_z: [*:0]const u16) c_int {
    return @import("dll_translator").dllIconCountW(path_z);
}

pub export fn rosetta3_dll_extract_icon_w(path_z: [*:0]const u16, index: c_int) usize {
    return @import("dll_translator").dllExtractIconW(path_z, index);
}

test "root module links exported ABI surfaces" {
    try @import("std").testing.expect(true);
}
