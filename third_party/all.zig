const std = @import("std");

comptime {
    _ = @import("crypto/sha");
    _ = @import("crypto/des");
    _ = @import("crypto/rijndael");
    _ = @import("dxbc/dxbc_checksum");
    _ = @import("endianness/endianness");
    _ = @import("fxaa/fxaa");
    _ = @import("half/half");
    _ = @import("renderdoc/renderdoc");
    _ = @import("avx_to_neon/avx_to_neon");
    _ = @import("llvm/llvm");
    _ = @import("microprofile/microprofile");
    _ = @import("mspack/mspack");
    _ = @import("stb/stb");
}

test {
    std.testing.refAllDecls(@This());
}
