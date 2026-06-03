comptime {
    _ = @import("abi_suite.zig");
}

test "root module links exported ABI surfaces" {
    try @import("std").testing.expect(true);
}
